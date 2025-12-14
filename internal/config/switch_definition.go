package config

import (
	"errors"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

type SwitchModuleDefinition struct {
	Filename      string                 `yaml:"filename"`
	Module        string                 `yaml:"module"`
	MinKeycapSize MinKeycapSize          `yaml:"min_keycap_size,omitempty"`
	ExtraArgs     map[string]interface{} `yaml:"extra_args,omitempty"`
}

type MinKeycapSize struct {
	Width  float64 `yaml:"width,omitempty"`
	Height float64 `yaml:"height,omitempty"`
	Depth  float64 `yaml:"depth,omitempty"`
}

func LoadSwitchModules(path string) (map[string]*SwitchModuleDefinition, error) {
	files, err := os.ReadDir(path)
	if err != nil {
		return nil, errors.Join(errors.New("failed to read switch modules directory: "+path), err)
	}
	modules := make(map[string]*SwitchModuleDefinition)
	for _, file := range files {
		if file.IsDir() {
			continue
		}
		if filepath.Ext(file.Name()) != ".yml" {
			continue
		}
		module, err := LoadSwitchModule(filepath.Join(path, file.Name()))
		if err != nil {
			return nil, errors.Join(errors.New("failed to load switch module"), err)
		}
		name := filepath.Base(file.Name())
		modules[strings.TrimSuffix(name, filepath.Ext(name))] = &module
	}
	return modules, nil
}

func LoadSwitchModule(path string) (SwitchModuleDefinition, error) {
	module := SwitchModuleDefinition{}
	data, err := os.ReadFile(path)
	if err != nil {
		return SwitchModuleDefinition{}, errors.Join(errors.New("failed to read switch module file"), err)
	}
	err = yaml.Unmarshal(data, &module)
	if err != nil {
		return SwitchModuleDefinition{}, errors.Join(errors.New("failed to unmarshal switch module"), err)
	}
	return module, nil
}
