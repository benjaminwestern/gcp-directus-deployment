terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.36.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.36.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.2"
    }
  }
}
