resource "google_cloud_run_service" "rails_server" {
    name     = "rails-server"
    location = var.region

    template {
        spec {
            containers {
                image = var.rails_server_image # 例: "gcr.io/${var.project_id}/rails-app:latest"
                ports {
                    container_port = 8080
                }
                env {
                    name  = "RAILS_ENV"
                    value = "production"
                }
                env {
                    name  = "RAILS_MASTER_KEY"
                    value = var.rails_master_key
                }
                # 必要に応じて他の環境変数も追加
            }
        }
    }

    traffic {
        percent         = 100
        latest_revision = true
    }
}

resource "google_cloud_run_service_iam_member" "public_invoker" {
    service  = google_cloud_run_service.rails_server.name
    location = google_cloud_run_service.rails_server.location
    role     = "roles/run.invoker"
    member   = "allUsers"
}

output "cloud_run_url" {
    value = google_cloud_run_service.rails_server.status[0].url
}