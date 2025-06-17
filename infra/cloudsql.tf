resource "google_sql_database_instance" "main" {
  name             = "rails-db"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = true
    }
  }
}

resource "google_sql_user" "user" {
  name     = var.database_user
  instance = google_sql_database_instance.main.name
  password_wo = var.database_password
  
  depends_on = [google_sql_database_instance.main]
}

resource "google_sql_database" "db" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
  
  depends_on = [google_sql_database_instance.main]
}
