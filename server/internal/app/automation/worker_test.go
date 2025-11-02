package automation

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	areaapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/area"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
	subscriptiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/subscription"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	queueport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/queue"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

type singleReservationQueue struct {
	reservation queueport.Reservation
	once        sync.Once
}

type fixedClock struct {
	now time.Time
}

func (f fixedClock) Now() time.Time {
	return f.now
}

type recordingHandler struct {
	called bool
	err    error
}

func (h *recordingHandler) Supports(component *componentdomain.Component) bool {
	return component != nil
}

func (h *recordingHandler) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	h.called = true
	status := 200
	if h.err != nil {
		status = 500
	}
	return outbound.ReactionResult{
		Endpoint: "test-endpoint",
		Request: map[string]any{
			"foo": "bar",
		},
		Response: map[string]any{
			"status": "ok",
		},
		StatusCode: &status,
		Duration:   5 * time.Millisecond,
	}, h.err
}

func (s *singleReservationQueue) Enqueue(ctx context.Context, msg queueport.JobMessage) error {
	return nil
}

func (s *singleReservationQueue) Reserve(ctx context.Context, timeout time.Duration) (queueport.Reservation, error) {
	var res queueport.Reservation
	s.once.Do(func() {
		res = s.reservation
	})
	if res == nil {
		return nil, queueport.ErrEmpty
	}
	return res, nil
}

type testReservation struct {
	msg   queueport.JobMessage
	acked bool
	retry bool
	delay time.Duration
	mu    sync.Mutex
}

func (r *testReservation) Message() queueport.JobMessage {
	return r.msg
}

func (r *testReservation) Ack(ctx context.Context) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.acked = true
	return nil
}

func (r *testReservation) Requeue(ctx context.Context, delay time.Duration) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.retry = true
	r.delay = delay
	r.msg.RunAt = time.Now().Add(delay)
	return nil
}

type stubJobRepository struct {
	job     jobdomain.Job
	updated jobdomain.Job
	mu      sync.Mutex
}

func (s *stubJobRepository) Create(ctx context.Context, job jobdomain.Job) (jobdomain.Job, error) {
	return job, nil
}

func (s *stubJobRepository) CreateBatch(ctx context.Context, jobs []jobdomain.Job) ([]jobdomain.Job, error) {
	return jobs, nil
}

func (s *stubJobRepository) Update(ctx context.Context, job jobdomain.Job) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.updated = job
	s.job = job
	return nil
}

func (s *stubJobRepository) Claim(ctx context.Context, id uuid.UUID, worker string, now time.Time) (jobdomain.Job, error) {
	if s.job.ID != id {
		return jobdomain.Job{}, outbound.ErrNotFound
	}
	jobCopy := s.job
	jobCopy.Status = jobdomain.StatusRunning
	jobCopy.Attempt++
	jobCopy.LockedBy = &worker
	lockedAt := now
	jobCopy.LockedAt = &lockedAt
	s.job = jobCopy
	return jobCopy, nil
}

func (s *stubJobRepository) ListWithDetails(ctx context.Context, opts outbound.JobListOptions) ([]outbound.JobDetails, error) {
	return []outbound.JobDetails{}, nil
}

func (s *stubJobRepository) FindDetails(ctx context.Context, userID uuid.UUID, jobID uuid.UUID) (outbound.JobDetails, error) {
	return outbound.JobDetails{}, outbound.ErrNotFound
}

type stubLogRepository struct {
	logs []jobdomain.DeliveryLog
	mu   sync.Mutex
}

func (s *stubLogRepository) Create(ctx context.Context, log jobdomain.DeliveryLog) (jobdomain.DeliveryLog, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.logs = append(s.logs, log)
	return log, nil
}

func (s *stubLogRepository) ListByJob(ctx context.Context, jobID uuid.UUID, limit int) ([]jobdomain.DeliveryLog, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]jobdomain.DeliveryLog(nil), s.logs...), nil
}

type stubAreaRepository struct {
	area areadomain.Area
}

func (s stubAreaRepository) Create(ctx context.Context, area areadomain.Area, action areadomain.Link, reactions []areadomain.Link) (areadomain.Area, error) {
	return s.area, nil
}

func (s stubAreaRepository) FindByID(ctx context.Context, id uuid.UUID) (areadomain.Area, error) {
	return s.area, nil
}

func (s stubAreaRepository) ListByUser(ctx context.Context, userID uuid.UUID) ([]areadomain.Area, error) {
	return []areadomain.Area{s.area}, nil
}

func (s stubAreaRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return nil
}

func (s stubAreaRepository) UpdateMetadata(ctx context.Context, area areadomain.Area) error {
	return nil
}

func (s stubAreaRepository) UpdateConfig(ctx context.Context, config componentdomain.Config) error {
	return nil
}

type stubComponentRepository struct {
	components map[uuid.UUID]componentdomain.Component
}

func (s stubComponentRepository) FindByID(ctx context.Context, id uuid.UUID) (componentdomain.Component, error) {
	return s.components[id], nil
}

