package redisqueue

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/queue"
	"github.com/alicebob/miniredis/v2"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

func newTestQueue(t *testing.T) (*Queue, *miniredis.Miniredis) {
	t.Helper()

	srv := miniredis.RunT(t)
	cfg := Config{
		Addr:     srv.Addr(),
		QueueKey: "jobs",
	}
	q, err := New(context.Background(), cfg, zap.NewNop())
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	return q, srv
}

func TestNewQueueDefaults(t *testing.T) {
	q, srv := newTestQueue(t)
	defer srv.Close()

	if q.client == nil {
		t.Fatal("expected redis client to be initialised")
	}
	if q.processing != "jobs:processing" {
		t.Fatalf("processing key = %q, want %q", q.processing, "jobs:processing")
	}
	if q.visibility != defaultVisibilityTimeout {
		t.Fatalf("visibility timeout = %s, want %s", q.visibility, defaultVisibilityTimeout)
	}
}

func TestNewQueueCustomProcessingAndVisibility(t *testing.T) {
	srv := miniredis.RunT(t)
	defer srv.Close()

	cfg := Config{
		Addr:              srv.Addr(),
		QueueKey:          "primary",
		ProcessingKey:     "custom:processing",
		VisibilityTimeout: 5 * time.Second,
	}
	q, err := New(context.Background(), cfg, nil)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if q.processing != "custom:processing" {
		t.Fatalf("processing key = %q, want %q", q.processing, "custom:processing")
	}
	if q.visibility != 5*time.Second {
		t.Fatalf("visibility timeout = %s, want 5s", q.visibility)
	}
}

func TestNewQueueMissingKey(t *testing.T) {
	if _, err := New(context.Background(), Config{}, nil); err == nil {
		t.Fatal("New() expected error for missing queue key")
	}
}

func TestNewQueuePingFailure(t *testing.T) {
	cfg := Config{Addr: "127.0.0.1:1", QueueKey: "jobs"}
	_, err := New(context.Background(), cfg, zap.NewNop())
	if err == nil || !contains(err.Error(), "ping redis") {
		t.Fatalf("New() expected ping error, got %v", err)
	}
}

func TestQueueEnqueueStoresPayload(t *testing.T) {
	q, srv := newTestQueue(t)
	defer srv.Close()

	jobID := uuid.New()
	runAt := time.Now().Add(2 * time.Minute).UTC()
	msg := queue.JobMessage{JobID: jobID, RunAt: runAt}
	if err := q.Enqueue(context.Background(), msg); err != nil {
		t.Fatalf("Enqueue() error = %v", err)
	}

	items := list(t, srv, "jobs")
	if len(items) != 1 {
		t.Fatalf("List len = %d, want 1", len(items))
	}

	var stored payload
	if err := json.Unmarshal([]byte(items[0]), &stored); err != nil {
		t.Fatalf("json.Unmarshal() error = %v", err)
	}
	if stored.JobID != jobID.String() {
		t.Fatalf("stored.JobID = %q, want %q", stored.JobID, jobID)
	}
	if !stored.RunAt.Equal(runAt) {
		t.Fatalf("stored.RunAt = %s, want %s", stored.RunAt, runAt)
	}
}

func TestQueueEnqueueErrors(t *testing.T) {
	var nilQueue *Queue
	if err := nilQueue.Enqueue(context.Background(), queue.JobMessage{JobID: uuid.New()}); err == nil {
		t.Fatal("nil queue expected error")
	}

	q, srv := newTestQueue(t)
	defer srv.Close()

	if err := q.Enqueue(context.Background(), queue.JobMessage{}); err == nil {
		t.Fatal("Enqueue() expected error for missing job id")
	}
}

