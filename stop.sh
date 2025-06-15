#!/bin/bash

# BandBrother2 Backend 停止スクリプト
# このスクリプトは Rails サーバー（Docker）と Go WebSocket サーバー（ローカル）を停止します

echo "🛑 BandBrother2 Backend を停止中..."
echo "=================================="

# 現在のディレクトリを保存
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Go WebSocketサーバーの停止
echo "🔌 Go WebSocket サーバーを停止中..."
if pgrep -f "./bin/server" > /dev/null; then
    echo "   Go サーバープロセスを停止します..."
    pkill -f "./bin/server"
    sleep 2
    
    if pgrep -f "./bin/server" > /dev/null; then
        echo "   強制停止します..."
        pkill -9 -f "./bin/server"
    fi
    echo "   ✅ Go WebSocket サーバーを停止しました"
else
    echo "   ℹ️  Go WebSocket サーバーは実行されていません"
fi

# Dockerサービスの停止
echo ""
echo "🐳 Docker サービスを停止中..."
cd "$SCRIPT_DIR/rails-server"

if docker-compose ps | grep -q "Up"; then
    echo "   Docker Compose サービスを停止します..."
    docker-compose down
    echo "   ✅ Docker サービスを停止しました"
else
    echo "   ℹ️  Docker サービスは実行されていません"
fi

# ログファイルのクリーンアップ（オプション）
echo ""
echo "🧹 ログファイルの処理..."
if [ -f "$SCRIPT_DIR/go-server.log" ]; then
    echo "   📝 Go サーバーログ: $SCRIPT_DIR/go-server.log (保持されます)"
    # 必要に応じてログを削除する場合は以下のコメントを外してください
    # rm "$SCRIPT_DIR/go-server.log"
    # echo "   🗑️  Go サーバーログを削除しました"
fi

# 最終確認
echo ""
echo "🔍 停止状況の確認..."
echo "=================================="

echo "🔌 Go WebSocket サーバー:"
if pgrep -f "./bin/server" > /dev/null; then
    echo "   ⚠️  まだ実行中です (PID: $(pgrep -f './bin/server'))"
else
    echo "   ✅ 停止済み"
fi

echo ""
echo "📦 Docker サービス:"
if docker-compose -f "$SCRIPT_DIR/rails-server/docker-compose.yml" ps | grep -q "Up"; then
    docker-compose -f "$SCRIPT_DIR/rails-server/docker-compose.yml" ps
else
    echo "   ✅ 全て停止済み"
fi

echo ""
echo "✅ BandBrother2 Backend の停止が完了しました！"
