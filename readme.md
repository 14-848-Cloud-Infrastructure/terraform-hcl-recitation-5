# Readme
**Project ID: `cmu-26fall-recitation-5`.** The commands and Terraform examples below use this project. Please replace it with your own project id.

## Setup

### setup gcloud, terraform, service accounts
For a fresh project, first link an active billing account. Run the setup commands with a user account that can enable APIs (`serviceusage.services.enable`, included in `roles/serviceusage.serviceUsageAdmin`) and manage the service account and IAM roles below.

```bash
# login gcloud cli to your corresponding account
gcloud auth login

# select the project before enabling APIs or creating service accounts
gcloud config set project cmu-26fall-recitation-5
gcloud config get-value project

# Enable required APIs before terraform plan (including its Compute data sources).
# This waits for API enablement to finish; it can be rerun for an existing project.
gcloud services enable \
  serviceusage.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  storage.googleapis.com \
  --project=cmu-26fall-recitation-5

# initialize terraform 
terraform init

# create new service account for terraform 
# It will have limited permissions (principle of least privilege)
gcloud iam service-accounts create terraform-sa --display-name="Terraform" \
  --project=cmu-26fall-recitation-5
gcloud iam service-accounts keys create key.json \
     --iam-account=terraform-sa@cmu-26fall-recitation-5.iam.gserviceaccount.com

# The command above will create the key.json file in the same folder where it is executed. 

# Add required roles to the service account
gcloud projects add-iam-policy-binding cmu-26fall-recitation-5 \
  --member="serviceAccount:terraform-sa@cmu-26fall-recitation-5.iam.gserviceaccount.com" \
  --role="roles/compute.networkViewer"

```

API enablement is a project setup step. `custom-terraform-permissions.yaml` defines what the Terraform service account can do; granting those permissions does not enable APIs. This setup uses your logged-in `gcloud` user to enable APIs before Terraform reads zones and the default network during `plan`. No additional API-enablement permissions are needed in the Terraform custom role for this workflow. See Google's [API enablement guide](https://docs.cloud.google.com/service-usage/docs/enable-disable).

#### Custom roles with principle of least privilege 
Let us create a custom permission and keep all the roles that this terraform config requires there. 
I already have a `custom-terraform-permissions.yaml` file. You can copy this file and modify it as required. 
```sh
gcloud iam roles create terraformSaPermissions \
  --project=cmu-26fall-recitation-5 \
  --file=custom-terraform-permissions.yaml

# then assign the role to our terraform-sa service account
gcloud projects add-iam-policy-binding cmu-26fall-recitation-5 \
  --member="serviceAccount:terraform-sa@cmu-26fall-recitation-5.iam.gserviceaccount.com" \
  --role="projects/cmu-26fall-recitation-5/roles/terraformSaPermissions"
```
When new permission is required, add it in the `includedPermissions` array of `custom-terraform-permissions.yaml` file, and update the role 
```sh
gcloud iam roles update terraformSaPermissions \
  --project=cmu-26fall-recitation-5 \
  --file=custom-terraform-permissions.yaml
```

### VM image

The VM examples use `debian-cloud/debian-12`. Debian 11 reached end of support and image deprecation on August 31, 2026; use a supported image family for new deployments. See Google's [OS support table](https://docs.cloud.google.com/compute/docs/images/os-details#debian).

You can check that the image family resolves before planning:

```bash
gcloud compute images describe-from-family debian-12 --project=debian-cloud
```

`debian-cloud` is Google's public image project; keep that project name for this lookup. Terraform creates the VMs in `cmu-26fall-recitation-5`. The command above uses your logged-in `gcloud` account, while Terraform uses the service account in `key.json`.

## terraform init, plan, review, apply, destroy
These are the most common commands used in terraform.
```sh
# Needs to be run at the very beginning + anytime you add/update providers in your configuration
terraform init
# generate a plan
terraform plan -out s1.tfplan
# read the terraform plan file
terraform show s1.tfplan

# If you want to see plan in json format it:
# terraform show -json s1.tfplan | jq .
# If you want to see the DAG created by terraform
# (NOTE: this requires graphviz to be installed: https://graphviz.org/download/)
# terraform graph | dot -Tpng > viz.png

terraform apply s1.tfplan

# To read the terraform state file
terraform show

terraform destroy s1.tfplan
```


## HCL 

### expressions and functions
HCL has a bunch of useful expressios and functions that you can use in your configuration to dynamically create/maintain resources.

For testing, run these HCL values in the repl using command:
```bash
terraform console
```
This will open python-like repl where you can quickly test some commands. 
```hcl
> 5+5

> 5<=5 ? "yes" : "no"

> length("find_length")

> upper("terraform")

> lower("DEV")

> "${lower("DEV")}-database"

> split(",", "hello,14848")
> join(",", ["hello", "14848"])
```

### Review state files
You can also easily view the contents of your terraform state from the console. This is super useful. 
```sh
terraform console
> data.google_compute_zones.available
> google_compute_instance.web1
> google_compute_instance.web-instances[*].name
```
Make sure that these resources actually exist in your configuration.

