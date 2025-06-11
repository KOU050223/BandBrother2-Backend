# デプロイ手順

```bash
terraform init
terraform plan
terraform apply
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
