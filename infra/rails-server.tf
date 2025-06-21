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
                
                # データベース設定
                env {
                    name  = "DATABASE_HOST"
                    value = var.database_host
                }
                env {
                    name  = "DATABASE_NAME"
                    value = var.database_name
                }
                env {
                    name  = "DATABASE_USERNAME"
                    value = var.database_username
                }
                env {
                    name  = "DATABASE_PASSWORD"
                    value = var.database_password
                }
                
                # Redis設定
                env {
                    name  = "REDIS_URL"
                    value = "redis://${google_redis_instance.redis.host}:${google_redis_instance.redis.port}/0"
                }
                
                # ジョブ処理設定
                env {
                    name  = "JOB_CONCURRENCY"
                    value = "1"
                }
            }
            
            container_concurrency = 80
            timeout_seconds      = 300
        }
        
        metadata {
            annotations = {
                "autoscaling.knative.dev/maxScale" = var.cloud_run_max_instances
                "autoscaling.knative.dev/minScale" = "0"
                "run.googleapis.com/cloudsql-instances" = var.database_host
                "run.googleapis.com/execution-environment" = "gen2"
                # VPC Connectorは一旦コメントアウト（Redisへの接続は後で設定）
                # "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
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