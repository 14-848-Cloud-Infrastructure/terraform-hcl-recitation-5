/*
Child module: webservers

This module encapsulates the "create one VM per environment" pattern.

Inputs (see `variables.tf`):
- `server_settings`: map keyed by environment (DEV/PROD), with machine_type + labels
- `network_interface`: object containing network + subnetwork self_links
- `project_id`: which GCP project to place instances in
- `prefix`: optional naming prefix (e.g., "web-")

Key Terraform concept:
- `for_each` creates one resource instance per map entry, keyed by the map keys.
  That means Terraform addresses look like:
    google_compute_instance.web-instances["DEV"]
    google_compute_instance.web-instances["PROD"]
*/

locals {
  # Add a trailing dash only when a non-empty prefix is provided.
  prefix = var.prefix != "" ? "${var.prefix}-" : ""
}

resource "google_compute_instance" "web-instances" {
  # Create one VM per entry in `var.server_settings`.
  for_each = var.server_settings

  # Setting `project` here makes the module explicit about where resources go,
  # instead of relying on an implicit provider default.
  project = var.project_id
  # Example names: "web-dev", "web-prod" (depending on prefix and map key).
  name         = "${local.prefix}${lower(each.key)}"
  machine_type = each.value.machine_type
  labels       = each.value.labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    # These are passed from the root module so networking is shared/consistent.
    network    = var.network_interface.network
    subnetwork = var.network_interface.subnetwork
  }
}