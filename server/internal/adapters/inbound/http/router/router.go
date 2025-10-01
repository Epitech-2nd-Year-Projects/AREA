package router

import (
	aboutapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/about"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/services/catalog"
	"github.com/gin-gonic/gin"
)

// Dependencies aggregates inbound HTTP dependencies
type Dependencies struct {
	AboutLoader catalog.Loader
	Clock       aboutapp.Clock
}

// Register mounts all HTTP endpoints on the provided router
func Register(r gin.IRouter, deps Dependencies) error {
	if deps.AboutLoader == nil {
		deps.AboutLoader = catalog.EmptyLoader{}
	}
	if deps.Clock == nil {
		deps.Clock = aboutapp.SystemClock{}
	}

	aboutHandler := aboutapp.New(deps.AboutLoader, deps.Clock)
	aboutHandler.Register(r)

	return nil
}
