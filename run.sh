
#!/bin/bash

# BandBrother2 Backend 統合起動スクリプト
# このスクリプトは Rails サーバー（Docker）と Go WebSocket サーバー（ローカル）を起動します

set -e  # エラー時に停止

echo "🎵 BandBrother2 Backend を起動中..."
echo "=================================="

# 現在のディレクトリを保存
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 スクリプトディレクトリ: $SCRIPT_DIR"

# Dockerサービスの起動
echo ""
echo "🐳 Docker サービスを起動中..."
cd "$SCRIPT_DIR/rails-server"

# Docker Composeサービスの状態確認
if docker-compose ps | grep -q "Up"; then
    echo "✅ Docker サービスは既に起動しています"
    docker-compose ps
else
    echo "🚀 Docker サービスを起動します..."
    docker-compose up -d
    
    # サービスの起動を待機
    echo "⏳ サービスの起動を待機中..."
    sleep 10
    
    # データベースの接続確認
    echo "🗄️  データベース接続を確認中..."
    for i in {1..30}; do
        if docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1; then
            echo "✅ データベースが利用可能です"
            break
        fi
        echo "   データベース接続待機中... ($i/30)"
        sleep 2
    done
fi

# Railsサーバーの起動確認
echo ""
echo "🚂 Rails サーバーの起動を確認中..."
for i in {1..20}; do
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Rails サーバーが起動しました (http://localhost:3000)"
        break
    fi
    echo "   Rails サーバー起動待機中... ($i/20)"
    sleep 3
done

# Go WebSocketサーバーの起動
echo ""
echo "🔌 Go WebSocket サーバーを起動中..."
cd "$SCRIPT_DIR/game-server"

# 既存のGoサーバープロセスを確認
if pgrep -f "./bin/server" > /dev/null; then
    echo "⚠️  既存の Go サーバーが実行中です。停止してから再起動します..."
    pkill -f "./bin/server" || true
    sleep 2
fi

# Goサーバーをバックグラウンドで起動
echo "🚀 Go WebSocket サーバーを起動します..."
nohup ./run.sh > ../go-server.log 2>&1 &
GO_PID=$!

# Go サーバーの起動確認
echo "⏳ Go WebSocket サーバーの起動を確認中..."
sleep 5

for i in {1..10}; do
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        echo "✅ Go WebSocket サーバーが起動しました (ws://localhost:8080)"
        break
    fi
    echo "   Go WebSocket サーバー起動待機中... ($i/10)"
    sleep 2
done

# 起動状況の最終確認
echo ""
echo "🔍 サービス起動状況の最終確認..."
echo "=================================="

# Docker サービス状況
echo "📦 Docker サービス:"
docker-compose -f "$SCRIPT_DIR/rails-server/docker-compose.yml" ps

# Go サーバー状況
echo ""
echo "🔌 Go WebSocket サーバー:"
if pgrep -f "./bin/server" > /dev/null; then
    echo "   ✅ 実行中 (PID: $(pgrep -f './bin/server'))"
else
    echo "   ❌ 停止中"
fi

# ポート確認
echo ""
echo "🌐 ポート使用状況:"
echo "   ポート 3000 (Rails): $(nc -z localhost 3000 && echo "✅ 開放" || echo "❌ 閉鎖")"
echo "   ポート 8080 (WebSocket): $(nc -z localhost 8080 && echo "✅ 開放" || echo "❌ 閉鎖")"
echo "   ポート 5432 (PostgreSQL): $(nc -z localhost 5432 && echo "✅ 開放" || echo "❌ 閉鎖")"
echo "   ポート 6379 (Redis): $(nc -z localhost 6379 && echo "✅ 開放" || echo "❌ 閉鎖")"

echo ""
echo "🎉 BandBrother2 Backend の起動が完了しました！"
echo "=================================="
echo "📍 アクセス情報:"
echo "   🚂 Rails API: http://localhost:3000"
echo "   🔌 WebSocket: ws://localhost:8080"
echo "   🗄️  PostgreSQL: localhost:5432"
echo "   📦 Redis: localhost:6379"
echo ""
echo "📝 ログファイル:"
echo "   🔌 Go サーバーログ: $SCRIPT_DIR/go-server.log"
echo ""
echo "🛑 停止するには: $SCRIPT_DIR/stop.sh を実行してください"