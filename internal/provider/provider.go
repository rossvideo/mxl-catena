package provider

import (
    "context"

    "github.com/hashicorp/terraform-plugin-framework/datasource"
    "github.com/hashicorp/terraform-plugin-framework/provider"
    "github.com/hashicorp/terraform-plugin-framework/provider/schema"
    "github.com/hashicorp/terraform-plugin-framework/resource"
    "github.com/hashicorp/terraform-plugin-framework/types"

    clientpkg "github.com/rossvideo/terraform-provider-st2138/internal/client"
    respkg "github.com/rossvideo/terraform-provider-st2138/internal/resources"
)

// New returns a new instance of the Catena provider.
func New() provider.Provider {
    return &catenaProvider{}
}

type catenaProvider struct{}

type catenaProviderModel struct {
    Endpoint  types.String `tfsdk:"endpoint"`
    Transport types.String `tfsdk:"transport"`
    DevicesDir types.String `tfsdk:"devices_dir"`
    ExecutablesDir types.String `tfsdk:"executables_dir"`
}

func (p *catenaProvider) Metadata(_ context.Context, _ provider.MetadataRequest, resp *provider.MetadataResponse) {
    resp.TypeName = "catena"
}

func (p *catenaProvider) Schema(_ context.Context, _ provider.SchemaRequest, resp *provider.SchemaResponse) {
    resp.Schema = schema.Schema{
        Description: "OpenTofu provider for Catena devices/services.",
        Attributes: map[string]schema.Attribute{
            "endpoint": schema.StringAttribute{
                Optional:    true,
                Description: "Service endpoint, e.g. host:port",
            },
            "transport": schema.StringAttribute{
                Optional:    true,
                Description: "Transport type (e.g. grpc, http)",
            },
            "devices_dir": schema.StringAttribute{
                Optional:    true,
                Description: "Base directory containing per-device-type Dockerfiles (each under devices_dir/<device_type>). Defaults to ../devices relative to the working directory.",
            },
            "executables_dir": schema.StringAttribute{
                Optional:    true,
                Description: "Alias for devices_dir: base directory containing per-device-type executables/Dockerfiles (each under <dir>/<device_type>).",
            },
        },
    }
}

func (p *catenaProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
    var data catenaProviderModel
    diags := req.Config.Get(ctx, &data)
    resp.Diagnostics.Append(diags...)
    if resp.Diagnostics.HasError() {
        return
    }

    // Build a simple client from provider config.
    cli := &clientpkg.Client{
        Endpoint:  data.Endpoint.ValueString(),
        Transport: data.Transport.ValueString(),
        DevicesDir: func() string {
            // Prefer executables_dir if provided, else fallback to devices_dir
            if v := data.ExecutablesDir.ValueString(); v != "" {
                return v
            }
            return data.DevicesDir.ValueString()
        }(),
    }

    resp.DataSourceData = cli
    resp.ResourceData = cli
}

func (p *catenaProvider) Resources(_ context.Context) []func() resource.Resource {
    return []func() resource.Resource{
        respkg.NewDeviceResource,
    }
}

func (p *catenaProvider) DataSources(_ context.Context) []func() datasource.DataSource {
    return []func() datasource.DataSource{}
}
