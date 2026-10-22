/*
Demo 1: Project organization + core Terraform language features (GCP)

This file focuses on "compute" resources (VM instances) and shows:
- How to configure the Google provider (credentials/project/region/zone)
- How to parameterize config with variables (`var.*`)
- Two ways to create multiple similar resources:
  - `count` (indexed instances)
  - `for_each` (keyed instances driven by a map)

Related files in this demo:
- `variables.tf`: input variables used here
- `networking.tf`: subnet + firewall used by these instances
- `data.tf`: data sources (read-only lookups) used by these instances
- `outputs.tf`: values printed after `terraform apply`
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
  # The GCP project all resources will be created in.
  project = var.project-id

  # Default region/zone for zonal resources (like `google_compute_instance`).
  region = var.region
  zone   = var.zone

  # Loads service account JSON credentials from a local file.
  # Keep this file out of git (it's a secret).
  credentials = file("../../key.json")
}

resource "google_compute_instance" "nginx_instance" {
  name = "nginx-proxy"
  # Pick the VM size based on the selected environment (DEV vs PROD).
  machine_type = var.environment_machine_type[var.target_environment]
  labels = {
    # Labels are metadata you can filter/search in the GCP console.
    environment = var.environment_map[var.target_environment]
  }
  # Network tags are used by firewall rules (see `networking.tf`).
  tags = var.compute-source-tags

  boot_disk {
    initialize_params {
      # Boot image for the VM (Debian 11).
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    # Attach to the default VPC network, but use our custom subnet.
    network    = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
    access_config {
      # `access_config {}` allocates an ephemeral external IP.
      # We keep an empty block here to make it obvious that this instance is public.
    }
  }
}

resource "google_compute_instance" "web-instances" {
  # `count` creates N copies of this resource. Each copy is indexed by `count.index`.
  # `count.index` is the index of the current resource in the loop.
  # Individual instance of this resource can be addressed with the `google_compute_instance.web-instances[<some_index (0, 1, 2)>]` syntax.
  # All the instances can be addressed with the `google_compute_instance.web-instances[*]` syntax.
  count        = 3
  name         = "web${count.index}"
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
    network    = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
  }
}

resource "google_compute_instance" "web-map-instances" {
  # `for_each` creates one instance per key in the map.
  # The key and value of the map can be accessed through the `each` variable: each.key and each.value 
  # `each` is only accessible within the for_each block.
  for_each     = var.environment_instance_settings
  name         = "${lower(each.key)}-web"
  machine_type = each.value.machine_type
  labels       = each.value.labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
  }
}

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
    # No `access_config` here => private-only VM (no external IP).
    network    = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
  }
}