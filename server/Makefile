APP = server

.PHONY: build test lint run coverage

build:
	go build -o bin/$(APP) ./cmd/server

test:
	go test ./...

lint:
	go vet ./...

run:
	go run ./cmd/server

coverage:
	go test -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out
