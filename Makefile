# BandBrother2 Backend Makefile
# 統合開発環境の管理用Makefile

.PHONY: help up down restart status clean logs test build deploy health lint format

# デフォルトターゲット
help: ## ヘルプを表示
	@echo "🎵 BandBrother2 Backend 開発環境管理 Makefile"
	@echo "==============================================="
	@echo "利用可能なコマンド:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

# Docker Compose Services Management
up: ## 全サービスを起動（開発環境）
	@echo "🚀 BandBrother2 Backend を起動中..."
	@docker-compose up -d
	@echo "⏳ サービスの起動を待機中..."
	@sleep 5
	@echo "🎉 BandBrother2 Backend の起動が完了しました！"
	@echo "📍 アクセス情報:"
	@echo "   🚂 Rails API: http://localhost:3000"
	@echo "   🔌 WebSocket: ws://localhost:8080"
	@echo "   📝 Pub/Sub: Mock Mode (外部依存なし)"

dev: up ## 開発環境を起動（upのエイリアス）

down: ## 全サービスを停止
	@echo "🛑 BandBrother2 Backend を停止中..."
	@docker-compose down
	@echo "✅ BandBrother2 Backend の停止が完了しました！"

restart: ## 全サービスを再起動
	@echo "🔄 BandBrother2 Backend を再起動中..."
	@make down
	@sleep 3
	@make up

status: ## サービス状況を確認
	@echo "🔍 BandBrother2 Backend 状況確認..."
	@echo "======================================"
	@echo "📦 Docker サービス状況:"
	@docker-compose ps 2>/dev/null || echo "   ❌ Docker サービスが起動していません"
	@$(MAKE) health

# Docker Compose Shortcuts
build: ## Dockerイメージをビルド
	@echo "🏗️  Dockerイメージをビルド中..."
	@docker-compose build

pull: ## Dockerイメージを更新
	@echo "📥 Dockerイメージを更新中..."
	@docker-compose pull

# Logs
logs: ## 全サービスのログを表示
	@echo "📝 全サービスログを表示中..."
	@docker-compose logs -f

logs-rails: ## Railsサーバーのログを表示
	@echo "🚂 Railsサーバーログを表示中..."
	@docker-compose logs -f web

logs-go: ## Go WebSocketサーバーのログを表示
	@echo "🔌 Go WebSocketサーバーログを表示中..."
	@docker logs -f myapp-game-server

# Pub/Subは開発環境でMockを使用

# Pub/Sub Management
# 開発環境ではPub/Sub Mockを使用するため、追加設定不要

test-matching: ## マッチング機能のテスト
	@echo "🎮 マッチング機能をテスト中..."
	@echo "開発環境ではMockを使用してマッチング処理をテストします"
	@curl -X POST http://localhost:3000/api/matchmaking \
		-H "Content-Type: application/json" \
		-d '{"userId":"test123","difficulty":"easy"}' || echo "Rails APIが起動していません"

# Rails Management
rails-console: ## Railsコンソールを起動
	@echo "🚂 Railsコンソールを起動中..."
	@docker-compose exec web bundle exec rails console

rails-shell: ## Railsコンテナのbashシェルに接続
	@echo "🐚 Railsコンテナシェルに接続中..."
	@docker-compose exec web bash

# Testing
test: ## 全テストを実行
	@echo "🧪 全テストを実行中..."
	@make test-rails
	@make test-go

test-rails: ## Railsテストを実行
	@echo "🚂 Railsテストを実行中..."
	@docker-compose exec web bundle exec rails test

test-go: ## Go WebSocketサーバーテストを実行
	@echo "🔌 Goテストを実行中..."
	@cd game-server && go test ./...

# Health Checks
health: ## 全サービスのヘルスチェック
	@echo "🏥 ヘルスチェックを実行中..."
	@echo "🚂 Rails API (http://localhost:3000):"
	@curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:3000 || echo "  ❌ 接続失敗"
	@echo "🔌 Go WebSocket (http://localhost:8080):"
	@curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:8080 || echo "  ❌ 接続失敗"
	@echo "📝 Pub/Sub: Mock Mode (外部依存なし)"

# Clean up
clean: ## 全コンテナ・ボリューム・ネットワークを削除（危険！）
	@echo "🧹 Docker環境をクリーンアップ中..."
	@docker-compose down -v --remove-orphans
	@docker system prune -f

clean-volumes: ## Dockerボリュームを削除（危険！）
	@echo "🗑️  Dockerボリュームを削除中..."
	@docker-compose down -v

# Development Tools
format-rails: ## Railsコードをフォーマット
	@echo "✨ Railsコードフォーマット中..."
	@docker-compose exec web bundle exec rubocop -A || true

format-go: ## Goコードをフォーマット
	@echo "✨ Goコードフォーマット中..."
	@cd game-server && go fmt ./...

lint-rails: ## Railsコードリント
	@echo "🔍 Railsコードリント中..."
	@docker-compose exec web bundle exec rubocop

lint-go: ## Goコードリント
	@echo "🔍 Goコードリント中..."
	@cd game-server && go vet ./...

# Production Deployment
deploy-build-rails: ## Rails本番用Dockerイメージをビルド・プッシュ
	@echo "🏗️  Rails本番イメージビルド中..."
	@cd rails-server && DOCKER_BUILDKIT=1 docker buildx build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/bandbrother2/rails-server/rails-server:latest --push .

deploy-build-go: ## Go本番用Dockerイメージをビルド・プッシュ
	@echo "🏗️  Go本番イメージビルド中..."
	@cd game-server && docker buildx build --platform linux/amd64 -t asia-northeast1-docker.pkg.dev/bandbrother2/go-websocket/game-server:latest --push .

deploy-infra: ## Terraformで本番インフラをデプロイ
	@echo "🌍 本番インフラをデプロイ中..."
	@cd infra && terraform apply -auto-approve

deploy: ## フルデプロイ（ビルド + インフラ）
	@echo "🚀 フルデプロイを実行中..."
	@make deploy-build-rails
	@make deploy-build-go
	@make deploy-infra

# Quick Commands
dev: up ## 開発環境を起動（upのエイリアス）
stop: down ## 開発環境を停止（downのエイリアス）
check: status ## 状況確認（statusのエイリアス）

# Docker Authentication (for deployment)
auth-docker: ## Google Cloud Dockerレジストリに認証
	@echo "🔐 Docker認証中..."
	@gcloud auth configure-docker asia-northeast1-docker.pkg.dev
