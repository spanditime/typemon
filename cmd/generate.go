package cmd

import (
	"errors"
	"fmt"
	"typemon/internal/generator"

	"github.com/fsnotify/fsnotify"
	"github.com/spf13/cobra"
)

var (
	watchMode bool
)

// Команда generate
var genCmd = &cobra.Command{
	Use:   "generate",
	Short: "Generate OpenSCAD model from config",
	RunE:  runGenerate,
}

func init() {
	genCmd.Flags().BoolVarP(&watchMode, "watch", "w", false, "Watch for changes and regenerate in real time")
}

func runGenerate(cmd *cobra.Command, args []string) error {
	if watchMode {
		watcher, err := fsnotify.NewWatcher()
		if err != nil {
			return errors.Join(errors.New("failed to create watcher"), err)
		}
		defer watcher.Close()
		watcher.Add(generator.ConfigPath(configName))
		watcher.Add(generator.SwitchModulesConfigDir)
		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return errors.New("watcher closed")
				}
				if event.Op&fsnotify.Write == fsnotify.Write {
					err = runGenerator()
					if err != nil {
						fmt.Println("failed to generate: " + err.Error())
					}
				}
			}
		}
	} else {
		return runGenerator()
	}
}

func runGenerator() error {
	generator, err := generator.New(configName)
	if err != nil {
		return errors.Join(errors.New("failed to create generator"), err)
	}
	err = generator.Generate()
	if err != nil {
		return errors.Join(errors.New("failed to generate"), err)
	}
	fmt.Println("generated successfully")
	return nil
}
