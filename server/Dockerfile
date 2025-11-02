FROM golang:1.25.3-alpine AS builder
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server

FROM alpine:3.22 AS runner
WORKDIR /
COPY --from=builder /out/server /server
COPY config /config
RUN if [ ! -f /config/config.yaml ] && [ -f /config/config.example.yaml ]; then cp /config/config.example.yaml /config/config.yaml; fi
EXPOSE 8080
ENTRYPOINT ["/server"]
