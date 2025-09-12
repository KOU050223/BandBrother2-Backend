# ==================================================
# 基本設定
# ==================================================
variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "asia-northeast1"
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

# ==================================================

# データベース設定は削除（Pub/Sub使用）

# ==================================================
# Pub/Sub設定
# ==================================================
variable "matching_queue_topic" {
  description = "マッチングキュー用Pub/Subトピック名"
  type        = string
  default     = "bandbrother2-matching-queue"
}

variable "match_results_topic" {
  description = "マッチング結果通知用Pub/Subトピック名"
  type        = string
  default     = "bandbrother2-match-results"
}

variable "room_events_topic" {
  description = "ルームイベント通知用Pub/Subトピック名"
  type        = string
  default     = "bandbrother2-room-events"
}

# ==================================================
# Cloud Run設定
# ==================================================
variable "rails_server_image" {
  description = "Rails server Docker image"
  type        = string
}

variable "game_server_image" {
  description = "Go WebSocket server Docker image"
  type        = string
}

variable "rails_master_key" {
  description = "Rails master key for credentials"
  type        = string
  sensitive   = true
}

variable "service_account_email" {
  description = "Cloud Run実行用サービスアカウントのメールアドレス"
  type        = string
}

variable "cloud_run_service_name" {
  description = "Rails Cloud Runサービス名"
  type        = string
  default     = "rails-server"
}

variable "game_server_service_name" {
  description = "Game server Cloud Runサービス名"
  type        = string
  default     = "game-server"
}

variable "cloud_run_max_instances" {
  description = "Cloud Runの最大インスタンス数"
  type        = number
  default     = 3
}

variable "cloud_run_min_instances" {
  description = "Cloud Runの最小インスタンス数"
  type        = number
  default     = 0
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

variable "cloud_run_timeout" {
  description = "Cloud Runのタイムアウト（秒）"
  type        = number
  default     = 300
}

variable "container_concurrency" {
  description = "Cloud Runのコンテナ並行数"
  type        = number
  default     = 80
}
