#!/bin/bash

# BandBrother2 Backend 状態確認スクリプト
# システムの稼働状況を確認します

echo "🔍 BandBrother2 Backend 状態確認"
echo "=================================="

# 現在のディレクトリを保存
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# サービス状況確認
echo "📦 Docker サービス状況:"
# 現在のディレクトリでdocker-compose psを実行
if docker-compose ps 2>/dev/null | grep -q "myapp"; then
    docker-compose ps
else
    echo "   ❌ Docker サービスが起動していません"
fi

echo ""
echo "🔌 Go WebSocket サーバー状況:"
# Dockerコンテナの状態をチェック
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "myapp-game-server"; then
    CONTAINER_STATUS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "myapp-game-server" | awk '{print $2, $3}')
    echo "   ✅ コンテナ実行中 ($CONTAINER_STATUS)"
    
    # WebSocketサーバーの動作確認（HTTPアクセステスト）
    if curl -s --max-time 3 http://localhost:8080 > /dev/null 2>&1; then
        echo "   ✅ WebSocketサーバー応答中"
    else
        echo "   ⚠️  WebSocketサーバーが応答していません"
    fi
    
    # メモリ使用量を表示
    MEMORY_USAGE=$(docker stats myapp-game-server --no-stream --format "{{.MemUsage}}" 2>/dev/null || echo "取得不可")
    echo "   📊 メモリ使用量: $MEMORY_USAGE"
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

# アクセステスト
echo ""
echo "🌐 アクセステスト:"

# Rails サーバーテスト
echo -n "   Rails API (http://localhost:3000): "
if curl -s --max-time 5 http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ アクセス可能"
else
    echo "❌ アクセス不可"
fi

# Go WebSocket サーバーテスト
echo -n "   WebSocket Server (http://localhost:8080): "
if curl -s --max-time 5 http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ アクセス可能"
else
    echo "❌ アクセス不可"
fi

# データベース接続テスト
echo -n "   PostgreSQL データベース: "
if docker exec myapp-db pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ 接続可能"
else
    echo "❌ 接続不可"
fi

# Redis接続テスト
echo -n "   Redis: "
if docker exec myapp-redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ 接続可能"
else
    echo "❌ 接続不可"
fi

# ログファイル状況
echo ""
echo "📝 ログファイル状況:"
if [ -f "$SCRIPT_DIR/go-server.log" ]; then
    LOG_SIZE=$(du -h "$SCRIPT_DIR/go-server.log" | cut -f1)
    LOG_LINES=$(wc -l < "$SCRIPT_DIR/go-server.log")
    echo "   📄 Go サーバーログ: $LOG_SIZE ($LOG_LINES 行)"
    echo "      パス: $SCRIPT_DIR/go-server.log"
else
    echo "   ❌ Go サーバーログファイルが見つかりません"
fi

# システムリソース使用状況
echo ""
echo "💻 システムリソース:"
if command -v docker > /dev/null; then
    echo "   🐳 Docker コンテナ数: $(docker ps -q | wc -l)"
fi

if command -v free > /dev/null; then
    echo "   🧠 メモリ使用量: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
elif command -v vm_stat > /dev/null; then
    # macOS の場合
    VM_STAT=$(vm_stat)
    PAGES_FREE=$(echo "$VM_STAT" | grep "Pages free" | awk '{print $3}' | tr -d '.')
    PAGES_ACTIVE=$(echo "$VM_STAT" | grep "Pages active" | awk '{print $3}' | tr -d '.')
    PAGES_INACTIVE=$(echo "$VM_STAT" | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
    PAGES_USED=$((PAGES_ACTIVE + PAGES_INACTIVE))
    TOTAL_PAGES=$((PAGES_FREE + PAGES_USED))
    MEMORY_USED_GB=$((PAGES_USED * 4096 / 1024 / 1024 / 1024))
    MEMORY_TOTAL_GB=$((TOTAL_PAGES * 4096 / 1024 / 1024 / 1024))
    echo "   🧠 メモリ使用量: 約 ${MEMORY_USED_GB}GB / ${MEMORY_TOTAL_GB}GB"
fi

echo ""
echo "=================================="
echo "📍 アクセス情報:"
echo "   🚂 Rails API: http://localhost:3000"
echo "   🔌 WebSocket: ws://localhost:8080"
echo "   🗄️  PostgreSQL: localhost:5432"
echo "   📦 Redis: localhost:6379"
