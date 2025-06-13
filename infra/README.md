# デプロイ手順

```bash
terraform init
terraform plan
terraform apply
```

# リソース削除

```bash
terraform destroy
```

# 構築手順メモ

Artifact Registry API・Cloud Run Admin APIを有効にする

https://console.cloud.google.com/apis/api/artifactregistry.googleapis.com/metrics
https://console.cloud.google.com/apis/api/run.googleapis.com/metrics

環境変数を渡す

- terraform.tfvars

## Dockerコンテナをプッシュ

初回のみ認証を挟む

```bash
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
```

### game-serverの方のコンテナプッシュ

```bash
# 1. game-serverディレクトリに移動
cd ../game-server

# 2. ビルド（必要ならGoのmain.goを含むディレクトリで）
docker buildx build --platform linux/amd64 \
  -t asia-northeast1-docker.pkg.dev/bandbrother2/go-websocket/game-server:latest \
  --push .

# 3. Google Cloudへpush
docker push asia-northeast1-docker.pkg.dev/bandbrother2/go-websocket/game-server:latest
```

```bash
# 1. rails-server ディレクトリに移動
cd ../rails-server

# 2. ビルド
DOCKER_BUILDKIT=1 docker buildx build --platform linux/amd64 \
  -t asia-northeast1-docker.pkg.dev/bandbrother2/rails-server/rails-server:latest \
  --push .
```
