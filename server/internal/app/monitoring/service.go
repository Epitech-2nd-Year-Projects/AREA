package monitoring

import (
	"context"
	"fmt"
	"strings"
	"time"

	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
)

// Service exposes monitoring queries for jobs and delivery logs
type Service struct {
	jobs outbound.JobRepository
	logs outbound.DeliveryLogRepository
}

// NewService builds a monitoring service instance
func NewService(jobs outbound.JobRepository, logs outbound.DeliveryLogRepository) *Service {
	return &Service{jobs: jobs, logs: logs}
}

// ListJobsOptions defines filters accepted by ListJobs
type ListJobsOptions struct {
	UserID uuid.UUID
	AreaID *uuid.UUID
	Status string
	Limit  int
}

// JobOverview presents job state along with area/component metadata
type JobOverview struct {
	ID            uuid.UUID       `json:"id"`
	Status        string          `json:"status"`
	Attempt       int             `json:"attempt"`
	RunAt         time.Time       `json:"run_at"`
	CreatedAt     time.Time       `json:"created_at"`
	UpdatedAt     time.Time       `json:"updated_at"`
	Area          AreaSummary     `json:"area"`
	Reaction      ReactionSummary `json:"reaction"`
	ResultPayload map[string]any  `json:"result_payload,omitempty"`
	Error         *string         `json:"error,omitempty"`
}

// AreaSummary represents a simplified area description
type AreaSummary struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

// ReactionSummary captures metadata about the reaction component
type ReactionSummary struct {
	Component string `json:"component"`
	Provider  string `json:"provider"`
}

// ListJobs returns recent jobs for the authenticated user respecting filters
func (s *Service) ListJobs(ctx context.Context, opts ListJobsOptions) ([]JobOverview, error) {
	if s == nil || s.jobs == nil {
		return nil, fmt.Errorf("monitoring.Service.ListJobs: repository unavailable")
	}
	if opts.UserID == uuid.Nil {
		return nil, fmt.Errorf("monitoring.Service.ListJobs: user id missing")
	}

	listOpts := outbound.JobListOptions{
		UserID: opts.UserID,
		Limit:  opts.Limit,
	}
	if opts.AreaID != nil {
		listOpts.AreaID = *opts.AreaID
	}
	if trimmed := strings.TrimSpace(opts.Status); trimmed != "" {
		status := jobdomain.Status(strings.ToLower(trimmed))
		listOpts.Status = &status
	}

	details, err := s.jobs.ListWithDetails(ctx, listOpts)
	if err != nil {
		return nil, fmt.Errorf("monitoring.Service.ListJobs: jobs.ListWithDetails: %w", err)
	}

	overviews := make([]JobOverview, 0, len(details))
	for _, detail := range details {
		overview := JobOverview{
			ID:        detail.Job.ID,
			Status:    string(detail.Job.Status),
			Attempt:   detail.Job.Attempt,
			RunAt:     detail.Job.RunAt,
			CreatedAt: detail.Job.CreatedAt,
			UpdatedAt: detail.Job.UpdatedAt,
			Area: AreaSummary{
				ID:   detail.AreaID,
				Name: detail.AreaName,
			},
			Reaction: ReactionSummary{
				Component: detail.ComponentName,
				Provider:  detail.ProviderName,
			},
			ResultPayload: detail.Job.ResultPayload,
			Error:         detail.Job.Error,
		}
		overviews = append(overviews, overview)
	}
	return overviews, nil
}

// ListJobLogs returns delivery logs for the specified job ensuring ownership
func (s *Service) ListJobLogs(ctx context.Context, userID uuid.UUID, jobID uuid.UUID, limit int) ([]jobdomain.DeliveryLog, error) {
	if s == nil || s.jobs == nil || s.logs == nil {
		return nil, fmt.Errorf("monitoring.Service.ListJobLogs: repositories unavailable")
	}
	if userID == uuid.Nil || jobID == uuid.Nil {
		return nil, fmt.Errorf("monitoring.Service.ListJobLogs: identifiers missing")
	}

	// Ensure the job belongs to the user before listing logs
	if _, err := s.jobs.FindDetails(ctx, userID, jobID); err != nil {
		return nil, fmt.Errorf("monitoring.Service.ListJobLogs: authorize job: %w", err)
	}

	logs, err := s.logs.ListByJob(ctx, jobID, limit)
	if err != nil {
		return nil, fmt.Errorf("monitoring.Service.ListJobLogs: logs.ListByJob: %w", err)
	}
	return logs, nil
}
