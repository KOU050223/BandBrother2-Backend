# 必要なGoogle Cloud APIを有効化
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
  
  disable_dependent_services = true
}

resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
  
  disable_dependent_services = true
}

resource "google_project_service" "redis" {
  project = var.project_id
  service = "redis.googleapis.com"
  
  disable_dependent_services = true
}

resource "google_project_service" "sqladmin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
  
  disable_dependent_services = true
}

resource "google_project_service" "vpcaccess" {
  project = var.project_id
  service = "vpcaccess.googleapis.com"
  
  disable_dependent_services = true
}

resource "google_project_service" "cloudrun" {
  project = var.project_id
  service = "run.googleapis.com"
  
  disable_dependent_services = true
}

resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
  
  disable_dependent_services = true
}