package resources

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"

	clientpkg "github.com/rossvideo/terraform-provider-st2138/internal/client"
)

// NewDeviceResource returns a new device resource instance.
func NewDeviceResource() resource.Resource {
	return &deviceResource{}
}

type deviceResource struct {
	client *clientpkg.Client
}

type deviceModel struct {
	ID           types.String       `tfsdk:"id"`
	Name         types.String       `tfsdk:"name"`
	DeviceType   types.String       `tfsdk:"device_type"`
	ContainerID  types.String       `tfsdk:"container_id"`
	Params       []paramPairModel   `tfsdk:"params"`
	ParamsMap    types.Map          `tfsdk:"params_map"`
	Slot         types.Int64        `tfsdk:"slot"`
	StartCommand types.String       `tfsdk:"start_command"`
	StopCommand  types.String       `tfsdk:"stop_command"`
	DeviceStatus *deviceStatusModel `tfsdk:"device_status"`
	StatusValue  types.String       `tfsdk:"status_value"`
	ApplyAll     types.Bool         `tfsdk:"apply_all"`
	Address      types.String       `tfsdk:"address"`
	Port         types.Int64        `tfsdk:"port"`
}

type deviceStatusModel struct {
	Endpoint   types.String `tfsdk:"endpoint"`
	Oid        types.String `tfsdk:"oid"`
	ReadyValue types.String `tfsdk:"ready_value"`
}

func (r *deviceResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_device"
}

func (r *deviceResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Represents a Catena device (minimal skeleton).",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:      true,
				Description:   "Unique identifier for the device.",
				PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()},
			},
			"name": schema.StringAttribute{
				Optional:    true,
				Description: "Human-readable device name.",
			},
			"device_type": schema.StringAttribute{
				Optional:    true,
				Description: "Device type identifier (e.g., pat2mxl).",
			},
			"container_id": schema.StringAttribute{
				Computed:      true,
				Description:   "ID of the Docker container launched for this device.",
				PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()},
			},
			"status_value": schema.StringAttribute{
				Computed:      true,
				Description:   "Latest polled value of device_status OID (via gRPC GetValue).",
				PlanModifiers: []planmodifier.String{stringplanmodifier.UseStateForUnknown()},
			},
			"apply_all": schema.BoolAttribute{
				Optional:    true,
				Description: "When true, always send all params_map and params values on apply/update, even if unchanged.",
			},
			// Generic map to set OID->value pairs without repeated blocks
			"params_map": schema.MapAttribute{
				Optional:    true,
				ElementType: types.StringType,
				Description: "Map of OID to value (string); numbers/bools parsed automatically.",
			},
			"slot": schema.Int64Attribute{
				Required:    true,
				Description: "Device slot id used in gRPC calls.",
			},
			"address": schema.StringAttribute{
				Optional:    true,
				Description: "When device_type=remote-grpc, the remote device address (host or URL).",
			},
			"port": schema.Int64Attribute{
				Optional:    true,
				Description: "When device_type=remote-grpc, the remote device port (e.g., 6254).",
			},
			"start_command": schema.StringAttribute{
				Optional:    true,
				Description: "Optional command to run inside the container after startup.",
			},
			"stop_command": schema.StringAttribute{
				Optional:    true,
				Description: "Optional command to run inside the container before deletion.",
			},
			// selected_flow_id removed in favor of generic params_map
		},
		Blocks: map[string]schema.Block{
			"params": schema.ListNestedBlock{
				Description: "List of OID/value pairs to set via gRPC.",
				NestedObject: schema.NestedBlockObject{
					Attributes: map[string]schema.Attribute{
						"oid":   schema.StringAttribute{Required: true, Description: "Fully-qualified OID (e.g., /inputs/0/name)."},
						"value": schema.StringAttribute{Required: true, Description: "Value to set; string representation; numeric and bool parsed automatically."},
					},
				},
			},
			// inputs block removed in favor of generic params_map
			"device_status": schema.SingleNestedBlock{
				Attributes: map[string]schema.Attribute{
					"endpoint":    schema.StringAttribute{Optional: true, Description: "Deprecated alias for status OID."},
					"oid":         schema.StringAttribute{Optional: true, Description: "Status OID to poll for readiness."},
					"ready_value": schema.StringAttribute{Optional: true},
				},
			},
		},
	}
}

