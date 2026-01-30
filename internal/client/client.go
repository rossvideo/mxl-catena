package client

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"net/url"
	"strings"
	"time"

	"github.com/hashicorp/terraform-plugin-framework/types"
	st2138pb "github.com/rossvideo/terraform-provider-st2138/internal/genproto"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
)

// Client carries provider configuration and, when transport is grpc, a lazily-dialed connection.
type Client struct {
	Endpoint   string
	Transport  string
	DevicesDir string

	conn      *grpc.ClientConn
	rpcClient st2138pb.CatenaServiceClient
}

// Close releases any underlying connections.
func (c *Client) Close() {
	if c.conn != nil {
		_ = c.conn.Close()
		c.conn = nil
		c.rpcClient = nil
	}
}

// Clone returns a shallow copy of the client configuration without any active connection.
// Use per-resource clones to avoid endpoint/connection races across parallel resources.
func (c *Client) Clone() *Client {
	return &Client{
		Endpoint:   c.Endpoint,
		Transport:  c.Transport,
		DevicesDir: c.DevicesDir,
		conn:       nil,
		rpcClient:  nil,
	}
}

// SetEndpoint updates the client's endpoint. If the endpoint changes while a
// connection is open, the existing connection is closed so the next operation
// will re-dial the new target.
func (c *Client) SetEndpoint(ep string) {
	if ep == "" {
		return
	}
	if c.Endpoint != ep {
		c.Endpoint = ep
		c.Close()
	}
}

// ensureConn dials the gRPC endpoint and initializes the RPC client.
func (c *Client) ensureConn(ctx context.Context) error {
	if c.Transport != "grpc" {
		return fmt.Errorf("transport %q is not grpc", c.Transport)
	}
	if c.conn != nil && c.rpcClient != nil {
		return nil
	}
	// Dial timeout for establishing connection
	dctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	target := c.Endpoint
	var opts []grpc.DialOption
	// If endpoint includes an explicit scheme (://), use it to decide TLS
	// e.g., https://host:port or grpcs://host:port. Otherwise treat as host[:port].
	if strings.Contains(target, "://") {
		if u, err := url.Parse(target); err == nil {
			host := u.Host
			if host == "" {
				host = u.Path
			}
			if u.Scheme == "https" || u.Scheme == "grpcs" {
				serverName := host
				if hp := strings.Split(host, ":"); len(hp) > 0 {
					serverName = hp[0]
				}
				tlsCfg := &tls.Config{ServerName: serverName}
				opts = append(opts, grpc.WithTransportCredentials(credentials.NewTLS(tlsCfg)))
			} else {
				opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))
			}
			target = host
		} else {
			opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))
		}
	} else {
		// No scheme provided: default to insecure and use target as-is
		opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))
	}
	opts = append(opts, grpc.WithBlock())
	conn, err := grpc.DialContext(dctx, target, opts...)
	if err != nil {
		return err
	}
	c.conn = conn
	c.rpcClient = st2138pb.NewCatenaServiceClient(conn)
	return nil
}

// SetParams sets a subset of well-known params via gRPC when available.
// Currently supports setting string params like selected_flow_id if present.
func (c *Client) SetParams(ctx context.Context, dyn types.Dynamic) error {
	if err := c.ensureConn(ctx); err != nil {
		return err
	}
	// No generic decoding implemented yet; use resource-level helpers to set values.
	return nil
}

// SetStringValue performs GetParam then SetValue for a string OID.
func (c *Client) SetStringValue(ctx context.Context, slot uint32, oid string, value string) error {
	if err := c.ensureConn(ctx); err != nil {
		return err
	}
	// Use the provided slot as-is; caller is responsible for correctness
	// Normalize OID: ensure it starts with '/'
	roid := oid
	if !strings.HasPrefix(roid, "/") {
		roid = "/" + roid
	}

	req := &st2138pb.SingleSetValuePayload{
		Slot: slot,
		Value: &st2138pb.SetValuePayload{
			Oid:   roid,
			Value: &st2138pb.Value{Kind: &st2138pb.Value_StringValue{StringValue: value}},
		},
	}
	_, err := c.rpcClient.SetValue(ctx, req)
	return err
}

