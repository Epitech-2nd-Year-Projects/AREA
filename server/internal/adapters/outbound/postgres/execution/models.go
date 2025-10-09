package execution

import (
	"encoding/json"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type eventModel struct {
	ID          uuid.UUID      `gorm:"column:id;type:uuid;primaryKey"`
	SourceID    uuid.UUID      `gorm:"column:source_id"`
	OccurredAt  time.Time      `gorm:"column:occurred_at"`
	ReceivedAt  time.Time      `gorm:"column:received_at"`
	Fingerprint string         `gorm:"column:fingerprint"`
	Payload     datatypes.JSON `gorm:"column:payload"`
	DedupStatus string         `gorm:"column:dedup_status"`
}

func (eventModel) TableName() string { return "action_events" }

func (m eventModel) toDomain() actiondomain.Event {
	payload := map[string]any{}
	if len(m.Payload) > 0 {
		_ = json.Unmarshal(m.Payload, &payload)
	}
	return actiondomain.Event{
		ID:          m.ID,
		SourceID:    m.SourceID,
		OccurredAt:  m.OccurredAt,
		ReceivedAt:  m.ReceivedAt,
		Fingerprint: m.Fingerprint,
		Payload:     payload,
		DedupStatus: actiondomain.DedupStatus(m.DedupStatus),
	}
}

func eventFromDomain(event actiondomain.Event) (eventModel, error) {
	payload := event.Payload
	if payload == nil {
		payload = map[string]any{}
	}
	buffer, err := json.Marshal(payload)
	if err != nil {
		return eventModel{}, err
	}
	return eventModel{
		ID:          event.ID,
		SourceID:    event.SourceID,
		OccurredAt:  event.OccurredAt,
		ReceivedAt:  event.ReceivedAt,
		Fingerprint: event.Fingerprint,
		Payload:     datatypes.JSON(buffer),
		DedupStatus: string(event.DedupStatus),
	}, nil
}

type triggerModel struct {
	ID        uuid.UUID      `gorm:"column:id;type:uuid;primaryKey"`
	EventID   uuid.UUID      `gorm:"column:event_id"`
	AreaID    uuid.UUID      `gorm:"column:area_id"`
	Status    string         `gorm:"column:status"`
	MatchInfo datatypes.JSON `gorm:"column:match_info"`
	CreatedAt time.Time      `gorm:"column:created_at"`
	UpdatedAt time.Time      `gorm:"column:updated_at"`
}

func (triggerModel) TableName() string { return "triggers" }

func (m triggerModel) toDomain() actiondomain.Trigger {
	matchInfo := map[string]any{}
	if len(m.MatchInfo) > 0 {
		_ = json.Unmarshal(m.MatchInfo, &matchInfo)
	}
	return actiondomain.Trigger{
		ID:        m.ID,
		EventID:   m.EventID,
		AreaID:    m.AreaID,
		Status:    actiondomain.TriggerStatus(m.Status),
		MatchInfo: matchInfo,
		CreatedAt: m.CreatedAt,
		UpdatedAt: m.UpdatedAt,
	}
}

func triggerFromDomain(trigger actiondomain.Trigger) (triggerModel, error) {
	matchInfo := trigger.MatchInfo
	if matchInfo == nil {
		matchInfo = map[string]any{}
	}
	buffer, err := json.Marshal(matchInfo)
	if err != nil {
		return triggerModel{}, err
	}
	return triggerModel{
		ID:        trigger.ID,
		EventID:   trigger.EventID,
		AreaID:    trigger.AreaID,
		Status:    string(trigger.Status),
		MatchInfo: datatypes.JSON(buffer),
		CreatedAt: trigger.CreatedAt,
		UpdatedAt: trigger.UpdatedAt,
	}, nil
}

type jobModel struct {
	ID            uuid.UUID      `gorm:"column:id;type:uuid;primaryKey"`
	TriggerID     uuid.UUID      `gorm:"column:trigger_id"`
	AreaLinkID    uuid.UUID      `gorm:"column:area_link_id"`
	Status        string         `gorm:"column:status"`
	Attempt       int            `gorm:"column:attempt"`
	RunAt         time.Time      `gorm:"column:run_at"`
	LockedBy      *string        `gorm:"column:locked_by"`
	LockedAt      *time.Time     `gorm:"column:locked_at"`
	InputPayload  datatypes.JSON `gorm:"column:input_payload"`
	ResultPayload datatypes.JSON `gorm:"column:result_payload"`
	Error         *string        `gorm:"column:error"`
	CreatedAt     time.Time      `gorm:"column:created_at"`
	UpdatedAt     time.Time      `gorm:"column:updated_at"`
}

func (jobModel) TableName() string { return "jobs" }

func (m jobModel) toDomain() jobdomain.Job {
	input := map[string]any{}
	if len(m.InputPayload) > 0 {
		_ = json.Unmarshal(m.InputPayload, &input)
	}

	result := map[string]any{}
	if len(m.ResultPayload) > 0 {
		_ = json.Unmarshal(m.ResultPayload, &result)
	}

	return jobdomain.Job{
		ID:            m.ID,
		TriggerID:     m.TriggerID,
		AreaLinkID:    m.AreaLinkID,
		Status:        jobdomain.Status(m.Status),
		Attempt:       m.Attempt,
		RunAt:         m.RunAt,
		LockedBy:      m.LockedBy,
		LockedAt:      m.LockedAt,
		InputPayload:  input,
		ResultPayload: result,
		Error:         m.Error,
		CreatedAt:     m.CreatedAt,
		UpdatedAt:     m.UpdatedAt,
	}
}

func jobFromDomain(job jobdomain.Job) (jobModel, error) {
	input := job.InputPayload
	if input == nil {
		input = map[string]any{}
	}
	inputBuf, err := json.Marshal(input)
	if err != nil {
		return jobModel{}, err
	}

	result := job.ResultPayload
	if result == nil {
		result = map[string]any{}
	}
	resultBuf, err := json.Marshal(result)
	if err != nil {
		return jobModel{}, err
	}

	return jobModel{
		ID:            job.ID,
		TriggerID:     job.TriggerID,
		AreaLinkID:    job.AreaLinkID,
		Status:        string(job.Status),
		Attempt:       job.Attempt,
		RunAt:         job.RunAt.UTC(),
		LockedBy:      job.LockedBy,
		LockedAt:      job.LockedAt,
		InputPayload:  datatypes.JSON(inputBuf),
		ResultPayload: datatypes.JSON(resultBuf),
		Error:         job.Error,
		CreatedAt:     job.CreatedAt,
		UpdatedAt:     job.UpdatedAt,
	}, nil
}

type deliveryLogModel struct {
	ID         uuid.UUID      `gorm:"column:id;type:uuid;primaryKey"`
	JobID      uuid.UUID      `gorm:"column:job_id"`
	Endpoint   string         `gorm:"column:endpoint"`
	Request    datatypes.JSON `gorm:"column:request"`
	Response   datatypes.JSON `gorm:"column:response"`
	StatusCode *int           `gorm:"column:status_code"`
	DurationMS *int           `gorm:"column:duration_ms"`
	CreatedAt  time.Time      `gorm:"column:created_at"`
}

func (deliveryLogModel) TableName() string { return "delivery_logs" }

func (m deliveryLogModel) toDomain() jobdomain.DeliveryLog {
	request := map[string]any{}
	if len(m.Request) > 0 {
		_ = json.Unmarshal(m.Request, &request)
	}
	response := map[string]any{}
	if len(m.Response) > 0 {
		_ = json.Unmarshal(m.Response, &response)
	}
	return jobdomain.DeliveryLog{
		ID:         m.ID,
		JobID:      m.JobID,
		Endpoint:   m.Endpoint,
		Request:    request,
		Response:   response,
		StatusCode: m.StatusCode,
		DurationMS: m.DurationMS,
		CreatedAt:  m.CreatedAt,
	}
}

func deliveryLogFromDomain(log jobdomain.DeliveryLog) (deliveryLogModel, error) {
	request := log.Request
	if request == nil {
		request = map[string]any{}
	}
	requestBuf, err := json.Marshal(request)
	if err != nil {
		return deliveryLogModel{}, err
	}

	response := log.Response
	if response == nil {
		response = map[string]any{}
	}
	responseBuf, err := json.Marshal(response)
	if err != nil {
		return deliveryLogModel{}, err
	}

	return deliveryLogModel{
		ID:         log.ID,
		JobID:      log.JobID,
		Endpoint:   log.Endpoint,
		Request:    datatypes.JSON(requestBuf),
		Response:   datatypes.JSON(responseBuf),
		StatusCode: log.StatusCode,
		DurationMS: log.DurationMS,
		CreatedAt:  log.CreatedAt,
	}, nil
}
