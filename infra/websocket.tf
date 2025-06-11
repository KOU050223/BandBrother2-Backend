resource "google_artifact_registry_repository" "websocket_repo" {
  location      = var.region
  repository_id = "go-websocket"
  format        = "DOCKER"
  description   = "Go websocket server docker repo"
}

resource "google_cloud_run_service" "websocket_server" {
  name     = "game-server"
  location = var.region

  template {
    spec {
      containers {
        image = "asia-northeast1-docker.pkg.dev/${var.project_id}/go-websocket/game-server:latest"
        ports {
          container_port = 8080
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  service    = google_cloud_run_service.websocket_server.name
  location   = google_cloud_run_service.websocket_server.location
  role       = "roles/run.invoker"
  member     = "allUsers"
}
