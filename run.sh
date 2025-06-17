
#!/bin/bash

# BandBrother2 Backend 統合起動スクリプト
# このスクリプトは Docker Compose で全サービス（Rails、Go WebSocket、PostgreSQL、Redis）を起動します

set -e  # エラー時に停止

echo "🎵 BandBrother2 Backend を起動中..."
echo "=================================="

# 現在のディレクトリを保存
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 スクリプトディレクトリ: $SCRIPT_DIR"

# Docker Composeサービスの起動
echo ""
echo "🐳 Docker サービスを起動中..."
cd "$SCRIPT_DIR"

# Docker Composeサービスの状態確認
if docker-compose ps 2>/dev/null | grep -q "Up"; then
    echo "✅ Docker サービスは既に起動しています"
    docker-compose ps
else
    echo "🚀 Docker サービスを起動します..."
    docker-compose up -d
    
    # サービスの起動を待機
    echo "⏳ サービスの起動を待機中..."
    sleep 15
    
    # データベースとRedisの接続確認
    echo "🗄️  データベース接続を確認中..."
    for i in {1..30}; do
        if docker exec myapp-db pg_isready -U postgres > /dev/null 2>&1; then
            echo "✅ PostgreSQLが利用可能です"
            break
        fi
        echo "   PostgreSQL接続待機中... ($i/30)"
        sleep 2
    done
    
    echo "📦 Redis接続を確認中..."
    for i in {1..20}; do
        if docker exec myapp-redis redis-cli ping > /dev/null 2>&1; then
            echo "✅ Redisが利用可能です"
            break
        fi
        echo "   Redis接続待機中... ($i/20)"
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

# Go WebSocketサーバーの起動確認
echo ""
echo "🔌 Go WebSocket サーバーの起動を確認中..."
for i in {1..15}; do
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        echo "✅ Go WebSocket サーバーが起動しました (ws://localhost:8080)"
        break
    fi
    echo "   Go WebSocket サーバー起動待機中... ($i/15)"
    sleep 3
done

# 起動状況の最終確認
echo ""
echo "🔍 サービス起動状況の最終確認..."
echo "=================================="

# Docker サービス状況
echo "📦 Docker サービス:"
docker-compose ps

# Go サーバー状況 (Docker内)
echo ""
echo "🔌 Go WebSocket サーバー:"
if docker ps --format "{{.Names}}" | grep -q "myapp-game-server"; then
    CONTAINER_STATUS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "myapp-game-server" | awk '{print $2, $3}')
    echo "   ✅ コンテナ実行中 ($CONTAINER_STATUS)"
    
    if curl -s --max-time 3 http://localhost:8080 > /dev/null 2>&1; then
        echo "   ✅ WebSocketサーバー応答中"
    else
        echo "   ⚠️  WebSocketサーバーが応答していません"
    fi
else
    echo "   ❌ 停止中"
fi

# ポート確認
echo ""
echo "🌐 ポート使用状況:"
check_port() {
    local port=$1
    local service=$2
    if nc -z localhost $port 2>/dev/null; then
        echo "   ✅ ポート $port ($service): 開放"
    else
        echo "   ❌ ポート $port ($service): 閉鎖"
    fi
}

check_port 3000 "Rails"
check_port 8080 "WebSocket"
check_port 5432 "PostgreSQL"
check_port 6379 "Redis"

echo ""
echo "🎉 BandBrother2 Backend の起動が完了しました！"
echo "=================================="
echo "📍 アクセス情報:"
echo "   🚂 Rails API: http://localhost:3000"
echo "   🔌 WebSocket: ws://localhost:8080"
echo "   🗄️  PostgreSQL: localhost:5432"
echo "   📦 Redis: localhost:6379"
echo ""
echo "📝 ログ確認:"
echo "   📦 Docker ログ: docker-compose logs [service]"
echo "   🔌 Go サーバーログ: docker logs myapp-game-server"
echo ""
echo "🛑 停止するには: $SCRIPT_DIR/stop.sh を実行してください"
echo "🔍 状態確認: $SCRIPT_DIR/status.sh を実行してください"