func TestQueueReserveAndAck(t *testing.T) {
	q, srv := newTestQueue(t)
	defer srv.Close()

	jobID := uuid.New()
	runAt := time.Now().Add(30 * time.Second).UTC()
	if err := q.Enqueue(context.Background(), queue.JobMessage{JobID: jobID, RunAt: runAt}); err != nil {
		t.Fatalf("Enqueue() error = %v", err)
	}

	res, err := q.Reserve(context.Background(), time.Second)
	if err != nil {
		t.Fatalf("Reserve() error = %v", err)
	}

	msg := res.Message()
	if msg.JobID != jobID {
		t.Fatalf("reservation.JobID = %s, want %s", msg.JobID, jobID)
	}
	if !msg.RunAt.Equal(runAt) {
		t.Fatalf("reservation.RunAt = %s, want %s", msg.RunAt, runAt)
	}

	if err := res.Ack(context.Background()); err != nil {
		t.Fatalf("Ack() error = %v", err)
	}
	if err := res.Ack(context.Background()); err != nil {
		t.Fatalf("Ack() second call error = %v", err)
	}

	if l := list(t, srv, "jobs:processing"); len(l) != 0 {
		t.Fatalf("processing list should be empty after ack, got %v", l)
	}
}

func TestQueueReserveEmpty(t *testing.T) {
	q, srv := newTestQueue(t)
	defer srv.Close()

	_, err := q.Reserve(context.Background(), time.Millisecond*100)
	if !errors.Is(err, queue.ErrEmpty) {
		t.Fatalf("Reserve() error = %v, want ErrEmpty", err)
	}
}

func TestQueueReserveInvalidPayload(t *testing.T) {
	q, srv := newTestQueue(t)
	defer srv.Close()

	if _, err := srv.RPush("jobs", "not-json"); err != nil {
		t.Fatalf("RPush() error = %v", err)
	}

	_, err := q.Reserve(context.Background(), time.Second)
	if err == nil || !contains(err.Error(), "decode payload") {
		t.Fatalf("Reserve() expected decode error, got %v", err)
	}

	if l := list(t, srv, "jobs:processing"); len(l) != 0 {
		t.Fatalf("invalid payload should be removed from processing, got %v", l)
	}
}

func TestQueueReserveNilReceiver(t *testing.T) {
	var q *Queue
	if _, err := q.Reserve(context.Background(), time.Second); err == nil {
		t.Fatal("nil queue expected error")
	}
}

func TestReservationRequeue(t *testing.T) {
	q, srv := newTestQueue(t)
	defer srv.Close()

	jobID := uuid.New()
	runAt := time.Now().UTC()
	if err := q.Enqueue(context.Background(), queue.JobMessage{JobID: jobID, RunAt: runAt}); err != nil {
		t.Fatalf("Enqueue() error = %v", err)
	}

	res, err := q.Reserve(context.Background(), time.Second)
	if err != nil {
		t.Fatalf("Reserve() error = %v", err)
	}

	before := time.Now().UTC()
	delay := 5 * time.Second
	if err := res.Requeue(context.Background(), delay); err != nil {
		t.Fatalf("Requeue() error = %v", err)
	}
	if err := res.Requeue(context.Background(), delay); err != nil {
		t.Fatalf("Requeue() second call error = %v", err)
	}

	items := list(t, srv, "jobs")
	if len(items) != 1 {
		t.Fatalf("expected 1 item in queue after requeue, got %d", len(items))
	}

	var pl payload
	if err := json.Unmarshal([]byte(items[0]), &pl); err != nil {
		t.Fatalf("json.Unmarshal() error = %v", err)
	}
	if pl.JobID != jobID.String() {
		t.Fatalf("requeued job id = %q, want %q", pl.JobID, jobID)
	}
	if pl.RunAt.Before(before.Add(delay)) {
		t.Fatalf("requeued RunAt = %s, want at least %s", pl.RunAt, before.Add(delay))
	}
	if l := list(t, srv, "jobs:processing"); len(l) != 0 {
		t.Fatalf("processing list should be empty after requeue, got %v", l)
	}
}

func TestReservationAckWithoutQueue(t *testing.T) {
	res := reservation{}
	if err := res.Ack(context.Background()); err == nil {
		t.Fatal("Ack() expected error when queue missing")
	}
	if err := res.Requeue(context.Background(), time.Second); err == nil {
		t.Fatal("Requeue() expected error when queue missing")
	}
}

func list(t *testing.T, srv *miniredis.Miniredis, key string) []string {
	t.Helper()

	items, err := srv.List(key)
	if err == miniredis.ErrKeyNotFound {
		return nil
	}
	if err != nil {
		t.Fatalf("srv.List(%q) error = %v", key, err)
	}
	return items
}

func contains(s, substr string) bool {
	return strings.Contains(s, substr)
}
