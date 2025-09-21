package migrate

import (
    "context"

    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
)

// Run ensures MongoDB collections and indexes exist.
// Currently, it ensures a unique index on users.email.
func Run(ctx context.Context, db *mongo.Database) error {
    users := db.Collection("users")
    _, err := users.Indexes().CreateOne(ctx, mongo.IndexModel{
        Keys:    bson.D{{Key: "email", Value: 1}},
        Options: options.Index().SetUnique(true).SetName("uniq_email"),
    })
    if err != nil {
        // If index exists, driver may return an error; ignore duplicates
        // by checking command error code 85 (IndexKeySpecsConflict) or 11000-like
        // but CreateOne typically upserts by name; if it fails, surface error.
        return err
    }
    return nil
}
