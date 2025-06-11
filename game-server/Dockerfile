# game-server/Dockerfile

FROM golang:1.23 AS builder

WORKDIR /app

# 依存ファイルをコピーしてgo mod tidy
COPY go.mod go.sum ./
RUN go mod tidy

# 残り全部コピー
COPY . .

# ビルド（main.goはcmd/server配下）ビルドするときにCGO_ENABLED=0を設定して、Goのビルドを静的に行う
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server ./cmd/server/main.go


# 実行用
FROM gcr.io/distroless/base-debian11
WORKDIR /app
COPY --from=builder /app/server .
CMD ["/app/server"]
