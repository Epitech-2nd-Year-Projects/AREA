package sendgrid

import (
	"context"
	"fmt"
	"strings"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	sg "github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/sendgrid-go/helpers/mail"
)

// Mailer delivers transactional emails using SendGrid's v3 API
// Requires a valid API key and sender address configured upstream
type Mailer struct {
	APIKey    string
	FromEmail string
	FromName  string
	Sandbox   bool
}

// Send implements outbound.Mailer using SendGrid's REST API
func (m Mailer) Send(ctx context.Context, msg outbound.Mail) error {
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("sendgrid.Mailer.Send: context cancelled: %w", err)
	}
	if strings.TrimSpace(m.APIKey) == "" {
		return fmt.Errorf("sendgrid.Mailer.Send: api key is empty")
	}
	if strings.TrimSpace(m.FromEmail) == "" {
		return fmt.Errorf("sendgrid.Mailer.Send: from email is empty")
	}
	if strings.TrimSpace(msg.To) == "" {
		return fmt.Errorf("sendgrid.Mailer.Send: recipient is empty")
	}

	sender := mail.NewEmail(m.FromName, m.FromEmail)
	recipient := mail.NewEmail("", msg.To)
	email := mail.NewSingleEmail(sender, msg.Subject, recipient, msg.Text, msg.HTML)

	if m.Sandbox {
		enabled := true
		email.MailSettings = &mail.MailSettings{SandboxMode: &mail.Setting{Enable: &enabled}}
	}

	req := sg.GetRequest(m.APIKey, "/v3/mail/send", "https://api.sendgrid.com")
	req.Method = "POST"
	req.Body = mail.GetRequestBody(email)

	if err := ctx.Err(); err != nil {
		return fmt.Errorf("sendgrid.Mailer.Send: context cancelled: %w", err)
	}

	_, err := sg.API(req)
	if err != nil {
		return fmt.Errorf("sendgrid.Mailer.Send: sendgrid.API: %w", err)
	}
	return nil
}
