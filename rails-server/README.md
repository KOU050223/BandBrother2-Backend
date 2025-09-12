# BandBrother2 Rails API Server（最小限・マッチメイキング特化）

## 概要

BandBrother2 の **マッチメイキング専用** API サーバーです。Firebase ファーストアーキテクチャにより、ほとんどの機能は Firebase に移行し、Rails は以下の責務のみを担当します：

- **マッチメイキングキュー管理** - Google Cloud Pub/Sub 連携
- **ルーム作成調整** - 2プレイヤーマッチング成立時
- **管理者API** - 運営機能（必要に応じて）

## 🏗️ アーキテクチャ

```
React Frontend
    ↓
Firebase (メイン)
├── 🔥 Authentication - ユーザー認証
├── 🔥 Firestore - ユーザー・楽曲・スコア・ルーム
└── 🔥 Hosting - 静的サイト配信
    
Rails API (最小限)
├── 🚂 マッチメイキングキュー - Pub/Sub連携のみ
└── 🚂 管理者機能 - 運営用API

Go WebSocket (特化)
└── 🔌 ゲーム中通信 - リアルタイムスコア同期
```

## 📡 API エンドポイント（3つのみ）

### 🎮 マッチメイキング

#### POST /api/matchmaking/queue
マッチメイキングキューに参加

```bash
curl -X POST http://localhost:3000/api/matchmaking/queue \
  -H "Authorization: Bearer <firebase_id_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "firebase_uid_123",
    "difficulty": "normal",
    "music_id": "music_001"
  }'
```

**レスポンス**
```json
{
  "status": "queued",
  "queue_position": 1,
  "estimated_wait_time": 30,
  "queue_id": "queue_uuid_123"
}
```

#### DELETE /api/matchmaking/leave
マッチメイキングキューから離脱

```bash
curl -X DELETE http://localhost:3000/api/matchmaking/leave \
  -H "Authorization: Bearer <firebase_id_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "firebase_uid_123",
    "queue_id": "queue_uuid_123"
  }'
```

#### GET /api/matchmaking/status
マッチング状況確認

```bash
curl -X GET "http://localhost:3000/api/matchmaking/status?user_id=firebase_uid_123" \
  -H "Authorization: Bearer <firebase_id_token>"
```

**レスポンス**
```json
{
  "status": "matched",
  "room_id": "room_456",
  "opponent": {
    "uid": "firebase_uid_789",
    "display_name": "Player2"
  },
  "match_found_at": "2024-01-01T12:00:00.000Z"
}
```

## 🔥 Firebase 操作（フロントエンド直接）

Rails を通さず、フロントエンドから直接 Firebase を操作：

### ユーザー管理
```javascript
// Firebase Authentication + Firestore
import { auth, db } from './firebase-config';
import { signInAnonymously } from 'firebase/auth';
import { doc, setDoc } from 'firebase/firestore';

const createUser = async () => {
  const result = await signInAnonymously(auth);
  await setDoc(doc(db, 'users', result.user.uid), {
    displayName: 'プレイヤー',
    highScore: 0,
    createdAt: serverTimestamp()
  });
};
```

### 楽曲・スコア管理
```javascript
// 楽曲一覧取得
const getMusic = async () => {
  const snapshot = await getDocs(collection(db, 'music'));
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// スコア保存
const saveScore = async (scoreData) => {
  await addDoc(collection(db, 'scores'), {
    ...scoreData,
    playedAt: serverTimestamp()
  });
};
```

### ルーム管理（リアルタイム）
```javascript
// ルーム状態監視
const subscribeToRoom = (roomId, callback) => {
  return onSnapshot(doc(db, 'rooms', roomId), (snapshot) => {
    callback(snapshot.data());
  });
};
```

## 🔧 環境構築

### 前提条件
- **Docker & Docker Compose**
- **Google Cloud Project** （Pub/Sub 有効化）
- **Firebase Project** （Firestore、Authentication 設定済み）

### 1. リポジトリクローン
```bash
git clone https://github.com/KOU050223/BandBrother2-Backend.git
cd BandBrother2-Backend/rails-server
```

### 2. 環境変数設定
```bash
# .env ファイル作成
cp .env.example .env

# 必要な環境変数
GOOGLE_CLOUD_PROJECT=your-project-id
PUBSUB_TOPIC=matchmaking-queue
FIREBASE_PROJECT_ID=your-firebase-project
RAILS_ENV=development
```

### 3. Google Cloud 認証
```bash
# サービスアカウントキー配置
cp /path/to/service-account-key.json config/

# または環境変数で指定
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
```

### 4. Docker コンテナ起動
```bash
# BandBrother2-Backend/ ディレクトリで
docker-compose up -d

# または Makefile 使用
make up
```

