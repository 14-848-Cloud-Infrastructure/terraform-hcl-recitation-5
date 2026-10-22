/*
Demo 3: Variables for remote state bucket creation

This demo keeps inputs minimal: project + (optional) region/zone for provider defaults.
*/

variable "project-id" {
  # GCP project ID where the bucket will be created.
  type    = string
  default = "cmu-26fall-recitation-5"
}

variable "region" {
  # Region used as a provider default (the bucket itself is multi-region "US" below).
  type    = string
  default = "us-central1"
}

variable "zone" {
  # Zone used as a provider default (not directly used by the bucket resource).
  type    = string
  default = "us-central1-a"
}