# Private Service Connect を有効にする
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  
  depends_on = [google_project_service.servicenetworking]
}

resource "google_sql_database_instance" "main" {
  name             = "rails-db"
  database_version = "POSTGRES_15"
  region           = var.region
  
  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.sqladmin
  ]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = true
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
    }
    
    backup_configuration {
      enabled = true
    }
    
    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }
  
  deletion_protection = false
}

resource "google_sql_user" "user" {
  name        = var.database_username
  instance    = google_sql_database_instance.main.name
  password_wo = var.database_password
  
  depends_on = [google_sql_database_instance.main]
}

resource "google_sql_database" "db" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
  
  depends_on = [google_sql_database_instance.main]
}

# Cloud SQL接続名を出力
output "cloudsql_connection_name" {
  value = google_sql_database_instance.main.connection_name
}
