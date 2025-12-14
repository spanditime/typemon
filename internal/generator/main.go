package generator

import (
	"errors"
	"os"
	"path/filepath"
	"text/template"
	"typemon/internal/config"

	_ "embed"
)

type generator struct {
	config   *config.Config
	name     string
	switches *switchRepository
}

const (
	configDir       = "configs"
	configExtension = ".yml"
	OutDir          = "scad"
	outExtension    = ".scad"
	RenderDir       = "models"
	renderExtension = ".stl"

	outConfigExtension = ".config"
	outRightExtension  = ".right"
	outLeftExtension   = ".left"
	outBottomExtension = ".bottom"

	generatedExtension = ".g"
)

func GeneratedOutExtension() string {
	return generatedExtension + outExtension
}
func GeneratedRenderExtension() string {
	return generatedExtension + renderExtension
}

func GeneratedOutConfigFilename(configName string) string {
	return configName + outConfigExtension + GeneratedOutExtension()
}

func ConfigPath(configFilename string) string {
	return filepath.Join(configDir, configFilename+configExtension)
}

func New(configFilename string) (*generator, error) {
	path := ConfigPath(configFilename)
	config, err := config.Load(path)
	if err != nil {
		return nil, errors.Join(errors.New("failed to load config"), err)
	}
	switches, err := loadSwitchRepository()
	if err != nil {
		return nil, errors.Join(errors.New("failed to load switches"), err)
	}
	return &generator{
		name:     configFilename,
		config:   config,
		switches: switches,
	}, nil
}

func (g *generator) Generate() error {
	err := g.generateConfigFile()
	if err != nil {
		return errors.Join(errors.New("failed to generate config file"), err)
	}
	err = g.generateLeftFile()
	if err != nil {
		return errors.Join(errors.New("failed to generate left file"), err)
	}
	err = g.generateRightFile()
	if err != nil {
		return errors.Join(errors.New("failed to generate right file"), err)
	}
	// g.generateBottomFile()
	return nil
}

//go:embed templates/config.scad.tmpl
var configTemplate string

//go:embed templates/left.scad.tmpl
var leftTemplate string

//go:embed templates/right.scad.tmpl
var rightTemplate string

func (g *generator) generateConfigFile() error {
	// generate config scad file from template
	tmpl, err := template.New("config").Funcs(funcMap).Parse(configTemplate)
	if err != nil {
		return errors.Join(errors.New("failed to parse config template"), err)
	}

	path := filepath.Join(OutDir, GeneratedOutConfigFilename(g.name))
	file, err := os.Create(path)
	if err != nil {
		return errors.Join(errors.New("failed to create config file"), err)
	}
	defer file.Close()
	data, err := newTemplateData(g.config, g.switches)
	if err != nil {
		return errors.Join(errors.New("failed to create template data"), err)
	}
	err = tmpl.Execute(file, data)
	if err != nil {
		return errors.Join(errors.New("failed to execute config template"), err)
	}
	return nil
}

func (g *generator) generateLeftFile() error {
	tmpl, err := template.New("left").Parse(leftTemplate)
	if err != nil {
		return errors.Join(errors.New("failed to parse left template"), err)
	}
	path := filepath.Join(OutDir, g.name+outLeftExtension+GeneratedOutExtension())
	file, err := os.Create(path)
	if err != nil {
		return errors.Join(errors.New("failed to create left file"), err)
	}
	defer file.Close()
	err = tmpl.Execute(file, GeneratedOutConfigFilename(g.name))
	if err != nil {
		return errors.Join(errors.New("failed to execute left template"), err)
	}
	return nil
}

func (g *generator) generateRightFile() error {
	tmpl, err := template.New("right").Parse(rightTemplate)
	if err != nil {
		return errors.Join(errors.New("failed to parse right template"), err)
	}
	path := filepath.Join(OutDir, g.name+outRightExtension+GeneratedOutExtension())
	file, err := os.Create(path)
	if err != nil {
		return errors.Join(errors.New("failed to create right file"), err)
	}
	defer file.Close()
	err = tmpl.Execute(file, GeneratedOutConfigFilename(g.name))
	if err != nil {
		return errors.Join(errors.New("failed to execute right template"), err)
	}
	return nil
}

func (g *generator) Render() error {
	return nil
}
