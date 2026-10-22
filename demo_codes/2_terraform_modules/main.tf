/*
Demo 2: Terraform modules (GCP)

Goal of this demo:
- Keep the "root module" small and focused
- Move repeated patterns (web server instances) into a reusable child module

What you should notice:
- The `module "webservers"` block wires inputs into `./modules/webservers`
- Root module still owns shared infrastructure (subnet, firewall, proxy, DB)
- Outputs can reference both resources in the root module and outputs from child modules
*/

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  # Provider configuration applies to all google_* resources in this module.
  project     = var.project-id
  region      = var.region
  zone        = var.zone
  credentials = file("../../key.json")
}

# Nginx proxy instance (single instance with external IP)
resource "google_compute_instance" "nginx_instance" {
  name         = "nginx-proxy"
  machine_type = var.environment_machine_type[var.target_environment]
  labels = {
    environment = var.environment_map[var.target_environment]
  }
  tags = var.compute-source-tags

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
    access_config {}
  }
}

module "webservers" {
  # `source` points at the child module directory (relative path here).
  source = "./modules/webservers"

  # Pass values from root variables into the child module's variables.
  # This is how modules become configurable/reusable.
  project_id      = var.project-id
  server_settings = var.environment_instance_settings
  region          = var.region
  zone            = var.zone

  # Instead of letting the module look up networking itself, we pass the IDs/links
  # for the network/subnet created or referenced by the root module.
  network_interface = {
    network    = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
  }
}

# Database instance
resource "google_compute_instance" "mysqldb" {
  name         = "mysqldb"
  machine_type = var.environment_machine_type[var.target_environment]
  labels = {
    environment = var.environment_map[var.target_environment]
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    # No `access_config` => private-only VM.
    network    = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
  }
}
