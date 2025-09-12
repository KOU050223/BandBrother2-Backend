# Pub/Subトピックとサブスクリプション設定
# マッチングシステム用

# マッチング待機キュー用トピック
resource "google_pubsub_topic" "matching_queue" {
  name = "bandbrother2-matching-queue"
  
  labels = {
    environment = var.environment
    project     = "bandbrother2"
  }
  
  depends_on = [google_project_service.pubsub]
}

# マッチング結果通知用トピック
resource "google_pubsub_topic" "match_results" {
  name = "bandbrother2-match-results"
  
  labels = {
    environment = var.environment
    project     = "bandbrother2"
  }
  
  depends_on = [google_project_service.pubsub]
}

# ゲームルーム作成通知用トピック
resource "google_pubsub_topic" "room_events" {
  name = "bandbrother2-room-events"
  
  labels = {
    environment = var.environment
    project     = "bandbrother2"
  }
  
  depends_on = [google_project_service.pubsub]
}

# Rails サーバー用サブスクリプション（マッチング処理）
resource "google_pubsub_subscription" "rails_matching" {
  name  = "rails-matching-subscription"
  topic = google_pubsub_topic.matching_queue.name
  
  # メッセージ配信設定
  ack_deadline_seconds = 60
  retain_acked_messages = false
  message_retention_duration = "86400s"  # 24時間
  
  # プッシュ設定（Cloud Runへ直接配信）
  push_config {
    push_endpoint = "${google_cloud_run_service.rails_server.status[0].url}/api/matchmaking/webhook"
    
    attributes = {
      x-goog-version = "v1"
    }
    
    # OIDC認証を使用してCloud Runへの認証を行う
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
  
  # デッドレター設定
  dead_letter_policy {
    dead_letter_topic = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }
  
  depends_on = [google_cloud_run_service.rails_server]
}

# Game サーバー用サブスクリプション（ルーム管理）
resource "google_pubsub_subscription" "game_room_events" {
  name  = "game-room-events-subscription"
  topic = google_pubsub_topic.room_events.name
  
  ack_deadline_seconds = 30
  retain_acked_messages = false
  message_retention_duration = "86400s"
  
  # プッシュ設定
  push_config {
    push_endpoint = "${google_cloud_run_service.game_server.status[0].url}/webhook/room-events"
    
    attributes = {
      x-goog-version = "v1"
    }
    
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
  
  dead_letter_policy {
    dead_letter_topic = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 3
  }
  
  depends_on = [google_cloud_run_service.game_server]
}

# マッチング結果通知用サブスクリプション（フロントエンド向け）
resource "google_pubsub_subscription" "match_results_subscription" {
  name  = "match-results-subscription"
  topic = google_pubsub_topic.match_results.name
  
  ack_deadline_seconds = 30
  retain_acked_messages = false
  message_retention_duration = "3600s"  # 1時間（短時間で処理）
  
  # プル型サブスクリプション（ポーリングベース）
  # WebSocketサーバーがポーリングしてクライアントに通知
  
  depends_on = [google_project_service.pubsub]
}

# デッドレタートピック
resource "google_pubsub_topic" "dead_letter" {
  name = "bandbrother2-dead-letter"
  
  labels = {
    environment = var.environment
    project     = "bandbrother2"
  }
  
  depends_on = [google_project_service.pubsub]
}

# デッドレター用サブスクリプション
resource "google_pubsub_subscription" "dead_letter_subscription" {
  name  = "dead-letter-subscription"
  topic = google_pubsub_topic.dead_letter.name
  
  ack_deadline_seconds = 600
  retain_acked_messages = true
  message_retention_duration = "604800s"  # 7日間保持
  
  depends_on = [google_project_service.pubsub]
}

# 出力値
output "matching_queue_topic" {
  value = google_pubsub_topic.matching_queue.name
  description = "マッチングキュー用トピック名"
}

output "match_results_topic" {
  value = google_pubsub_topic.match_results.name
  description = "マッチング結果通知用トピック名"
}

output "room_events_topic" {
  value = google_pubsub_topic.room_events.name
  description = "ルームイベント通知用トピック名"
}

output "match_results_subscription" {
  value = google_pubsub_subscription.match_results_subscription.name
  description = "マッチング結果サブスクリプション名"
}