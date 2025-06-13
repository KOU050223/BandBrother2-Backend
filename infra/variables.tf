# プロジェクトの設定の宣言など

variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "asia-northeast1"
}

variable "db_instance_name" { default = "rails-db" }
variable "db_version" { default = "POSTGRES_15" }
variable "db_tier" { default = "db-f1-micro" }
variable "database_name" {}
variable "database_user" {}
variable "database_password" {}

variable "rails_server_image" {}
variable "rails_master_key" {}

variable "service_account_email" {
  description = "Cloud Run実行用サービスアカウントのメールアドレス"
}

variable "cloud_run_service_name" {
  description = "Cloud Runサービス名"
  type        = string
  default     = "rails-server"
}

variable "cloud_run_max_instances" {
  description = "Cloud Runの最大インスタンス数"
  type        = number
  default     = 3
}

variable "cloud_run_memory" {
  description = "Cloud Runのメモリ"
  type        = string
  default     = "512Mi"
}

variable "cloud_run_cpu" {
  description = "Cloud RunのCPU"
  type        = string
  default     = "1"
}
