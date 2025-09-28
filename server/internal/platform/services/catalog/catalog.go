package catalog

// Catalog lists the automation services available to AREA clients
type Catalog struct {
	Services []Service `yaml:"services"`
}

// Service describes a third-party integration with associated actions and reactions
type Service struct {
	Name      string      `yaml:"name"`
	Actions   []Component `yaml:"actions"`
	Reactions []Component `yaml:"reactions"`
}

// Component represents an actionable or reactive capability provided by a service
type Component struct {
	Name        string `yaml:"name"`
	Description string `yaml:"description"`
}

// Empty reports whether the catalog is empty
func (c Catalog) Empty() bool {
	return len(c.Services) == 0
}
