package main

import (
	"fmt"
	"os"

	configviper "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/config/viper"
)

func main() {
	cfg, err := configviper.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to load configuration: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("configuration loaded for environment %s on %s:%d\n", cfg.App.Environment, cfg.HTTP.Host, cfg.HTTP.Port)
}