type paramPairModel struct {
	Oid   types.String `tfsdk:"oid"`
	Value types.String `tfsdk:"value"`
}

// inputs model removed

func (r *deviceResource) Configure(_ context.Context, req resource.ConfigureRequest, _ *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}
	// Use a per-resource client clone to prevent endpoint/connection races
	if base, ok := req.ProviderData.(*clientpkg.Client); ok && base != nil {
		r.client = base.Clone()
	}
}

func (r *deviceResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan deviceModel
	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	// TODO: Call backend to create device. For now, synthesize an ID.
	if plan.Name.IsNull() || plan.Name.ValueString() == "" {
		plan.Name = types.StringValue("device")
	}
	plan.ID = types.StringValue("catena-" + plan.Name.ValueString())

	// Ensure computed attributes are set to known values.
	// Default to empty container ID so the result object is valid even if Docker workflow fails.
	plan.ContainerID = types.StringValue("")

	// Determine device type and workflow
	deviceType := plan.DeviceType.ValueString()
	var ports []string
	if deviceType == "remote-grpc" {
		// For remote-grpc: no Docker; require address and port, and set gRPC endpoint
		addr := strings.TrimSpace(plan.Address.ValueString())
		port := plan.Port.ValueInt64()
		if addr == "" || port <= 0 {
			resp.Diagnostics.AddError("remote-grpc requires address and port", "Provide 'address' (host or URL) and 'port' when device_type=remote-grpc.")
			return
		}
		// Preserve scheme if present and any host components; keep host without path
		scheme := ""
		host := addr
		if i := strings.Index(host, "://"); i >= 0 {
			scheme = strings.ToLower(host[:i])
			host = host[i+3:]
		}
		if j := strings.IndexByte(host, '/'); j >= 0 {
			host = host[:j]
		}
		// Set endpoint for client, including scheme when provided so client decides TLS
		if r.client != nil && r.client.Transport == "grpc" {
			if scheme != "" {
				r.client.SetEndpoint(fmt.Sprintf("%s://%s:%d", scheme, host, port))
			} else {
				r.client.SetEndpoint(fmt.Sprintf("%s:%d", host, port))
			}
		}
		// Ensure no container id
		plan.ContainerID = types.StringValue("")
		// No Docker wait needed
	}

	// Extract slot once for subsequent gRPC calls
	slot := plan.Slot.ValueInt64()

	// 3) using grpc set params from map and explicit pairs
	if r.client != nil && r.client.Transport == "grpc" {
		// For docker-based devices, map host port; for remote-grpc, endpoint already set
		if deviceType != "remote-grpc" {
			// If a port mapping to internal 6254 is set, update client endpoint to <dockerHost>:<hostPort>
			if hp := r.selectHostPortForInternal(ports, 6254); hp > 0 {
				r.client.SetEndpoint(fmt.Sprintf("%s:%d", r.dockerHost(), hp))
			}
		}
		// Structured inputs and selected_flow_id removed; use params_map or params
		// Next, apply any params from the generic params_map
		if !plan.ParamsMap.IsNull() && !plan.ParamsMap.IsUnknown() {
			var pm map[string]string
			di := plan.ParamsMap.ElementsAs(ctx, &pm, false)
			resp.Diagnostics.Append(di...)
			if !resp.Diagnostics.HasError() {
				for oid, sval := range pm {
					val := r.parseValueString(sval)
					switch v := val.(type) {
					case string:
						if err := r.setStringValueWithRetry(ctx, uint32(slot), oid, v); err != nil {
							resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
							return
						}
					case float64:
						if err := r.setNumberValueWithRetry(ctx, uint32(slot), oid, v); err != nil {
							resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
							return
						}
					case bool:
						sv := "false"
						if v {
							sv = "true"
						}
						if err := r.setStringValueWithRetry(ctx, uint32(slot), oid, sv); err != nil {
							resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
							return
						}
					}
				}
			}
		}
		// Finally, set each provided param pair (overrides any previous values if overlapping)
		for _, p := range plan.Params {
			oid := p.Oid.ValueString()
			if oid == "" {
				continue
			}
			// Decode string value into primitive types (int/float/bool) when possible
			val := r.parseValueString(p.Value.ValueString())
			switch v := val.(type) {
			case string:
				if err := r.setStringValueWithRetry(ctx, uint32(slot), oid, v); err != nil {
					resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
					return
				}
			case float64:
				if err := r.setNumberValueWithRetry(ctx, uint32(slot), oid, v); err != nil {
					resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
					return
				}
			case bool:
				sv := "false"
				if v {
					sv = "true"
				}
				if err := r.setStringValueWithRetry(ctx, uint32(slot), oid, sv); err != nil {
					resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
					return
				}
			default:
				// Unsupported type; skip
			}
		}
	}

	// If a start_command is specified, honor required behavior:
	// wait 3s, send the command, then wait for device_status==ready_value.
	if r.client != nil && r.client.Transport == "grpc" && !plan.StartCommand.IsNull() && plan.StartCommand.ValueString() != "" {
		resp.Diagnostics.AddWarning("device start", fmt.Sprintf("Sleeping 3s then sending start_command: %s", plan.StartCommand.ValueString()))
		// wait 3 seconds before issuing start command
		time.Sleep(3 * time.Second)
		// send start command
		if err := r.client.RunStart(ctx, uint32(slot), plan.StartCommand.ValueString()); err != nil {
			resp.Diagnostics.AddError("gRPC ExecuteCommand start failed", err.Error())
			return
		}
		resp.Diagnostics.AddWarning("device start", "Start command sent; awaiting ready state if configured")
		// then, if device_status is configured, wait until ready
		if plan.DeviceStatus != nil {
			endpoint := plan.DeviceStatus.Endpoint.ValueString()
			if endpoint == "" {
				endpoint = plan.DeviceStatus.Oid.ValueString()
			}
			ready := plan.DeviceStatus.ReadyValue.ValueString()
			if endpoint != "" && ready != "" {
				resp.Diagnostics.AddWarning("device start", fmt.Sprintf("Waiting for status %s to equal %q", endpoint, ready))
				if err := r.client.WaitReady(ctx, uint32(slot), endpoint, ready, 60*time.Second); err != nil {
					resp.Diagnostics.AddError("gRPC WaitReady failed", err.Error())
					return
				}
				resp.Diagnostics.AddWarning("device start", "Device reported ready state")
			}
		}
	}

	// In all cases, update status_value if device_status is configured (no waiting unless start_command used)
	if r.client != nil && r.client.Transport == "grpc" && plan.DeviceStatus != nil {
		endpoint := plan.DeviceStatus.Endpoint.ValueString()
		if endpoint == "" {
			endpoint = plan.DeviceStatus.Oid.ValueString()
		}
		// Fetch current status_value to ensure a known computed value after apply
		if endpoint != "" {
			if val, err := r.client.GetStringValue(ctx, uint32(slot), endpoint); err == nil {
				plan.StatusValue = types.StringValue(val)
			} else {
				plan.StatusValue = types.StringValue("")
			}
		} else {
			plan.StatusValue = types.StringValue("")
		}
	} else {
		// Ensure status_value is set to a known value even when gRPC/status not configured
		if plan.StatusValue.IsNull() || plan.StatusValue.IsUnknown() {
			plan.StatusValue = types.StringValue("")
		}
	}

	diags = resp.State.Set(ctx, &plan)
	resp.Diagnostics.Append(diags...)
}