func (s stubComponentRepository) FindByIDs(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]componentdomain.Component, error) {
	return s.components, nil
}

func (s stubComponentRepository) List(ctx context.Context, opts outbound.ComponentListOptions) ([]componentdomain.Component, error) {
	result := make([]componentdomain.Component, 0, len(s.components))
	for _, component := range s.components {
		result = append(result, component)
	}
	return result, nil
}

type stubSubscriptionRepository struct{}

func (stubSubscriptionRepository) Create(ctx context.Context, subscription subscriptiondomain.Subscription) (subscriptiondomain.Subscription, error) {
	return subscription, nil
}

func (stubSubscriptionRepository) Update(ctx context.Context, subscription subscriptiondomain.Subscription) error {
	return nil
}

func (stubSubscriptionRepository) FindByUserAndProvider(ctx context.Context, userID uuid.UUID, providerID uuid.UUID) (subscriptiondomain.Subscription, error) {
	return subscriptiondomain.Subscription{Status: subscriptiondomain.StatusActive}, nil
}

func (stubSubscriptionRepository) ListByUser(ctx context.Context, userID uuid.UUID) ([]subscriptiondomain.Subscription, error) {
	return []subscriptiondomain.Subscription{}, nil
}

func TestWorkerProcessesJob(t *testing.T) {
	logger := zap.NewNop()
	now := time.Unix(1720000000, 0).UTC()
	jobID := uuid.New()
	areaID := uuid.New()
	userID := uuid.New()
	reactionID := uuid.New()
	providerID := uuid.New()
	componentID := uuid.New()

	component := componentdomain.Component{
		ID:        componentID,
		Name:      "http_request",
		Provider:  componentdomain.Provider{ID: providerID, Name: "http"},
		Kind:      componentdomain.KindReaction,
		Enabled:   true,
		CreatedAt: now,
		UpdatedAt: now,
	}

	reactionLink := areadomain.Link{
		ID:   reactionID,
		Role: areadomain.LinkRoleReaction,
		Config: componentdomain.Config{
			ID:          uuid.New(),
			ComponentID: componentID,
			Component:   &component,
			Params: map[string]any{
				"url": "https://example.com",
			},
			Active:    true,
			CreatedAt: now,
			UpdatedAt: now,
		},
		CreatedAt: now,
		UpdatedAt: now,
	}

	areaModel := areadomain.Area{
		ID:     areaID,
		UserID: userID,
		Name:   "Test area",
		Action: &areadomain.Link{
			ID:   uuid.New(),
			Role: areadomain.LinkRoleAction,
			Config: componentdomain.Config{
				ID:          uuid.New(),
				ComponentID: uuid.New(),
				Component: &componentdomain.Component{
					ID:       uuid.New(),
					Name:     "timer_interval",
					Provider: componentdomain.Provider{Name: "scheduler"},
					Kind:     componentdomain.KindAction,
					Enabled:  true,
				},
				Params:    map[string]any{},
				Active:    true,
				CreatedAt: now,
				UpdatedAt: now,
			},
			CreatedAt: now,
			UpdatedAt: now,
		},
		Reactions: []areadomain.Link{reactionLink},
		CreatedAt: now,
		UpdatedAt: now,
	}

	areaRepo := stubAreaRepository{area: areaModel}
	componentRepo := stubComponentRepository{components: map[uuid.UUID]componentdomain.Component{
		componentID: component,
	}}
	subsRepo := stubSubscriptionRepository{}
	service := areaapp.NewService(areaRepo, componentRepo, subsRepo, nil, nil, fixedClock{now: now}, nil)

	job := jobdomain.Job{
		ID: jobID,
		InputPayload: map[string]any{
			"areaId":        areaID.String(),
			"userId":        userID.String(),
			"reactionId":    reactionID.String(),
			"componentName": component.Name,
			"provider":      component.Provider.Name,
			"providerId":    providerID.String(),
			"params": map[string]any{
				"url": "https://example.com",
			},
		},
		RunAt:  now,
		Status: jobdomain.StatusQueued,
	}

	jobRepo := &stubJobRepository{job: job}
	reservation := &testReservation{msg: queueport.JobMessage{JobID: jobID}}
	queue := &singleReservationQueue{reservation: reservation}

	handler := &recordingHandler{}
	reactionExecutor := areaapp.NewCompositeReactionExecutor(nil, logger, handler)
	logRepo := &stubLogRepository{}

	worker := NewWorker(queue, jobRepo, logRepo, service, reactionExecutor, logger, WithClock(fixedClock{now: now}), WithPollTimeout(10*time.Millisecond))

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go worker.Run(ctx)

	time.Sleep(50 * time.Millisecond)
	cancel()
	time.Sleep(20 * time.Millisecond)

	jobRepo.mu.Lock()
	defer jobRepo.mu.Unlock()
	if jobRepo.updated.Status != jobdomain.StatusSucceeded {
		t.Fatalf("expected job status succeeded, got %s", jobRepo.updated.Status)
	}
	if !reservation.acked {
		t.Fatalf("expected reservation to be acked")
	}
	if !handler.called {
		t.Fatalf("expected reaction handler to be executed")
	}
	if len(logRepo.logs) != 1 {
		t.Fatalf("expected one delivery log entry, got %d", len(logRepo.logs))
	}
}