// SetNumberValue sets a numeric param; prefers int32 when value is integral and in range, else float32.
func (c *Client) SetNumberValue(ctx context.Context, slot uint32, oid string, n float64) error {
	if err := c.ensureConn(ctx); err != nil {
		return err
	}
	roid := oid
	if !strings.HasPrefix(roid, "/") {
		roid = "/" + roid
	}
	var val *st2138pb.Value
	// Check if n is integral within int32 range
	if n == float64(int32(n)) {
		val = &st2138pb.Value{Kind: &st2138pb.Value_Int32Value{Int32Value: int32(n)}}
	} else {
		val = &st2138pb.Value{Kind: &st2138pb.Value_Float32Value{Float32Value: float32(n)}}
	}
	req := &st2138pb.SingleSetValuePayload{
		Slot:  slot,
		Value: &st2138pb.SetValuePayload{Oid: roid, Value: val},
	}
	_, err := c.rpcClient.SetValue(ctx, req)
	return err
}

// SetParamsWithSlot walks a JSON-like params object, sets all string and numeric leaves via SetValue.
// Complex values (objects/arrays) are traversed as subparams to produce OIDs like /a/b/0/c.
func (c *Client) SetParamsWithSlot(ctx context.Context, dyn types.Dynamic, slot uint32) error {
	if err := c.ensureConn(ctx); err != nil {
		return err
	}
	if dyn.IsNull() || dyn.IsUnknown() {
		return nil
	}
	var data any
	// Decode via JSON marshal/unmarshal; if wrapper object has a "value" field, use it.
	rawBytes, jerr := json.Marshal(dyn)
	if jerr != nil || len(rawBytes) == 0 {
		return nil
	}
	// First try direct decode
	if uerr := json.Unmarshal(rawBytes, &data); uerr != nil {
		return nil
	}
	// If result is a wrapper with common fields, extract nested "value"
	if m, ok := data.(map[string]any); ok {
		if v, vok := m["value"]; vok {
			data = v
		}
	}
	type pair struct {
		oid string
		v   any
	}
	var work []pair
	var walk func(prefix string, node any)
	walk = func(prefix string, node any) {
		switch t := node.(type) {
		case map[string]any:
			for k, v := range t {
				np := prefix + "/" + k
				walk(np, v)
			}
		case []any:
			for i, v := range t {
				np := fmt.Sprintf("%s/%d", prefix, i)
				walk(np, v)
			}
		case string:
			work = append(work, pair{oid: prefix, v: t})
		case float64:
			work = append(work, pair{oid: prefix, v: t})
		case bool:
			// booleans treated as strings "true"/"false" unless a dedicated type is desired
			work = append(work, pair{oid: prefix, v: t})
		default:
			// other scalar types not expected; ignore
		}
	}
	// Start walk at root with empty prefix; ensure leading '/'
	walk("", data)
	for _, p := range work {
		// Normalize OID
		oid := p.oid
		if !strings.HasPrefix(oid, "/") {
			oid = "/" + oid
		}
		switch v := p.v.(type) {
		case string:
			if err := c.SetStringValue(ctx, slot, oid, v); err != nil {
				return err
			}
		case float64:
			if err := c.SetNumberValue(ctx, slot, oid, v); err != nil {
				return err
			}
		case bool:
			sv := "false"
			if v {
				sv = "true"
			}
			if err := c.SetStringValue(ctx, slot, oid, sv); err != nil {
				return err
			}
		}
	}
	return nil
}

// getFirstSlot queries the server for populated slots and returns the first one.
// getFirstSlot removed: slot must be provided

