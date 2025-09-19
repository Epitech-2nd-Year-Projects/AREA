FROM golang:1.25.1-alpine AS builder
WORKDIR /src
COPY . .
RUN go build -o /out/server ./cmd/server

FROM alpine:3.22 AS runner
COPY --from=builder /out/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]