## Separating configs 
Managing the entire terraform configuration in one file is difficult to maintain. Terraform doesn't impose a specfic way to structure your codebase but there is a general convention in the industry to manage your terraform projects. 
Here are some common files:
- **provider.tf**: Used for defining Terraform provider blocks and backend configuration.
- **main.tf**: Contains the primary resources and overall infrastructure components.
- **<resource_type>.tf**: For larger projects, we can group resources by their function, e.g. `networking.tf` for all the networking related resources, `storage.tf` for all the storage buckets and databases, etc.
- **variables.tf**: All input variables (`variable` blocks) are defined here.
- **outputs.tf**: Output values (`output` blocks) from your configuration are listed here.
- **data.tf**: For data sources

**Best Practices:**
- Place input variables in `variables.tf` and outputs in `outputs.tf`.
- Use separate `.tfvars` file for secrets and environment-specific values (these files should be gitignored). Eg: `dev.tfvars` , `prod.tfvars`
- Keep tfstate, credentials and sensitive data outside version control

## Passing input vars

```sh
# pass input values from flags
terraform plan -out s1.tfplan -var="project-id=cmu-26fall-recitation-5"

# pass input values from a file
terraform plan -out s1.tfplan -var-file="inputs.tfvars"
```
Here, inputs.tfvars has `key=value` pair. The value needs to match the datatype of the variable. For example:
```sh
some_string_value = "double quoted"
some_bool_value = true
some_int_val = 2
```

### HOW is tfvars different than variables.tf

**Example `variables.tf`:**
```hcl
variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "instance_count" {
  type    = number
  default = 1
}
```

**Example `prod.tfvars`:**
```hcl
project_id     = "cmu-26fall-recitation-5"
instance_count = 5
```

Think of it as: `variables.tf` defines **what** variables exist and their constraints, while `.tfvars` provides the **actual values**. This separation allows you to reuse the same Terraform configuration across different environments (dev, staging, prod) by swapping out the `.tfvars` file.

For example, we could have a `dev.tfvars` file with smaller instance_count
```hcl
project_id     = "cmu-26fall-recitation-5"
instance_count = 1
```


### Modules
Modules allow us to combine code into logical groups that can be managed together. For example, we can group several resources (e.g. a compute instance, firewall rules, a bucket) into a module and reuse that module across dev and prod, or across multiple projects.

It helps ensure reusability, encapsulation, and maintainability.

#### What is a module?
A **module** is a folder containing Terraform files (`.tf`) that define a set of resources. A module has:
- **Inputs**: `variable` blocks that the caller passes in.
- **Outputs**: `output` blocks that expose values to the caller.
- **Resources**: The actual infrastructure (e.g. instances, networks) created by the module.

#### Calling a module
Use a `module` block in your root or another module to call a module:

```hcl
module "web_instances" {
  source = "./web-server"
  # Arguments...
}
```

- `source`: Path to the module. Can be:
  - Local: `"./web-server"` (relative path), `../modules/network"`.
  - Registry: `hashicorp/consul/aws"` (Terraform Registry).
  - Git: `"git::https://github.com/org/repo.git?ref=v1.0.0"`.
- Arguments: Pass values for the module’s input variables.

After adding or changing a module’s `source`, run `terraform init` so Terraform can fetch or link the module.

#### Using module outputs
Reference outputs from a module as `module.<module_name>.<output_name>`:

```hcl
# Example: use private IPs of instances created by the module
module.webservers.webserver-ips
module.webservers.webserver-ips[*].name
```

#### Best practices
- One purpose per module: Keep each module focused (e.g. “web servers”, “networking”, “storage”).
- Expose only what’s needed: Use `output` for values other config or modules need; avoid exposing internal resources unnecessarily.
- Document variables: Use `description` in `variable` and `output` blocks.
- Pin external modules: Use a version or ref in `source` (e.g. `?ref=v1.0.0`) for registry or Git modules so changes are predictable.

### Remote backend
https://developer.hashicorp.com/terraform/language/backend#overview 

A remote backend stores Terraform state somewhere other than the a local `terraform.tfstate` file. Terraform supports GCS, S3, Terraform Cloud, kubernetes, and more places to store the files. Using a remote backend is important for several reasons:
- Collaboration: With a local backend, only one person can run Terraform at a time without risking state conflicts or overwrites. A remote backend allows locking so that one person applies while others wait, and everyone works from the same source of truth.
- State safety: Local state can be lost with disk failure, accidental deletion, or if it’s never committed. Remote backends provide durability, versioning, and backups.
- Security: State often contains secrets (passwords, keys, IPs). Keeping it in a shared, access-controlled remote store is safer than scattering `terraform.tfstate` copies on laptops or in repos.
- CI/CD: Pipelines need a consistent state to run `plan` and `apply`. A remote backend gives every run the same state without manual file copying.


Let's use GCS bucket in our case. https://developer.hashicorp.com/terraform/language/backend/gcs
We follow the following steps:
1. First, create the required storage bucket in GCP
2. Then add the backend inside the terraform block. 
3. Then run `terraform init -backend-config="bucket=remotestate_cmu-26fall-recitation-5" -backend-config="credentials=key.json"`
4. The config files will be stored in the remote backend.
