# Collects the default networking robot account
resource "google_project_service" "servicenetworking" {
  provider                   = google-beta.australia-southeast1
  project                    = module.project_factory.project_id
  service                    = "servicenetworking.googleapis.com"
  disable_dependent_services = false
}

# Creates the required VPC
resource "google_compute_network" "vpc_network" {
  provider                = google-beta.australia-southeast1
  project                 = module.project_factory.project_id
  name                    = "vpc-network"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.servicenetworking]
}

# Sets up the first VPC
resource "google_compute_subnetwork" "vpc_subnet" {
  provider      = google-beta.australia-southeast1
  name          = "vpc-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc_network.self_link
  region        = var.deployment_location
  depends_on    = [google_compute_network.vpc_network]
}

# Sets up the second VPC
resource "google_compute_subnetwork" "vpc_subnet2" {
  provider      = google-beta.australia-southeast1
  name          = "vpc-subnet2"
  ip_cidr_range = "10.99.99.0/28"
  network       = google_compute_network.vpc_network.self_link
  region        = var.deployment_location
  depends_on    = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "iap_sql_proxy" {
  project     = module.project_factory.project_id
  name        = "iap-sql-proxy"
  network     = google_compute_network.vpc_network.name
  description = "Creates firewall rule to allow IAP Google IP Addresses to route to devices on this VPC"
  direction   = "INGRESS"
  disabled    = false
  allow {
    protocol = "tcp"
    ports    = ["22", "3306"]
  }
  source_ranges = ["35.235.240.0/20"]
}

# Build Private IP 
resource "google_compute_global_address" "private_ip_address" {
  provider      = google-beta.australia-southeast1
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
  depends_on    = [google_compute_network.vpc_network]
}

# Private VPC Connection required for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta.australia-southeast1
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on              = [google_compute_network.vpc_network]
}

# Creates serverless VPC Connector
resource "google_vpc_access_connector" "serverless_vpc_connector" {
  provider = google-beta.australia-southeast1
  name     = "svpc-connector"
  subnet {
    name = google_compute_subnetwork.vpc_subnet2.name
  }
  region         = var.deployment_location
  min_instances  = 2
  max_instances  = 10
  max_throughput = 1000
  depends_on     = [google_compute_subnetwork.vpc_subnet2]
}

# Creates Serverless Network endpoint group for use with container fronted LBs
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  provider              = google-beta.australia-southeast1
  region                = var.deployment_location
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.cloud_run_service.name
  }
  depends_on = [google_cloud_run_v2_service.cloud_run_service]
}
