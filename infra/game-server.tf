resource "google_artifact_registry_repository" "go_websocket_repo" {
  location      = var.region
  repository_id = "go-websocket"
  format        = "DOCKER"
  description   = "Go WebSocket server container images"
  
  depends_on = [google_project_service.artifactregistry]
}

resource "google_cloud_run_service" "game_server" {
    name     = var.game_server_service_name
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
                    name  = "GOOGLE_CLOUD_PROJECT"
                    value = var.project_id
                }
                env {
                    name  = "MATCH_RESULTS_SUBSCRIPTION"
                    value = google_pubsub_subscription.match_results_subscription.name
                }
                env {
                    name  = "ROOM_EVENTS_TOPIC"
                    value = google_pubsub_topic.room_events.name
                }
            }
            
            container_concurrency = var.container_concurrency
            timeout_seconds      = var.cloud_run_timeout
        }
        
        metadata {
            annotations = {
                "autoscaling.knative.dev/maxScale" = var.cloud_run_max_instances
                "autoscaling.knative.dev/minScale" = tostring(var.cloud_run_min_instances)
                "run.googleapis.com/execution-environment" = "gen2"
                # VPC Connectorは使用しない（簡略化）
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
