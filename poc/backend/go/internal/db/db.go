package db

import (
    "context"
    "time"

    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
)

// Connect creates a MongoDB client and returns the database handle.
// The caller is responsible for calling client.Disconnect when shutting down.
func Connect(ctx context.Context, uri, dbName string) (*mongo.Client, *mongo.Database, error) {
    client, err := mongo.NewClient(options.Client().ApplyURI(uri))
    if err != nil {
        return nil, nil, err
    }
    // Use a short timeout for initial connection
    cctx, cancel := context.WithTimeout(ctx, 10*time.Second)
    defer cancel()
    if err := client.Connect(cctx); err != nil {
        return nil, nil, err
    }
    // Ping to verify connectivity
    if err := client.Ping(cctx, nil); err != nil {
        _ = client.Disconnect(context.Background())
        return nil, nil, err
    }
    return client, client.Database(dbName), nil
}
