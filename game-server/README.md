# game-serverのフォルダー

WebSocketサーバーをローカルで実行するためのプロジェクトです。

## 環境構築手順

```bash
cd game-server
go mod tidy
```

## サーバーの起動方法

### 方法1: 実行スクリプトを使用
```bash
./run.sh
```

### 方法2: 直接実行
```bash
# 環境変数を読み込み
export $(cat .env | xargs)

# サーバーを起動
go run ./cmd/server
```

### 方法3: ビルドして実行
```bash
# ビルド
go build -o bin/server ./cmd/server

# 実行
export $(cat .env | xargs)
./bin/server
```

## 設定

`.env`ファイルで以下の設定が可能です：
- `WS_PORT`: WebSocketサーバーのポート番号（デフォルト: 8080）
- `RAILS_API_URL`: Rails APIのURL（デフォルト: http://localhost:3000）
- `WEBSOCKET_SERVER_URL`: WebSocketサーバーのURL（デフォルト: ws://localhost:8080）
