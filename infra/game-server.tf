resource "google_artifact_registry_repository" "go_websocket_repo" {
  location      = var.region
  repository_id = "go-websocket"
  format        = "DOCKER"
  description   = "Go WebSocket server container images"
  
  depends_on = [google_project_service.artifactregistry]
}

resource "google_cloud_run_service" "game_server" {
    name     = "game-server"
    location = var.region
    
    depends_on = [google_project_service.cloudrun]

    template {
        spec {
            containers {
                image = var.game_server_image # 例: "asia-northeast1-docker.pkg.dev/bandbrother2/go-websocket/game-server:latest"
                ports {
                    container_port = 8080
                }
                
                resources {
                    limits = {
                        cpu    = var.cloud_run_cpu
                        memory = var.cloud_run_memory
                    }
                }
                
                # Go WebSocket サーバー設定
                env {
                    name  = "RAILS_API_URL"
                    value = google_cloud_run_service.rails_server.status[0].url
                }
                env {
                    name  = "REDIS_HOST"
                    value = google_redis_instance.redis.host
                }
                env {
                    name  = "REDIS_PORT"
                    value = tostring(google_redis_instance.redis.port)
                }
                env {
                    name  = "REDIS_URL"
                    value = "redis://${google_redis_instance.redis.host}:${google_redis_instance.redis.port}/0"
                }
            }
            
            container_concurrency = 80
            timeout_seconds      = 300
        }
        
        metadata {
            annotations = {
                "autoscaling.knative.dev/maxScale" = var.cloud_run_max_instances
                "autoscaling.knative.dev/minScale" = "0"
                "run.googleapis.com/execution-environment" = "gen2"
            }
        }
    }

    traffic {
        percent         = 100
        latest_revision = true
    }
}

resource "google_cloud_run_service_iam_member" "game_server_public_invoker" {
    service  = google_cloud_run_service.game_server.name
    location = google_cloud_run_service.game_server.location
    role     = "roles/run.invoker"
    member   = "allUsers"
}

output "game_server_url" {
    value = try(google_cloud_run_service.game_server.status[0].url, "")
}
