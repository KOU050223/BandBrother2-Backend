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
up: ## 全サービスを起動（Docker Compose + Go WebSocket）
	@echo "🚀 BandBrother2 Backend を起動中..."
	@./run.sh

down: ## 全サービスを停止
	@echo "🛑 BandBrother2 Backend を停止中..."
	@./stop.sh

restart: ## 全サービスを再起動
	@echo "🔄 BandBrother2 Backend を再起動中..."
	@make down
	@sleep 3
	@make up

status: ## サービス状況を確認
	@echo "📊 BandBrother2 Backend 状況確認..."
	@./status.sh

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

logs-db: ## PostgreSQLのログを表示
	@echo "🗄️  PostgreSQLログを表示中..."
	@docker-compose logs -f db

logs-redis: ## Redisのログを表示
	@echo "📦 Redisログを表示中..."
	@docker-compose logs -f redis

# Database Management
db-migrate: ## データベースマイグレーション実行
	@echo "📊 データベースマイグレーション実行中..."
	@docker-compose exec web bundle exec rails db:migrate

db-seed: ## データベースシードデータ投入
	@echo "🌱 シードデータ投入中..."
	@docker-compose exec web bundle exec rails db:seed

db-reset: ## データベースリセット（危険！）
	@echo "⚠️  データベースをリセットします..."
	@docker-compose exec web bundle exec rails db:drop db:create db:migrate db:seed

db-console: ## PostgreSQLコンソールに接続
	@echo "🗄️  PostgreSQLコンソールに接続中..."
	@docker-compose exec db psql -U postgres -d myapp_development

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
	@echo "🗄️  PostgreSQL:"
	@docker exec myapp-db pg_isready -U postgres && echo "  ✅ 接続OK" || echo "  ❌ 接続失敗"
	@echo "📦 Redis:"
	@docker exec myapp-redis redis-cli ping && echo "  ✅ 接続OK" || echo "  ❌ 接続失敗"

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

deploy-full: ## フルデプロイ（ビルド + インフラ）
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
