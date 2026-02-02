package main

import (
    "context"

    "github.com/hashicorp/terraform-plugin-framework/providerserver"
    providerpkg "github.com/rossvideo/terraform-provider-st2138/internal/provider"
)

func main() {
    providerserver.Serve(context.Background(), providerpkg.New, providerserver.ServeOpts{
        // Full provider address to match local mirror path.
        Address: "registry.opentofu.org/local/catena",
    })
}
