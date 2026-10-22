/*
Demo 1: Input variables

Variables make Terraform configurations reusable:
- You can set values via `-var`, `.tfvars` files, or environment variables in your terminal when running the terraform command. 
- Variables can have types and defaults.

Naming note:
- This demo uses hyphens in variable names (e.g., `project-id`). Terraform allows this,
  but many teams prefer underscores for consistency.
*/

variable "project-id" {
  # GCP project ID where resources are created.
  type    = string
  default = "cmu-26fall-recitation-5"
}

variable "region" {
  # Region where regional resources (like subnets) live.
  type = string
  # default = "us-central1"
}

variable "zone" {
  # Zone for zonal resources (Compute Engine VMs).
  type    = string
  default = "us-central1-a"
}

variable "subnet-name" {
  # Name for the subnetwork resource we create.
  type    = string
  default = "subnet1"
}

variable "subnet-cidr" {
  # CIDR block for the subnet. Must not overlap other subnets in the VPC.
  type    = string
  default = "10.127.0.0/20"
}

variable "private_google_access" {
  # When true, VMs without public IPs can still reach Google APIs internally.
  type    = bool
  default = true
}

variable "firewall-ports" {
  # Allowed TCP ports for instances tagged with `compute-source-tags`.
  type    = list(any)
  default = ["80", "8080", "1000-2000", "22"]
}

variable "compute-source-tags" {
  # Network tags applied to instances (used by firewall rules).
  type    = list(any)
  default = ["web"]
}

variable "target_environment" {
  # Choose which environment settings to use.
  # In real projects you might set this via `-var="target_environment=PROD"`.
  default = "DEV" # DEV, PROD
}

variable "environment_list" {
  # Used by `storage.tf` to create one bucket per environment.
  type    = list(string)
  default = ["DEV", "PROD"]
}

variable "environment_map" {
  # Converts a friendly environment key to a label value.
  type = map(string)
  default = {
    "DEV"  = "dev",
    "PROD" = "prod"
  }
}

variable "environment_machine_type" {
  # Map environment -> machine type (VM size).
  type = map(string)
  default = {
    "DEV"  = "f1-micro",
    "PROD" = "e2-medium"
  }
}

variable "environment_instance_settings" {
  # Example of a nested type:
  # - map keyed by environment (DEV/PROD)
  # - each value is an object with machine_type and a labels map
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