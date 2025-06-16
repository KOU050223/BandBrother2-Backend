# バンドブラザー2 バックエンドリポジトリ

バンドブラザー2のバックエンドリポジトリです

[Figjam](https://www.figma.com/board/miStDbGbn50Ogp68O5o9V3/%E3%82%AE%E3%82%AC%E3%81%AE%E3%81%A8?node-id=0-1&t=Aot7F3M2pF4HE1Z4-1)

## 🚀 クイックスタート

### 前提条件
- Docker & Docker Compose
- Go 1.23+
- macOS/Linux環境

### 一括起動
```bash
# 全てのサービスを起動
./run.sh
```

### 一括停止
```bash
# 全てのサービスを停止
./stop.sh
```

### 状態確認
```bash
# サービスの状態を確認
./status.sh
```

## 📦 アーキテクチャ

### サービス構成
- **Rails API サーバー** (Docker) - ポート 3000
- **Go WebSocket サーバー** (ローカル) - ポート 8080
- **PostgreSQL** (Docker) - ポート 5432
- **Redis** (Docker) - ポート 6379

### ディレクトリ構造
```
BandBrother2-Backend/
├── run.sh              # 全サービス起動スクリプト
├── stop.sh             # 全サービス停止スクリプト
├── status.sh           # 状態確認スクリプト
├── rails-server/       # Rails APIサーバー
│   ├── docker-compose.yml
│   └── ...
├── game-server/        # Go WebSocketサーバー
│   ├── run.sh
│   └── ...
└── infra/              # インフラ設定（Terraform）
```

## 🔧 手動操作

### Rails サーバー（Docker）
```bash
cd rails-server
docker-compose up -d     # 起動
docker-compose down      # 停止
docker-compose logs web  # ログ確認
```

### Go WebSocket サーバー（ローカル）
```bash
cd game-server
./run.sh                 # 起動
```

### データベース操作
```bash
cd rails-server
# マイグレーション実行
docker-compose exec web bundle exec rails db:migrate

# Rails コンソール
docker-compose exec web bundle exec rails console

# データベース直接接続
docker-compose exec db psql -U postgres -d myapp_development

# ライブラリインストール
docker-compose exec --user root web bundle install
```

## 🌐 アクセス情報

| サービス | URL | 説明 |
|---------|-----|------|
| Rails API | http://localhost:3000 | REST API エンドポイント |
| WebSocket | ws://localhost:8080 | リアルタイム通信 |
| PostgreSQL | localhost:5432 | データベース |
| Redis | localhost:6379 | キャッシュ・セッション |

## 📝 ログ

- **Rails**: `docker-compose logs web`
- **Go WebSocket**: `go-server.log`
- **PostgreSQL**: `docker-compose logs db`
- **Redis**: `docker-compose logs redis`

## 🛠️ 開発

### 依存関係の更新
```bash
# Rails
cd rails-server
docker-compose exec web bundle install

# Go
cd game-server
go mod tidy
```

### テスト実行
```bash
# Rails テスト
cd rails-server
docker-compose exec web bundle exec rails test

# Go テスト
cd game-server
go test ./...
```
