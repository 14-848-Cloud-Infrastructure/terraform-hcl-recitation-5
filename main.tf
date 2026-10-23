/*
Root example: Full configuration in a single file + remote state backend

                       Internet
                          |
                          v
+--------------- Existing default VPC ----------------+
|                                                    |
|  +---------------- Subnet: subnet1 -------------+  |
|  |                                              |  |
|  |              nginx-proxy                     |  |
|  |              Public IP                       |  |
|  |                   |                          |  |
|  |         +---------+---------+                |  |
|  |         v         v         v                |  |
|  |       web1      web2      web3                |  |
|  |         |         |         |                |  |
|  |         +---------+---------+                |  |
|  |                   v                          |  |
|  |                mysqldb                       |  |
|  |                                              |  |
|  |    All five VMs have internal IP addresses.   |  |
|  +----------------------------------------------+  |
+----------------------------------------------------+


This file appears to be a "monolithic" version of the GCP example:
- Provider + data sources
- Networking (subnet + firewall)
- Several VM instances

It also includes a `backend "gcs"` block to demonstrate remote state.
Important:
- The backend block here only sets `prefix`. To actually use GCS remote state,
  you must also configure the bucket name (usually `bucket = "<state-bucket>"`),
  or supply it via partial backend configuration during `terraform init`.
- Creating the state bucket itself is typically done once (see demo 3).
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
  # GCP project used for this recitation.
  project = "cmu-26fall-recitation-5"
  region  = "us-central1"

  # Loads service account credentials from a local file.
  # Keep `key.json` out of git.
  credentials = file("key.json")
}

data "google_compute_zones" "available" {
  # Query available zones within the chosen region.
  region = "us-central1"
}

data "google_compute_network" "default" {
  # Read the existing default VPC network.
  name = "default"
}

locals {
  # Locals are named expressions used to avoid repeating values.
  region = "us-central1"
  zones  = data.google_compute_zones.available.names
}

resource "google_compute_subnetwork" "subnet-1" {
  # A custom subnet inside the default VPC.
  name                     = "subnet1"
  ip_cidr_range            = "10.127.0.0/20"
  network                  = data.google_compute_network.default.self_link
  region                   = local.region
  private_ip_google_access = true
}

resource "google_compute_firewall" "default" {
  # Inbound firewall rule scoped to instances tagged "web".
  name    = "test-firewall"
  network = data.google_compute_network.default.self_link

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000", "22"]
  }

  source_tags = ["web"]
}

resource "google_compute_instance" "nginx_instance" {
  # Public-facing instance (has `access_config` => external IP).
  name         = "nginx-proxy"
  machine_type = "f1-micro"
  zone         = local.zones[0]
  tags         = ["web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
    access_config {
      # Empty block requests an ephemeral external IP.
    }
  }
}

resource "google_compute_instance" "web1" {
  # Private-only web instances (no external IP configured).
  name         = "web1"
  machine_type = "f1-micro"
  zone         = local.zones[0]

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
resource "google_compute_instance" "web2" {
  name         = "web2"
  machine_type = "f1-micro"
  zone         = local.zones[0]

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
resource "google_compute_instance" "web3" {
  name         = "web3"
  machine_type = "f1-micro"
  zone         = local.zones[0]

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
  # Example DB VM (private-only).
  name         = "mysqldb"
  machine_type = "f1-micro"
  zone         = local.zones[0]

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