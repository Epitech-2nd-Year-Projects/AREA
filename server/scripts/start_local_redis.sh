#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME=${CONTAINER_NAME:-area-redis}
IMAGE=${REDIS_IMAGE:-redis:7-alpine}
PORT=${REDIS_PORT:-6379}

if ! command -v docker >/dev/null 2>&1; then
	echo "docker binary not found in PATH" >&2
	exit 1
fi

status=$(docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format "{{.Status}}" || true)

if [[ -n "$status" ]]; then
	if docker ps --filter "name=^/${CONTAINER_NAME}$" --filter "status=running" --format '{{.ID}}' | grep -q .; then
		echo "Redis container '${CONTAINER_NAME}' already running (status: $status)"
	else
		echo "Starting existing Redis container '${CONTAINER_NAME}'"
		docker start "$CONTAINER_NAME" >/dev/null
		echo "Redis running at redis://localhost:${PORT}"
	fi
	exit 0
fi

echo "Launching Redis container '${CONTAINER_NAME}' from image ${IMAGE}"
docker run -d \
	--name "$CONTAINER_NAME" \
	-p "${PORT}:6379" \
	"$IMAGE" >/dev/null

echo "Redis running at redis://localhost:${PORT}"
