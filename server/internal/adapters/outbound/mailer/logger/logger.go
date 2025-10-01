package logger

import (
	"context"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"go.uber.org/zap"
)

// Mailer logs outbound emails for debugging or local development
// It is suitable for sandbox environments where external providers are unavailable
type Mailer struct {
	Logger *zap.Logger
}

// Send satisfies the outbound.Mailer interface by logging the payload
func (m Mailer) Send(ctx context.Context, msg outbound.Mail) error {
	if m.Logger == nil {
		return nil
	}
	m.Logger.Info("sending email", zap.String("to", msg.To), zap.String("subject", msg.Subject))
	return nil
}