func (r *deviceResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state deviceModel
	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
	// Refresh status_value via gRPC if possible; set client endpoint
	if r.client != nil && r.client.Transport == "grpc" {
		dtype := state.DeviceType.ValueString()
		if dtype == "remote-grpc" {
			addr := strings.TrimSpace(state.Address.ValueString())
			p := state.Port.ValueInt64()
			if addr != "" && p > 0 {
				scheme := ""
				host := addr
				if i := strings.Index(host, "://"); i >= 0 {
					scheme = strings.ToLower(host[:i])
					host = host[i+3:]
				}
				if j := strings.IndexByte(host, '/'); j >= 0 {
					host = host[:j]
				}
				if scheme != "" {
					r.client.SetEndpoint(fmt.Sprintf("%s://%s:%d", scheme, host, p))
				} else {
					r.client.SetEndpoint(fmt.Sprintf("%s:%d", host, p))
				}
			}
		}
	}
	// Now poll device_status if configured
	if r.client != nil && r.client.Transport == "grpc" && state.DeviceStatus != nil {
		endpoint := state.DeviceStatus.Endpoint.ValueString()
		if endpoint == "" {
			endpoint = state.DeviceStatus.Oid.ValueString()
		}
		if endpoint != "" {
			if val, err := r.client.GetStringValue(ctx, uint32(state.Slot.ValueInt64()), endpoint); err == nil {
				state.StatusValue = types.StringValue(val)
			}
		}
	}
	// Ensure container_id is populated by querying Docker if missing (non-remote-grpc)
	if state.DeviceType.ValueString() != "remote-grpc" {
		if (state.ContainerID.IsNull() || state.ContainerID.IsUnknown() || state.ContainerID.ValueString() == "") && r.commandExists("docker") {
			if cid := r.getContainerID(state.Name.ValueString()); cid != "" {
				state.ContainerID = types.StringValue(cid)
			}
		}
	}
	diags = resp.State.Set(ctx, &state)
	resp.Diagnostics.Append(diags...)
}

