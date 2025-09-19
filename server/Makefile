APP = server

.PHONY: build test lint run

build:
	go build -o bin/$(APP) ./cmd/server

test:
	go test ./...

lint:
	go vet ./...

run:
	go run ./cmd/server

