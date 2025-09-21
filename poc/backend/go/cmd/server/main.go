package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/joho/godotenv"

    "github.com/epitech/area-poc/backend/go/internal/config"
    "github.com/epitech/area-poc/backend/go/internal/db"
    "github.com/epitech/area-poc/backend/go/internal/handlers"
    "github.com/epitech/area-poc/backend/go/internal/migrate"
)

func main() {
	_ = godotenv.Load()

    cfg := config.Load()

    client, database, err := db.Connect(context.Background(), cfg.MongoURI, cfg.MongoDB)
    if err != nil {
        log.Fatalf("db connect: %v", err)
    }
    defer client.Disconnect(context.Background())

    if err := migrate.Run(context.Background(), database); err != nil {
        log.Fatalf("migrations: %v", err)
    }

    h := handlers.New(database, cfg)
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      h.Routes(),
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	go func() {
		log.Printf("listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = srv.Shutdown(ctx)
}