func (r *deviceResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan deviceModel
	var prev deviceModel
	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
	diags = req.State.Get(ctx, &prev)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Preserve computed attributes from previous state when not recalculated here
	if plan.ID.IsNull() || plan.ID.IsUnknown() || plan.ID.ValueString() == "" {
		if !prev.ID.IsNull() && !prev.ID.IsUnknown() && prev.ID.ValueString() != "" {
			plan.ID = prev.ID
		} else {
			plan.ID = types.StringValue("catena-" + plan.Name.ValueString())
		}
	}
	// Always carry forward container_id from previous state unless explicitly changed elsewhere
	if !prev.ContainerID.IsNull() && !prev.ContainerID.IsUnknown() && prev.ContainerID.ValueString() != "" {
		plan.ContainerID = prev.ContainerID
	}
	// If still missing, attempt to resolve via Docker
	if (plan.ContainerID.IsNull() || plan.ContainerID.IsUnknown() || plan.ContainerID.ValueString() == "") && r.commandExists("docker") {
		if cid := r.getContainerID(plan.Name.ValueString()); cid != "" {
			plan.ContainerID = types.StringValue(cid)
		}
	}
	if plan.StatusValue.IsNull() || plan.StatusValue.IsUnknown() {
		if !prev.StatusValue.IsNull() && !prev.StatusValue.IsUnknown() {
			plan.StatusValue = prev.StatusValue
		}
	}

	// Apply changed params via gRPC on update
	if r.client != nil && r.client.Transport == "grpc" {
		// Determine endpoint based on device type
		// Prefer plan.DeviceType, fallback to prev.DeviceType
		dtype := plan.DeviceType.ValueString()
		if dtype == "" {
			dtype = prev.DeviceType.ValueString()
		}
		if dtype == "remote-grpc" {
			// Resolve address/port from plan or prev, preserve scheme for TLS
			addr := strings.TrimSpace(plan.Address.ValueString())
			if addr == "" {
				addr = strings.TrimSpace(prev.Address.ValueString())
			}
			p := plan.Port.ValueInt64()
			if p == 0 {
				p = prev.Port.ValueInt64()
			}
			if addr != "" && p > 0 {
				scheme := ""
				host := addr
				if i := strings.Index(host, "://"); i >= 0 {
					scheme = strings.ToLower(host[:i])
					host = host[i+3:]
				}
				if j := strings.IndexByte(host, '/'); j >= 0 {
					host = host[:j]
				}
				if scheme != "" {
					r.client.SetEndpoint(fmt.Sprintf("%s://%s:%d", scheme, host, p))
				} else {
					r.client.SetEndpoint(fmt.Sprintf("%s:%d", host, p))
				}
			}
		}

		// Resolve slot
		slot := plan.Slot.ValueInt64()
		if slot == 0 {
			slot = prev.Slot.ValueInt64()
		}

		// Read apply_all flag
		applyAll := false
		if !plan.ApplyAll.IsNull() && !plan.ApplyAll.IsUnknown() {
			applyAll = plan.ApplyAll.ValueBool()
		}

		// Diff params_map and set values
		var prevMap, planMap map[string]string
		if !prev.ParamsMap.IsNull() && !prev.ParamsMap.IsUnknown() {
			di := prev.ParamsMap.ElementsAs(ctx, &prevMap, false)
			resp.Diagnostics.Append(di...)
		}
		if !plan.ParamsMap.IsNull() && !plan.ParamsMap.IsUnknown() {
			di := plan.ParamsMap.ElementsAs(ctx, &planMap, false)
			resp.Diagnostics.Append(di...)
		}
		// Apply changes for keys present in planMap; if applyAll, apply all regardless of diff
		for oid, sval := range planMap {
			if applyAll || prevMap == nil || prevMap[oid] != sval {
				val := r.parseValueString(sval)
				switch v := val.(type) {
				case string:
					if err := r.client.SetStringValue(ctx, uint32(slot), oid, v); err != nil {
						resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
						return
					}
				case float64:
					if err := r.client.SetNumberValue(ctx, uint32(slot), oid, v); err != nil {
						resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
						return
					}
				case bool:
					sv := "false"
					if v {
						sv = "true"
					}
					if err := r.client.SetStringValue(ctx, uint32(slot), oid, sv); err != nil {
						resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
						return
					}
				}
			}
		}
		// Also apply explicit params pairs from plan (treated as authoritative)
		for _, p := range plan.Params {
			oid := p.Oid.ValueString()
			if strings.TrimSpace(oid) == "" {
				continue
			}
			val := r.parseValueString(p.Value.ValueString())
			switch v := val.(type) {
			case string:
				if err := r.client.SetStringValue(ctx, uint32(slot), oid, v); err != nil {
					resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
					return
				}
			case float64:
				if err := r.client.SetNumberValue(ctx, uint32(slot), oid, v); err != nil {
					resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
					return
				}
			case bool:
				sv := "false"
				if v {
					sv = "true"
				}
				if err := r.client.SetStringValue(ctx, uint32(slot), oid, sv); err != nil {
					resp.Diagnostics.AddError("gRPC SetValue failed", err.Error())
					return
				}
			}
		}
	}

	diags = resp.State.Set(ctx, &plan)
	resp.Diagnostics.Append(diags...)
}