### 5. 動作確認
```bash
# ヘルスチェック
curl http://localhost:3000/health

# マッチメイキングAPI テスト
curl -X POST http://localhost:3000/api/matchmaking/queue \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test_user","difficulty":"normal","music_id":"music_001"}'
```

## 🧪 テスト

### Rails API テスト
```bash
# コンテナ内でテスト実行
docker-compose exec web bundle exec rails test

# または Makefile
make test-rails
```

### Pub/Sub テスト
```bash
# Pub/Sub エミュレーター起動
gcloud beta emulators pubsub start --project=test-project

# テスト実行（エミュレーター使用）
PUBSUB_EMULATOR_HOST=localhost:8085 bundle exec rails test
```

## 📊 Google Cloud Pub/Sub 設定

### トピック・サブスクリプション作成
```bash
# プロジェクト設定
gcloud config set project your-project-id

# トピック作成
gcloud pubsub topics create matchmaking-queue

# サブスクリプション作成（マッチング処理用）
gcloud pubsub subscriptions create matchmaking-processor \
  --topic=matchmaking-queue
```

### IAM 権限設定
```bash
# サービスアカウントに Pub/Sub 権限付与
gcloud projects add-iam-policy-binding your-project-id \
  --member="serviceAccount:your-service-account@your-project-id.iam.gserviceaccount.com" \
  --role="roles/pubsub.editor"
```

## 🚀 デプロイ

### Cloud Run デプロイ
```bash
# Docker イメージビルド・プッシュ
make deploy-rails

# または手動
docker buildx build --platform linux/amd64 \
  -t asia-northeast1-docker.pkg.dev/your-project/rails-api/matchmaking:latest \
  --push .

# Cloud Run デプロイ
gcloud run deploy matchmaking-api \
  --image=asia-northeast1-docker.pkg.dev/your-project/rails-api/matchmaking:latest \
  --platform=managed \
  --region=asia-northeast1 \
  --allow-unauthenticated
```

## 📝 開発コマンド

```bash
# 📋 利用可能コマンド一覧
make help

# 🚀 開発環境
make up              # Rails サーバー起動
make down            # サーバー停止
make logs            # ログ確認
make shell           # コンテナシェル接続

# 🧪 テスト・品質
make test            # Rails テスト実行
make lint            # RuboCop リント
make format          # コード自動整形

# 🚀 デプロイ
make deploy          # Cloud Run デプロイ
```

## 🔍 ログ・モニタリング

### ローカル開発
```bash
# Rails ログ
docker-compose logs -f web

# Pub/Sub ログ（開発環境）
tail -f log/pubsub.log

# 全サービスログ
make logs
```

### 本番環境
```bash
# Cloud Run ログ
gcloud logs read "resource.type=cloud_run_revision" --limit=50

# Pub/Sub メトリクス
gcloud monitoring metrics list --filter="metric.type:pubsub"
```

## 🚨 トラブルシューティング

### よくある問題

#### ❌ Pub/Sub 接続エラー
```bash
# 認証確認
gcloud auth list

# プロジェクト確認
gcloud config get-value project

# トピック存在確認
gcloud pubsub topics list
```

#### ❌ Firebase 認証エラー
```bash
# サービスアカウントキー確認
ls -la config/service-account-key.json

# 権限確認
gcloud iam service-accounts get-iam-policy your-service-account@your-project.iam.gserviceaccount.com
```

#### ❌ Docker コンテナ起動失敗
```bash
# コンテナ状態確認
docker ps -a

# ログ確認
docker-compose logs web

# 強制再ビルド
docker-compose build --no-cache web
```

## 📚 関連ドキュメント

- **[メイン README](../../README.md)** - プロジェクト全体概要
- **[API 仕様書](../../docs/API.md)** - 詳細 API リファレンス
- **[Firebase 設定ガイド](../../docs/FIREBASE_SETUP.md)** - Firebase 環境構築
- **[Google Cloud 設定](../../docs/GCP_SETUP.md)** - Pub/Sub・Cloud Run 設定

---

## 🎯 Rails 責務まとめ

| 機能 | 担当 | 理由 |
|------|------|------|
| **ユーザー認証** | Firebase | 標準機能・スケーラブル |
| **ユーザー管理** | Firestore | リアルタイム・柔軟性 |
| **楽曲マスター** | Firestore | 静的データ・CDN配信 |
| **スコア管理** | Firestore | 履歴・ランキング・リアルタイム |
| **ルーム状態** | Firestore | リアルタイム更新・接続断検知 |
| **マッチメイキング** | **Rails + Pub/Sub** | **複雑なロジック・キュー管理** |
| **ゲーム通信** | Go WebSocket | 低遅延・高頻度通信 |

Rails は **マッチメイキング専用サーバー** として最適化され、Firebase の強力なリアルタイム機能と組み合わせることで、効率的で拡張性の高いアーキテクチャを実現しています。
