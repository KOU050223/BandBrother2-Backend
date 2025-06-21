# Redis Memory Store インスタンス
resource "google_redis_instance" "redis" {
  name           = "bandbrother2-redis"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.region
  
  # ネットワーク設定（一旦デフォルトネットワーク使用）
  # authorized_network = google_compute_network.vpc.id
  
  # Redis設定
  redis_version = "REDIS_6_X"
  display_name  = "BandBrother2 Redis Instance"
  
  # 認証有効（セキュリティ向上）
  auth_enabled = true
  
  labels = {
    environment = "production"
    project     = "bandbrother2"
  }
  
  depends_on = [google_project_service.redis]
}

# VPCネットワーク
resource "google_compute_network" "vpc" {
  name                    = "bandbrother2-vpc"
  auto_create_subnetworks = false
  
  depends_on = [google_project_service.compute]
}

# サブネット
resource "google_compute_subnetwork" "subnet" {
  name          = "bandbrother2-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# VPC Connector は一旦コメントアウト（ネットワーク設定を簡単にするため）
# resource "google_vpc_access_connector" "connector" {
#   name          = "bandbrother2-connector"
#   ip_cidr_range = "10.1.0.0/28"
#   network       = google_compute_network.vpc.name
#   region        = var.region
#   
#   # インスタンス数を指定（小規模なアプリケーション用）
#   min_instances = 2
#   max_instances = 3
#   
#   depends_on = [google_project_service.vpcaccess]
# }

# Redis接続情報を出力
output "redis_host" {
  value = google_redis_instance.redis.host
}

output "redis_port" {
  value = google_redis_instance.redis.port
}

output "redis_url" {
  value = "redis://${google_redis_instance.redis.host}:${google_redis_instance.redis.port}/0"
}