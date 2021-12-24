terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.53"
    }
  }
}

# GCP project
variable "project" {
  type        = string
  description = "Google Cloud Platform Project ID"
}

provider "google" {
  project = var.project
}



# Enable services
resource "google_project_service" "run" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

# The Cloud Run service
resource "google_cloud_run_service" "demo" {
  name                       = "demo"
  location                   = "us-central1"
  autogenerate_revision_name = true

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}/docker"
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.run]
}

# Set service public
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.demo.location
  project  = google_cloud_run_service.demo.project
  service  = google_cloud_run_service.demo.name

  policy_data = data.google_iam_policy.noauth.policy_data
  depends_on  = [google_cloud_run_service.demo]
}

# Return service URL
output "service_url" {
  value = google_cloud_run_service.demo.status[0].url
}