func (r *deviceResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state deviceModel
	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
	// name not used; docker operations removed
	// Set endpoint for remote-grpc devices
	if r.client != nil && r.client.Transport == "grpc" && state.DeviceType.ValueString() == "remote-grpc" {
		addr := strings.TrimSpace(state.Address.ValueString())
		p := state.Port.ValueInt64()
		if addr != "" && p > 0 {
			scheme := ""
			host := addr
			if i := strings.Index(host, "://"); i >= 0 {
				scheme = strings.ToLower(host[:i])
				host = host[i+3:]
			}
			if j := strings.IndexByte(host, '/'); j >= 0 {
				host = host[:j]
			}
			if scheme != "" {
				r.client.SetEndpoint(fmt.Sprintf("%s://%s:%d", scheme, host, p))
			} else {
				r.client.SetEndpoint(fmt.Sprintf("%s:%d", host, p))
			}
		}
	}
	// If using gRPC, only run stop_command when device_status indicates ready_value
	if r.client != nil && r.client.Transport == "grpc" && state.DeviceStatus != nil {
		endpoint := state.DeviceStatus.Endpoint.ValueString()
		if endpoint == "" {
			endpoint = state.DeviceStatus.Oid.ValueString()
		}
		ready := state.DeviceStatus.ReadyValue.ValueString()
		slot := uint32(state.Slot.ValueInt64())
		if endpoint != "" && ready != "" && !state.StopCommand.IsNull() && state.StopCommand.ValueString() != "" {
			if val, err := r.client.GetStringValue(ctx, slot, endpoint); err == nil && val == ready {
				_ = r.client.RunStop(ctx, slot, state.StopCommand.ValueString())
			}
		}
	}
}

