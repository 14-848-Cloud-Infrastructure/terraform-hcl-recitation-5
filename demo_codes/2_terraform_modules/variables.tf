/*
Demo 2: Input variables for a module-based configuration

These inputs are consumed by:
- root resources (nginx proxy VM, DB VM, subnet, firewall, buckets)
- the `webservers` child module (via `module "webservers" { ... }`)
*/

variable "project-id" {
  # GCP project ID where resources are created.
  type    = string
  default = "cmu-26fall-recitation-5"
}

variable "region" {
  # Region for regional resources (like the subnet).
  type = string
}

variable "zone" {
  # Zone for zonal resources (Compute Engine VMs).
  type    = string
  default = "us-central1-a"
}

variable "subnet-name" {
  # Subnet name.
  type    = string
  default = "subnet1"
}

variable "subnet-cidr" {
  # Subnet CIDR range.
  type    = string
  default = "10.127.0.0/20"
}

variable "private_google_access" {
  # Allow private instances to reach Google APIs without public IPs.
  type    = bool
  default = true
}

variable "firewall-ports" {
  # TCP ports to allow through the firewall rule.
  type    = list(any)
  default = ["80", "8080", "1000-2000", "22"]
}

variable "compute-source-tags" {
  # Network tags applied to instances; firewall scopes to these tags.
  type    = list(any)
  default = ["web"]
}

variable "target_environment" {
  # Select which environment settings to use ("DEV" or "PROD").
  default = "DEV" # DEV, PROD
}

variable "environment_list" {
  # Used to create one bucket per environment.
  type    = list(string)
  default = ["DEV", "PROD"]
}

variable "environment_map" {
  # Map environment key -> label value.
  type = map(string)
  default = {
    "DEV"  = "dev"
    "PROD" = "prod"
  }
}

variable "environment_machine_type" {
  # Map environment -> VM machine type.
  type = map(string)
  default = {
    "DEV"  = "f1-micro"
    "PROD" = "e2-medium"
  }
}

variable "environment_instance_settings" {
  # Environment-specific settings passed into the child module for webservers.
  type = map(object({ machine_type = string, labels = map(string) }))
  default = {
    "DEV" = {
      machine_type = "f1-micro"
      labels = {
        environment = "dev"
      }
    },
    "PROD" = {
      machine_type = "e2-medium"
      labels = {
        environment = "prod"
      }
    }
  }
}
