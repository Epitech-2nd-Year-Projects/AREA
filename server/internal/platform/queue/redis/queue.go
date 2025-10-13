package redisqueue

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/queue"
	"github.com/google/uuid"
	goredis "github.com/redis/go-redis/v9"
	"go.uber.org/zap"
)

// Config captures the Redis connection settings for the job queue
type Config struct {
	Addr              string
	Password          string
	DB                int
	QueueKey          string
	ProcessingKey     string
	VisibilityTimeout time.Duration
}

const defaultVisibilityTimeout = 30 * time.Second

type payload struct {
	JobID string    `json:"job_id"`
	RunAt time.Time `json:"run_at"`
}

// Queue implements a Redis-backed job queue with reliable reservations
type Queue struct {
	client     *goredis.Client
	queueKey   string
	processing string
	visibility time.Duration
	log        *zap.Logger
}

// New constructs a Queue from the provided configuration
func New(ctx context.Context, cfg Config, logger *zap.Logger) (*Queue, error) {
	if logger == nil {
		logger = zap.NewNop()
	}
	if cfg.QueueKey == "" {
		return nil, fmt.Errorf("redisqueue.New: queue key required")
	}
	processingKey := cfg.ProcessingKey
	if processingKey == "" {
		processingKey = cfg.QueueKey + ":processing"
	}
	visibility := cfg.VisibilityTimeout
	if visibility <= 0 {
		visibility = defaultVisibilityTimeout
	}

	client := goredis.NewClient(&goredis.Options{
		Addr:     cfg.Addr,
		DB:       cfg.DB,
		Password: cfg.Password,
	})
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("redisqueue.New: ping redis: %w", err)
	}

	return &Queue{
		client:     client,
		queueKey:   cfg.QueueKey,
		processing: processingKey,
		visibility: visibility,
		log:        logger,
	}, nil
}

// Enqueue appends a job to the pending list
func (q *Queue) Enqueue(ctx context.Context, msg queue.JobMessage) error {
	if q == nil {
		return fmt.Errorf("redisqueue.Queue.Enqueue: nil receiver")
	}
	if msg.JobID == uuid.Nil {
		return fmt.Errorf("redisqueue.Queue.Enqueue: job id missing")
	}
	pl := payload{
		JobID: msg.JobID.String(),
		RunAt: msg.RunAt.UTC(),
	}
	data, err := json.Marshal(pl)
	if err != nil {
		return fmt.Errorf("redisqueue.Queue.Enqueue: marshal payload: %w", err)
	}
	if err := q.client.RPush(ctx, q.queueKey, data).Err(); err != nil {
		return fmt.Errorf("redisqueue.Queue.Enqueue: rpush: %w", err)
	}
	return nil
}

// Reserve leases a job using BRPOPLPUSH to ensure reliability
func (q *Queue) Reserve(ctx context.Context, timeout time.Duration) (queue.Reservation, error) {
	if q == nil {
		return nil, fmt.Errorf("redisqueue.Queue.Reserve: nil receiver")
	}
	if timeout <= 0 {
		timeout = q.visibility
	}
	raw, err := q.client.BRPopLPush(ctx, q.queueKey, q.processing, timeout).Result()
	if err != nil {
		if err == goredis.Nil {
			return nil, queue.ErrEmpty
		}
		return nil, fmt.Errorf("redisqueue.Queue.Reserve: brpoplpush: %w", err)
	}

	res, err := q.decodeReservation(raw)
	if err != nil {
		if remErr := q.client.LRem(ctx, q.processing, 1, raw).Err(); remErr != nil {
			q.log.Warn("failed to remove invalid payload", zap.Error(remErr))
		}
		return nil, err
	}
	res.queue = q
	res.raw = raw
	return res, nil
}

func (q *Queue) decodeReservation(raw string) (*reservation, error) {
	var pl payload
	if err := json.Unmarshal([]byte(raw), &pl); err != nil {
		return nil, fmt.Errorf("redisqueue.Queue.decodeReservation: decode payload: %w", err)
	}
	jobID, err := uuid.Parse(pl.JobID)
	if err != nil {
		return nil, fmt.Errorf("redisqueue.Queue.decodeReservation: parse job id: %w", err)
	}
	return &reservation{
		message: queue.JobMessage{
			JobID: jobID,
			RunAt: pl.RunAt.UTC(),
		},
		payload: pl,
	}, nil
}

type reservation struct {
	queue   *Queue
	message queue.JobMessage
	payload payload
	raw     string
	acked   bool
}

func (r *reservation) Message() queue.JobMessage {
	return r.message
}

func (r *reservation) Ack(ctx context.Context) error {
	if r.queue == nil {
		return fmt.Errorf("redisqueue.reservation.Ack: queue missing")
	}
	if r.acked {
		return nil
	}
	if err := r.queue.client.LRem(ctx, r.queue.processing, 1, r.raw).Err(); err != nil {
		return fmt.Errorf("redisqueue.reservation.Ack: lrem processing: %w", err)
	}
	r.acked = true
	return nil
}

func (r *reservation) Requeue(ctx context.Context, delay time.Duration) error {
	if r.queue == nil {
		return fmt.Errorf("redisqueue.reservation.Requeue: queue missing")
	}
	if r.acked {
		return nil
	}
	if err := r.queue.client.LRem(ctx, r.queue.processing, 1, r.raw).Err(); err != nil {
		return fmt.Errorf("redisqueue.reservation.Requeue: lrem processing: %w", err)
	}
	r.acked = true

	next := r.payload
	next.RunAt = time.Now().UTC().Add(delay)
	data, err := json.Marshal(next)
	if err != nil {
		return fmt.Errorf("redisqueue.reservation.Requeue: marshal payload: %w", err)
	}
	if err := r.queue.client.RPush(ctx, r.queue.queueKey, data).Err(); err != nil {
		return fmt.Errorf("redisqueue.reservation.Requeue: rpush queue: %w", err)
	}
	return nil
}

var _ queue.JobQueue = (*Queue)(nil)