// Helpers
func (r *deviceResource) resolveDevicesDir() string {
	candidates := []string{
		// New preferred locations under opentofu/
		"../opentofu/exe",
		"../../opentofu/exe",
		"/workspace/opentofu/exe",
		"./opentofu/exe",
		// Legacy fallbacks
		"../exe",
		"../../exe",
		"/workspace/exe",
		"./exe",
	}
	if r.client != nil && r.client.DevicesDir != "" {
		candidates = []string{r.client.DevicesDir}
	}
	for _, c := range candidates {
		if r.pathExists(c) {
			return c
		}
	}
	return "."
}

func (r *deviceResource) pathExists(p string) bool {
	info, err := os.Stat(p)
	return err == nil && info.IsDir()
}

func (r *deviceResource) commandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

// selectHostPortForInternal scans port mappings and returns the host port mapped to the given internal port.
// Supports formats like "7254:6254" and "127.0.0.1:7254:6254[/proto]".
func (r *deviceResource) selectHostPortForInternal(ports []string, internal int) int {
	for _, p := range ports {
		s := strings.TrimSpace(p)
		if s == "" {
			continue
		}
		// strip protocol suffix
		protoIdx := strings.IndexByte(s, '/')
		if protoIdx >= 0 {
			s = s[:protoIdx]
		}
		parts := strings.Split(s, ":")
		if len(parts) < 2 {
			continue
		}
		// container port is last part
		cpart := parts[len(parts)-1]
		hpart := parts[len(parts)-2]
		// If there are 3 parts (ip:host:container), hpart is correctly the host port
		// Parse ints
		if cp, err := strconv.Atoi(cpart); err == nil && cp == internal {
			if hp, err2 := strconv.Atoi(hpart); err2 == nil {
				return hp
			}
		}
	}
	return 0
}

// dockerHost returns the appropriate host name for reaching services exposed on the host
// from the current runtime. When running inside a Docker container, it returns
// host.docker.internal (Linux setups require extra_hosts). Otherwise, it returns localhost.
func (r *deviceResource) dockerHost() string {
	if _, err := os.Stat("/.dockerenv"); err == nil {
		return "host.docker.internal"
	}
	return "localhost"
}

func (r *deviceResource) dockerExec(ctx context.Context, name, command string) error {
	cmd := exec.CommandContext(ctx, "docker", "exec", name, "/bin/sh", "-lc", command)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("docker exec error: %v\n%s", err, string(out))
	}
	return nil
}

// getContainerID returns the container ID for a given name, or empty string if not found.
func (r *deviceResource) getContainerID(name string) string {
	if strings.TrimSpace(name) == "" {
		return ""
	}
	cmd := exec.Command("docker", "ps", "--format", "{{.ID}} {{.Names}}")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return ""
	}
	lines := strings.Split(string(out), "\n")
	for _, line := range lines {
		parts := strings.Fields(strings.TrimSpace(line))
		if len(parts) >= 2 && parts[1] == name {
			return parts[0]
		}
	}
	return ""
}

// decodeDynamic attempts to extract a primitive from a Dynamic value.
func (r *deviceResource) parseValueString(s string) any {
	if s == "" {
		return ""
	}
	// Try boolean
	if strings.EqualFold(s, "true") {
		return true
	}
	if strings.EqualFold(s, "false") {
		return false
	}
	// Try integer
	if iv, err := strconv.ParseInt(s, 10, 32); err == nil {
		return float64(iv)
	}
	// Try float
	if fv, err := strconv.ParseFloat(s, 64); err == nil {
		return fv
	}
	// Default string
	return s
}

// SetValue retry helpers to mitigate transient startup readiness issues
func (r *deviceResource) setStringValueWithRetry(ctx context.Context, slot uint32, oid, value string) error {
	var lastErr error
	for i := 0; i < 3; i++ {
		if err := r.client.SetStringValue(ctx, slot, oid, value); err == nil {
			return nil
		} else {
			lastErr = err
		}
		time.Sleep(time.Duration(500*(i+1)) * time.Millisecond)
	}
	return lastErr
}

func (r *deviceResource) setNumberValueWithRetry(ctx context.Context, slot uint32, oid string, n float64) error {
	var lastErr error
	for i := 0; i < 3; i++ {
		if err := r.client.SetNumberValue(ctx, slot, oid, n); err == nil {
			return nil
		} else {
			lastErr = err
		}
		time.Sleep(time.Duration(500*(i+1)) * time.Millisecond)
	}
	return lastErr
}
