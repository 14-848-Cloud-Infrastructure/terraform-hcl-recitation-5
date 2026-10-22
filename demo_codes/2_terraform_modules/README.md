# Modules Example

This directory demonstrates using a **reusable module** for the web instances. The same layout as `project_organization` is used, but the `web-instances` (the three `web0`, `web1`, `web2` VMs) are defined inside a separate **web-server** module.

## Layout

```
demo_codes/modules/
├── main.tf           # Provider, nginx, module call, web-map-instances, mysqldb
├── variables.tf      # Root input variables
├── outputs.tf        # Root outputs (includes module outputs)
├── networking.tf     # Subnet and firewall
├── data.tf           # Default network data source
├── storage.tf        # GCS buckets
├── inputs.tfvars     # Example variable values
└── web-server/       # Web instances module
    ├── main.tf       # google_compute_instance.web-instances (count = 3)
    ├── variables.tf  # Module input variables
    └── outputs.tf    # network_ips, instance_names
```

## Usage

From this directory:

```bash
terraform init
terraform plan -var="project-id=cmu-26fall-recitation-5" -var="region=us-central1" -out=tfplan
terraform apply tfplan
```

## What the module does

- **web-server** creates a fixed number of identical web VMs (no external IP), each with the same machine type, labels, and boot image.
- The root module passes: `instance_count`, `machine_type`, `labels`, `network_self_link`, `subnetwork_self_link`.
- Root `webserver-ips` output comes from the module’s `network_ips` output.

See the main repo **Readme** → **Modules** section for the full guide and this example in context.