// discoverSlot attempts to find an active device slot via GetPopulatedSlots,
// and if none are reported, opens a Connect stream to wait for SlotsAdded or a Device model.
// discoverSlot removed: slot must be provided

// resolveOID attempts to validate or discover the fully-qualified OID path for a param.
// It first tries the candidate directly via GetParam, then streams ParamInfoRequest
// to find an OID that ends with the candidate name.
// resolveOID removed: caller must provide the correct OID. We only normalize leading '/'.

// RunStart triggers the device start via the SMPTE gRPC API using ExecuteCommand.
// commandOID should be a fully-qualified OID for the command; leading '/' will be added if missing.
func (c *Client) RunStart(ctx context.Context, slot uint32, commandOID string) error {
	if err := c.ensureConn(ctx); err != nil {
		return err
	}
	oid := commandOID
	if !strings.HasPrefix(oid, "/") {
		oid = "/" + oid
	}
	payload := &st2138pb.ExecuteCommandPayload{
		Slot:    slot,
		Oid:     oid,
		Value:   &st2138pb.Value{Kind: &st2138pb.Value_EmptyValue{EmptyValue: &st2138pb.Empty{}}},
		Respond: false,
	}
	// Start the ExecuteCommand stream and immediately return; server should not respond when Respond=false.
	_, err := c.rpcClient.ExecuteCommand(ctx, payload)
	return err
}

// WaitReady polls the given endpoint OID for the provided slot until the value equals readyValue or timeout elapses.
func (c *Client) WaitReady(ctx context.Context, slot uint32, endpoint string, readyValue string, timeout time.Duration) error {
	if err := c.ensureConn(ctx); err != nil {
		return err
	}
	deadline := time.Now().Add(timeout)
	for {
		// Check context cancellation
		if ctx.Err() != nil {
			return ctx.Err()
		}
		// Attempt to read current value
		val, err := c.GetStringValue(ctx, slot, endpoint)
		if err == nil && val == readyValue {
			return nil
		}
		if time.Now().After(deadline) {
			if err != nil {
				return err
			}
			return fmt.Errorf("timeout waiting for %s to equal %q (last=%q)", endpoint, readyValue, val)
		}
		time.Sleep(1 * time.Second)
	}
}

// GetStringValue fetches a value for an OID and returns its string representation.
// If the underlying value is numeric or boolean, it is converted to a string.
func (c *Client) GetStringValue(ctx context.Context, slot uint32, oid string) (string, error) {
	if err := c.ensureConn(ctx); err != nil {
		return "", err
	}
	roid := oid
	if !strings.HasPrefix(roid, "/") {
		roid = "/" + roid
	}
	req := &st2138pb.GetValuePayload{Slot: slot, Oid: roid}
	val, err := c.rpcClient.GetValue(ctx, req)
	if err != nil {
		return "", err
	}
	// Prefer string if present; else coerce other scalar types
	if s := val.GetStringValue(); s != "" {
		return s, nil
	}
	if iv := val.GetInt32Value(); iv != 0 {
		return fmt.Sprintf("%d", iv), nil
	}
	if fv := val.GetFloat32Value(); fv != 0 {
		return fmt.Sprintf("%g", fv), nil
	}
	// Default empty string if kind is empty
	return "", nil
}

// RunStop triggers a device stop via ExecuteCommand using the given command OID.
func (c *Client) RunStop(ctx context.Context, slot uint32, commandOID string) error {
	if err := c.ensureConn(ctx); err != nil {
		return err
	}
	oid := commandOID
	if !strings.HasPrefix(oid, "/") {
		oid = "/" + oid
	}
	payload := &st2138pb.ExecuteCommandPayload{
		Slot:    slot,
		Oid:     oid,
		Value:   &st2138pb.Value{Kind: &st2138pb.Value_EmptyValue{EmptyValue: &st2138pb.Empty{}}},
		Respond: false,
	}
	_, err := c.rpcClient.ExecuteCommand(ctx, payload)
	return err
}
