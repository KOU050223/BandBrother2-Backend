# README

# 環境構築手順

1. クローン

```bash
git clone git@github.com:KOU050223/BandBrother2-Backend.git
```

2. プロジェクトの移動（rubyの環境はあるものとする/rubyのバージョンに注意）

```bash
cd rails-server
bundle install
```

3. 秘密鍵の配置

`config/master.key`を他開発者から入手しコピーしてください
この際にmaster.key内の文字列の後に改行を入れてください

4. 実行権限の設定

```bash
chmod +x bin/docker-entrypoint
```

5. Dockerイメージのビルド＆起動

```bash
docker-compose build
docker-compose up -d
```

6. DBマイグレーション

```bash
docker-compose exec web bundle exec rails db:create db:migrate
```

7. 動作確認

http://localhost:3000

# 開発サーバー（Dockerコンテナ）立ち上げ

```bash
docker-compose down
docker-compose up -d
```