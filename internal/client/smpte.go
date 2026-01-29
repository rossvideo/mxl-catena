//go:build smpte

package client

import (
	"context"
	"errors"
	"time"

	"google.golang.org/grpc"
)

// smpteClient holds typed gRPC stubs once protos are integrated.
type smpteClient struct {
	// Example: DeviceControl service client from generated code
	// ctrl smptepb.DeviceControlServiceClient
}

// ensureConn overrides to initialize generated SMPTE service clients.
func (c *Client) ensureConn(ctx context.Context) error {
	if c.Transport != "grpc" {
		return errors.New("transport is not grpc")
	}
	if c.conn != nil {
		return nil
	}
	dctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	conn, err := grpc.DialContext(dctx, c.Endpoint, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		return err
	}
	c.conn = conn

	// Initialize generated clients here, e.g.:
	// c.smpte = &smpteClient{
	//     ctrl: smptepb.NewDeviceControlServiceClient(conn),
	// }
	return nil
}

// SetParams sends desired params to the device via the SMPTE gRPC API.
func (c *Client) SetParams(ctx context.Context, params any) error {
	if err := c.ensureConn(ctx); err != nil {
		return err
	}
	// TODO: marshal `params` into the generated Params message and call the RPC, e.g.:
	// req := &smptepb.SetParamsRequest{ /* fill from params */ }
	// _, err := c.smpte.ctrl.SetParams(ctx, req)
	// return err
	return nil
}

// RunStart triggers the device start via the SMPTE gRPC API.
func (c *Client) RunStart(ctx context.Context, command string) error {
	if err := c.ensureConn(ctx); err != nil {
		return err
	}
	// req := &smptepb.StartRequest{ Command: command }
	// _, err := c.smpte.ctrl.Start(ctx, req)
	// return err
	return nil
}

// WaitReady polls device status until it equals readyValue or timeout elapses using the SMPTE gRPC API.
func (c *Client) WaitReady(ctx context.Context, _slot uint32, endpoint string, readyValue string, timeout time.Duration) error {
	if err := c.ensureConn(ctx); err != nil {
		return err
	}
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		// req := &smptepb.StatusRequest{ Endpoint: endpoint }
		// resp, err := c.smpte.ctrl.GetStatus(ctx, req)
		// if err == nil && resp.GetValue() == readyValue {
		//     return nil
		// }
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(1 * time.Second):
		}
	}
	return errors.New("timeout waiting for ready state")
}
