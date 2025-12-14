package generator

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"typemon/internal/config"
)

type switchRepository struct {
	modules map[string]*config.SwitchModuleDefinition
}

const (
	switchModulesConfigDir = "configs/switches"
	switchModulesDir       = "modules/switches"
	switchModulesExtension = ".scad"
)

func loadSwitchRepository() (*switchRepository, error) {
	modules, err := config.LoadSwitchModules(switchModulesConfigDir)
	if err != nil {
		return nil, errors.Join(errors.New("failed to load switch modules"), err)
	}
	repo := &switchRepository{modules: make(map[string]*config.SwitchModuleDefinition)}
	for name, module := range modules {
		err = repo.AddModule(name, module)
		if err != nil {
			fmt.Println("failed to add switch module: " + err.Error())
		}
	}
	return repo, nil
}

func (r *switchRepository) GetModule(name string) (*config.SwitchModuleDefinition, error) {
	module, ok := r.modules[name]
	if !ok {
		return nil, errors.Join(errors.New("switch module not found"), errors.New("switch module name: "+name))
	}
	return module, nil
}
func (r *switchRepository) AddModule(name string, module *config.SwitchModuleDefinition) error {
	if r.modules[name] != nil {
		return errors.Join(errors.New("switch module already exists"), errors.New("switch module name: "+name))
	}
	// check if module is valid
	if module.Filename == "" || module.Module == "" {
		return errors.Join(errors.New("invalid switch module"), errors.New("switch module name: "+name))
	}
	// check that filename exists
	path := filepath.Join(OutDir, switchModulesDir, module.Filename)
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return errors.Join(errors.New("switch module file not found: "+path), errors.New("switch module name: "+name))
	}
	r.modules[name] = module
	return nil
}

func OverrideModule(module *config.SwitchModuleDefinition, extraArgs map[string]interface{}) (*config.SwitchModuleDefinition, error) {
	newModule := &config.SwitchModuleDefinition{
		Filename:      module.Filename,
		Module:        module.Module,
		MinKeycapSize: module.MinKeycapSize,
		ExtraArgs:     make(map[string]interface{}),
	}
	for key, value := range extraArgs {
		if _, ok := module.ExtraArgs[key]; !ok {
			return nil, errors.New("extra argument not found in module: " + key)
		}
		newModule.ExtraArgs[key] = value
	}
	// copy over extra args that are not overridden
	for key, value := range module.ExtraArgs {
		if _, ok := newModule.ExtraArgs[key]; !ok {
			newModule.ExtraArgs[key] = value
		}
	}
	return newModule, nil
}
