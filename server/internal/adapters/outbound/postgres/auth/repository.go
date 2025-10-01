package auth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	authdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/auth"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository groups Postgres-backed persistence adapters for authentication concerns
type Repository struct {
	db *gorm.DB
}

// NewRepository returns a Repository backed by the provided gorm handle
func NewRepository(db *gorm.DB) Repository {
	return Repository{db: db}
}

// DB exposes the underlying gorm handle
func (r Repository) DB() *gorm.DB {
	return r.db
}

func (r Repository) withContext(ctx context.Context) *gorm.DB {
	return r.db.WithContext(ctx)
}

// Users returns a UserRepository implementation
func (r Repository) Users() outbound.UserRepository {
	return userRepo{db: r.db}
}

// Sessions returns a SessionRepository implementation
func (r Repository) Sessions() outbound.SessionRepository {
	return sessionRepo{db: r.db}
}

// VerificationTokens returns a VerificationTokenRepository implementation
func (r Repository) VerificationTokens() outbound.VerificationTokenRepository {
	return verificationTokenRepo{db: r.db}
}

type userRepo struct {
	db *gorm.DB
}

func (r userRepo) Create(ctx context.Context, userModelDomain userdomain.User) (userdomain.User, error) {
	model := userFromDomain(userModelDomain)
	if model.ID == uuid.Nil {
		model.ID = uuid.New()
	}
	if err := r.db.WithContext(ctx).Create(&model).Error; err != nil {
		if isUniqueViolation(err) {
			return userdomain.User{}, outbound.ErrConflict
		}
		return userdomain.User{}, fmt.Errorf("postgres.auth.userRepo.Create: %w", err)
	}
	return model.toDomain(), nil
}

func (r userRepo) FindByEmail(ctx context.Context, email string) (userdomain.User, error) {
	if email == "" {
		return userdomain.User{}, outbound.ErrNotFound
	}
	var model userModel
	err := r.db.WithContext(ctx).
		Where("lower(email) = ?", strings.ToLower(email)).
		Take(&model).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return userdomain.User{}, outbound.ErrNotFound
		}
		return userdomain.User{}, fmt.Errorf("postgres.auth.userRepo.FindByEmail: %w", err)
	}
	return model.toDomain(), nil
}

func (r userRepo) FindByID(ctx context.Context, id uuid.UUID) (userdomain.User, error) {
	var model userModel
	if err := r.db.WithContext(ctx).First(&model, "id = ?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return userdomain.User{}, outbound.ErrNotFound
		}
		return userdomain.User{}, fmt.Errorf("postgres.auth.userRepo.FindByID: %w", err)
	}
	return model.toDomain(), nil
}

func (r userRepo) Update(ctx context.Context, user userdomain.User) error {
	model := userFromDomain(user)
	if model.ID == uuid.Nil {
		return fmt.Errorf("postgres.auth.userRepo.Update: missing id")
	}
	if err := r.db.WithContext(ctx).Model(&model).
		Where("id = ?", model.ID).
		Updates(map[string]any{
			"email":         model.Email,
			"password_hash": model.PasswordHash,
			"status":        model.Status,
			"last_login_at": model.LastLoginAt,
			"updated_at":    model.UpdatedAt,
		}).Error; err != nil {
		if isUniqueViolation(err) {
			return outbound.ErrConflict
		}
		return fmt.Errorf("postgres.auth.userRepo.Update: %w", err)
	}
	return nil
}

type sessionRepo struct {
	db *gorm.DB
}

func (r sessionRepo) Create(ctx context.Context, session sessiondomain.Session) (sessiondomain.Session, error) {
	model := sessionFromDomain(session)
	if model.ID == uuid.Nil {
		model.ID = uuid.New()
	}
	if err := r.db.WithContext(ctx).Create(&model).Error; err != nil {
		return sessiondomain.Session{}, fmt.Errorf("postgres.auth.sessionRepo.Create: %w", err)
	}
	return model.toDomain(), nil
}

func (r sessionRepo) FindByID(ctx context.Context, id uuid.UUID) (sessiondomain.Session, error) {
	var model sessionModel
	if err := r.db.WithContext(ctx).First(&model, "id = ?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return sessiondomain.Session{}, outbound.ErrNotFound
		}
		return sessiondomain.Session{}, fmt.Errorf("postgres.auth.sessionRepo.FindByID: %w", err)
	}
	return model.toDomain(), nil
}

func (r sessionRepo) Delete(ctx context.Context, id uuid.UUID) error {
	if err := r.db.WithContext(ctx).Delete(&sessionModel{}, "id = ?", id).Error; err != nil {
		return fmt.Errorf("postgres.auth.sessionRepo.Delete: %w", err)
	}
	return nil
}

func (r sessionRepo) DeleteByUser(ctx context.Context, userID uuid.UUID) error {
	if err := r.db.WithContext(ctx).Delete(&sessionModel{}, "user_id = ?", userID).Error; err != nil {
		return fmt.Errorf("postgres.auth.sessionRepo.DeleteByUser: %w", err)
	}
	return nil
}

type verificationTokenRepo struct {
	db *gorm.DB
}

func (r verificationTokenRepo) Create(ctx context.Context, token authdomain.VerificationToken) (authdomain.VerificationToken, error) {
	model := verificationTokenFromDomain(token)
	if model.ID == uuid.Nil {
		model.ID = uuid.New()
	}
	if err := r.db.WithContext(ctx).Create(&model).Error; err != nil {
		return authdomain.VerificationToken{}, fmt.Errorf("postgres.auth.verificationTokenRepo.Create: %w", err)
	}
	return model.toDomain(), nil
}

func (r verificationTokenRepo) FindByToken(ctx context.Context, token string) (authdomain.VerificationToken, error) {
	var model verificationTokenModel
	if err := r.db.WithContext(ctx).First(&model, "token = ?", token).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return authdomain.VerificationToken{}, outbound.ErrNotFound
		}
		return authdomain.VerificationToken{}, fmt.Errorf("postgres.auth.verificationTokenRepo.FindByToken: %w", err)
	}
	return model.toDomain(), nil
}

func (r verificationTokenRepo) MarkConsumed(ctx context.Context, tokenID uuid.UUID, consumedAt int64) error {
	consumed := time.Unix(consumedAt, 0).UTC()
	if err := r.db.WithContext(ctx).
		Model(&verificationTokenModel{}).
		Where("id = ?", tokenID).
		Updates(map[string]any{
			"consumed_at": consumed,
		}).Error; err != nil {
		return fmt.Errorf("postgres.auth.verificationTokenRepo.MarkConsumed: %w", err)
	}
	return nil
}

func (r verificationTokenRepo) DeleteByUser(ctx context.Context, userID uuid.UUID) error {
	if err := r.db.WithContext(ctx).Delete(&verificationTokenModel{}, "user_id = ?", userID).Error; err != nil {
		return fmt.Errorf("postgres.auth.verificationTokenRepo.DeleteByUser: %w", err)
	}
	return nil
}

func isUniqueViolation(err error) bool {
	return err != nil && strings.Contains(strings.ToLower(err.Error()), "duplicate")
}
