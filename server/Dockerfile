FROM golang:1.25.3-alpine AS builder
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server

FROM alpine:3.22 AS runner
WORKDIR /
COPY --from=builder /out/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]

