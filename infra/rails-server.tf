resource "google_artifact_registry_repository" "rails_repo" {
  location      = var.region
  repository_id = "rails-server"
  format        = "DOCKER"
  description   = "Rails server container images"
  
  depends_on = [google_project_service.artifactregistry]
}

resource "google_cloud_run_service" "rails_server" {
    name     = "rails-server"
    location = var.region
    
    depends_on = [google_project_service.cloudrun]

    template {
        spec {
            containers {
                image = var.rails_server_image # 例: "gcr.io/${var.project_id}/rails-app:latest"
                ports {
                    container_port = 8080
                }
                
                resources {
                    limits = {
                        cpu    = var.cloud_run_cpu
                        memory = var.cloud_run_memory
                    }
                }
                # Rails アプリケーション設定
                env {
                    name  = "RAILS_ENV"
                    value = "production"
                }
                env {
                    name  = "RAILS_MASTER_KEY"
                    value = var.rails_master_key
                }
                env {
                    name  = "RAILS_LOG_LEVEL"
                    value = "info"
                }
                env {
                    name  = "RAILS_MAX_THREADS"
                    value = "5"
                }
# PORT環境変数はCloud Runで自動設定されるため削除
                
                # Pub/Sub設定
                env {
                    name  = "GOOGLE_CLOUD_PROJECT"
                    value = var.project_id
                }
                env {
                    name  = "MATCHING_QUEUE_TOPIC"
                    value = google_pubsub_topic.matching_queue.name
                }
                env {
                    name  = "MATCH_RESULTS_TOPIC"
                    value = google_pubsub_topic.match_results.name
                }
                env {
                    name  = "ROOM_EVENTS_TOPIC"
                    value = google_pubsub_topic.room_events.name
                }
                
                # ジョブ処理設定
                env {
                    name  = "JOB_CONCURRENCY"
                    value = "1"
                }
            }
            
            container_concurrency = var.container_concurrency
            timeout_seconds      = var.cloud_run_timeout
        }
        
        metadata {
            annotations = {
                "autoscaling.knative.dev/maxScale" = var.cloud_run_max_instances
                "autoscaling.knative.dev/minScale" = tostring(var.cloud_run_min_instances)
                # Cloud SQL設定は削除
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

resource "google_cloud_run_service_iam_member" "public_invoker" {
    service  = google_cloud_run_service.rails_server.name
    location = google_cloud_run_service.rails_server.location
    role     = "roles/run.invoker"
    member   = "allUsers"
}

output "cloud_run_url" {
    value = google_cloud_run_service.rails_server.status[0].url
}