APP = server

.PHONY: build test lint run coverage callvis-ui

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

callvis-ui:
	@if ! command -v go-callvis >/dev/null 2>&1; then \
		echo "Installing go-callvis..."; \
		go install github.com/ofabry/go-callvis@latest; \
	else \
		echo "go-callvis already installed"; \
	fi
	@echo "starting go-callvis interactive server at http://localhost:7878"
	@go-callvis \
		-group pkg,type \
		-rankdir LR \
		-nostd \
		-tests=false \
		-ignore '(vendor|migrations|scripts|/openapi/|\.gen\.go$$)' \
		./cmd/server
