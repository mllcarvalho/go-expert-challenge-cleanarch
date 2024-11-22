FROM golang:1.22.5 as builder

WORKDIR /app

# Copiar os arquivos do projeto
COPY . .

# Instalar dependências
RUN go mod tidy

# Compilar o binário para a arquitetura do container final
RUN GOOS=linux GOARCH=amd64 go build -o app ./cmd/ordersystem/main.go ./cmd/ordersystem/wire_gen.go

# ------------------------------
FROM alpine:3.18

WORKDIR /app

ARG DB_USER
ARG DB_PASS
ARG DB_HOST
ARG DB_PORT
ARG DB_NAME

# Use as variáveis no Dockerfile, se necessário
RUN echo "Connecting to DB at $DB_HOST:$DB_PORT with user $DB_USER"

RUN ls

# Instalar cliente MySQL e curl
RUN apk add --no-cache mysql-client curl && \
    curl -L https://github.com/golang-migrate/migrate/releases/download/v4.16.2/migrate.linux-arm64.tar.gz | tar xz -C /usr/local/bin

# Copiar o binário e arquivos necessários
COPY --from=builder /app/app .
COPY --from=builder /app/internal/infra/database/migrations internal/infra/database/migrations

# Expor as portas usadas pela aplicação
EXPOSE 8000 50051 8080

CMD ["./app/app"]