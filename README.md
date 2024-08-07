# Introduction
This pattern is designed to be easy to deploy and maintain, and it is a great starting point for anyone who wants to use Directus in a Google Cloud environment.

The repository includes:
- A Terraform library that defines all the resources required for the pattern 
- Instructions for how to use the pattern, as well as additional extra features to expand the pattern further.

This pattern is designed to be a starting point for building your own Directus Cloud Run applications.

Feel free to customize it to meet your specific needs.

## Architecture
<p align="center"> <img src="images/architecture.png" width="700"> </p>

## Reference
Content is pulled from the directus page here: [Manual deploy directus to GCP](https://docs.directus.io/blog/deploying-directus-to-google-cloud-platform-with-docker.html)

## Prerequisite Software
1. Install Google Cloud SDK [Installation Instructions](https://cloud.google.com/sdk/docs/install#installation_instructions)
2. Install Terraform [Installation Instructions](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform)

## Prerequisite Minimum Permissions
1. Ensure your user has `roles/billing.user` on the provided Billing Account ID
2. Ensure your user has `roles/resourcemanager.projectCreator` on the Organisation
3. Ensure your user has `roles/resourcemanager.organizationViewer` to view the Organisation

## Prerequisite Steps
1. Authenticate to Google Cloud Platform `gcloud auth login`
2. Authenticate to Google Cloud Platform using Application Credentials `gcloud auth application-default login`
3. Set the Default Project to an existing Google Cloud Platform Project `gcloud config set project <PROJECT_ID>`
4. Set the Default Quota Project to an existing Google Cloud Platform Project `gcloud auth application-default set-quota-project <PROJECT_ID>`

## Pre-Terraform Steps 
1. Navigate to the `terraform` directory and run `terraform init`
2. Create a `terraform.auto.tfvars` file in the same `terraform` directory
**The file should look like:**
```
oauth2_client_id     = ""
oauth2_client_secret = ""
org_id               = "<YOUR ORG ID>" # THESE MUST BE FILLED OUT
billing_account_id   = "<YOUR BILLING ACCOUNT ID>" # THESE MUST BE FILLED OUT
```
3. Upon succesful init you should see `Terraform has been successfully initialized!` 
4. Now run a targetted plan `terraform plan --target module.project_factory`, we need to build the project before we can continue!
4. Upon a successful plan you should see `Plan: 17 to add, 0 to change, 0 to destroy.`
5. Now run a targetted apply `terraform apply --target module.project_factory`, this will build the project add `--auto-approve` if you want to ignore the secondary check, this process can take upwards of 15 minutes to complete
**We need to setup the `remote state bucket` and the `NEW_backend.tf` to use the bucket**
5. Upon successful project creation, you should see `Apply complete! Resources: 17 added, 0 changed, 0 destroyed.`
6. Now run a targetted plan for the new state bucket and backend `terraform plan --target google_storage_bucket.terraform_state_bucket --target null_resource.org`
7. Upon successful bucket plan, you should see `Plan: 2 to add, 0 to change, 0 to destroy.`
8. Now run a targetted apply for the new state bucket and backend `terraform apply --target google_storage_bucket.terraform_state_bucket --target null_resource.org`
8. Upon successful bucket apply, you should see `Apply complete! Resources: 2 added, 0 changed, 0 destroyed.`
9. Now run `rm backend.tf && mv NEW_backend.tf backend.tf`
10. Now we need to migrate the local state to the remote state, run `terraform init -migrate-state` and type `yes` to migrate the local state to the remote backend 
11. Now run `rm terraform.tf*` to remove the local state from the folder

## Final Pre-Terraform Plan Steps:
1. Now that the project and state are deployed, we need to setup the OAuth2 Sign-In Page and Credential. Follow these instructions: [Basic Steps](https://developers.google.com/identity/protocols/oauth2#basicsteps)
2. Now that you have a OAuth2 Credential and Secret, update your `terraform.auto.tfvars` file:
```
oauth2_client_id     = ""
oauth2_client_secret = "<SECRET STRING>"
org_id               = "<YOUR ORG ID>" # THESE MUST BE FILLED OUT
billing_account_id   = "<YOUR BILLING ACCOUNT ID>" # THESE MUST BE FILLED OUT
```
3. Ensure you add a Redirect URL to your OAuth2.0 Client Authentication as follows:
`https://iap.googleapis.com/v1/oauth/clientIds/<YOUR CLIENT ID>:handleRedirect`
4. Now you can simply run `terraform plan` and `terraform apply` from here to deploy the remaining resources

## Post-Terraform Steps
1. Create A or AAAA Records on the provided domains to the LB IP Addresses
2. Navigate to `https://console.cloud.google.com/security/iap?project=<YOUR PROJECT ID>`
3. Click the ellipsis on for the line that has the IAP Toggle enabled and is called: `gcp-directus-admin-portal-backend-default` and click settings
4. Scroll down to `Allowed Domains` and enter your `admin` domain for this page.

## Whats Next?
1. You can now migrate data to your MySQL database using the Cloud SQL Proxy.
2. Install `cloud-sql-proxy` by following the steps for your system: [Installation Steps](https://github.com/GoogleCloudPlatform/cloud-sql-proxy#installation)
3. Ensure you are still authenticated to Google Cloud using `gcloud projects list` if data is returned, your good to continue.
4. Now, following the instructions, mount your GCP MySQL instance locally via the Proxy.
5. You can now login to the MySQL Database Locally to migrate data. If you need the credentials, ensure to grab them out of the secrets stored in 'Secrets Manager'

## Handy Hints
If you need to rename the container, redeploy the container or simply want to remove it, you will need to manually decouple the serverless NEG from the backends. You can do this by going to: [Backends](https://console.cloud.google.com/net-services/loadbalancing/list/backends) then for each of your listed backends that use the NEG, click edit, delete the backend and click save.

You can now delete the cloud run container / update it, as well as delete / update the Serverless NEG.

I don't know why I can't get terraform to handle this transition for me, but I couldn't

Also, in this Terraform I have deployed both an IAP Accessible Load Balancer and a Publically accessible Load Balancer. This is for instructional purposes so that the power of IAP can be shown in combination with a public site.

## Cleaning Up
1. You can simply destroy your created project to clean-up this repositories deployed resources: `gcloud projects delete example-foo-bar-1`
2. You can also delete your infrastructure using terraform: `terraform destroy`

## Pricing
Without going SUPER deep on the pricing calculator this respository deploys resources that cost ~$2 AUD / Day, however as it deploys **PUBLIC** facings infrastructure your costs **WILL** scale with usage of the containers and the associated storage bucket. `This is your warning!`

# Important Note 
This repository demonstrates an end-to-end deployment pattern for hosting a Docker image using Cloud Run and Identity-Aware Proxy (IAP). However, this is just one approach, and you should always conduct your own research and ensure that the tools and technologies used here meet your specific needs before implementing them in your own projects.