func TestWorkerRetriesJob(t *testing.T) {
	logger := zap.NewNop()
	now := time.Unix(1720000000, 0).UTC()
	jobID := uuid.New()
	areaID := uuid.New()
	userID := uuid.New()
	reactionID := uuid.New()
	providerID := uuid.New()
	componentID := uuid.New()

	component := componentdomain.Component{
		ID:        componentID,
		Name:      "http_request",
		Provider:  componentdomain.Provider{ID: providerID, Name: "http"},
		Kind:      componentdomain.KindReaction,
		Enabled:   true,
		CreatedAt: now,
		UpdatedAt: now,
	}

	retryPolicy := &areadomain.RetryPolicy{
		MaxRetries: 2,
		Strategy:   areadomain.RetryStrategyConstant,
		BaseDelay:  500 * time.Millisecond,
		MaxDelay:   2 * time.Second,
	}

	reactionLink := areadomain.Link{
		ID:   reactionID,
		Role: areadomain.LinkRoleReaction,
		Config: componentdomain.Config{
			ID:          uuid.New(),
			ComponentID: componentID,
			Component:   &component,
			Params: map[string]any{
				"url": "https://example.com",
			},
			Active:    true,
			CreatedAt: now,
			UpdatedAt: now,
		},
		RetryPolicy: retryPolicy,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	areaModel := areadomain.Area{
		ID:     areaID,
		UserID: userID,
		Name:   "Retry area",
		Action: &areadomain.Link{
			ID:   uuid.New(),
			Role: areadomain.LinkRoleAction,
			Config: componentdomain.Config{
				ID:          uuid.New(),
				ComponentID: uuid.New(),
				Component: &componentdomain.Component{
					ID:       uuid.New(),
					Name:     "timer_interval",
					Provider: componentdomain.Provider{Name: "scheduler"},
					Kind:     componentdomain.KindAction,
					Enabled:  true,
				},
				Params:    map[string]any{},
				Active:    true,
				CreatedAt: now,
				UpdatedAt: now,
			},
			CreatedAt: now,
			UpdatedAt: now,
		},
		Reactions: []areadomain.Link{reactionLink},
		CreatedAt: now,
		UpdatedAt: now,
	}

	areaRepo := stubAreaRepository{area: areaModel}
	componentRepo := stubComponentRepository{components: map[uuid.UUID]componentdomain.Component{
		componentID: component,
	}}
	subsRepo := stubSubscriptionRepository{}
	service := areaapp.NewService(areaRepo, componentRepo, subsRepo, nil, nil, fixedClock{now: now}, nil)

	job := jobdomain.Job{
		ID: jobID,
		InputPayload: map[string]any{
			"areaId":        areaID.String(),
			"userId":        userID.String(),
			"reactionId":    reactionID.String(),
			"componentName": component.Name,
			"provider":      component.Provider.Name,
			"providerId":    providerID.String(),
			"params": map[string]any{
				"url": "https://example.com",
			},
		},
		RunAt:  now,
		Status: jobdomain.StatusQueued,
	}

	jobRepo := &stubJobRepository{job: job}
	reservation := &testReservation{msg: queueport.JobMessage{JobID: jobID}}
	queue := &singleReservationQueue{reservation: reservation}
	handler := &recordingHandler{err: errors.New("boom")}
	reactionExecutor := areaapp.NewCompositeReactionExecutor(nil, logger, handler)
	logRepo := &stubLogRepository{}

	worker := NewWorker(queue, jobRepo, logRepo, service, reactionExecutor, logger, WithClock(fixedClock{now: now}), WithPollTimeout(10*time.Millisecond))

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go worker.Run(ctx)

	time.Sleep(30 * time.Millisecond)
	cancel()
	time.Sleep(10 * time.Millisecond)

	jobRepo.mu.Lock()
	updated := jobRepo.updated
	jobRepo.mu.Unlock()

	if updated.Status != jobdomain.StatusRetrying {
		t.Fatalf("expected job status retrying, got %s", updated.Status)
	}
	expectedDelay := retryPolicy.Delay(updated.Attempt)
	if updated.RunAt.Sub(now) != expectedDelay {
		t.Fatalf("unexpected runAt delay: got %v want %v", updated.RunAt.Sub(now), expectedDelay)
	}

	if !reservation.retry {
		t.Fatalf("expected reservation to be requeued")
	}
	if reservation.delay != expectedDelay {
		t.Fatalf("expected delay %v, got %v", expectedDelay, reservation.delay)
	}

	if len(logRepo.logs) != 1 {
		t.Fatalf("expected one delivery log, got %d", len(logRepo.logs))
	}
	if logRepo.logs[0].StatusCode == nil || *logRepo.logs[0].StatusCode != 500 {
		t.Fatalf("expected delivery log status 500")
	}
}
