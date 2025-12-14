package main

import (
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"typemon/internal/generator"

	"github.com/spf13/cobra"
)

const (
	defaultConfigPath = "default"
)

var (
	configName string
)

func main() {
	rootCmd := &cobra.Command{
		Use:   "typemon",
		Short: "typemon: parametric model generator for ergonomic keyboards",
	}

	// Global flags
	rootCmd.PersistentFlags().StringVarP(&configName, "config", "c", defaultConfigPath, "YAML config file name (without extension)")

	// Команда generate
	genCmd := &cobra.Command{
		Use:   "generate",
		Short: "Generate OpenSCAD model from config",
		RunE:  runGenerate,
	}

	// Команда render
	renderCmd := &cobra.Command{
		Use:   "render",
		Short: "Generate OpenSCAD model and STEP files (stub)",
		RunE:  runRender,
	}

	clearArtefactsCmd := &cobra.Command{
		Use:   "clear-artefacts",
		Short: "Clear artefacts from the project",
		RunE:  runClearArtefacts,
	}

	rootCmd.AddCommand(genCmd, renderCmd, clearArtefactsCmd)

	if err := rootCmd.Execute(); err != nil {
		log.Fatalf("command failed: %v", err)
	}
}

func runGenerate(cmd *cobra.Command, args []string) error {
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

func runRender(cmd *cobra.Command, args []string) error {
	return nil
}

func runClearArtefacts(cmd *cobra.Command, args []string) error {
	// delete all *.g.scad files in the scad directory
	scadDir := generator.OutDir
	files, err := os.ReadDir(scadDir)
	if err != nil {
		return errors.Join(errors.New("read scad directory"), err)
	}
	for _, file := range files {
		if strings.HasSuffix(file.Name(), generator.GeneratedOutExtension()) {
			err = os.Remove(filepath.Join(scadDir, file.Name()))
			if err != nil {
				return errors.Join(errors.New("remove scad file"), err)
			}
		}
	}
	// delete all *.g.step files in the models directory
	modelsDir := generator.RenderDir
	files, err = os.ReadDir(modelsDir)
	if err != nil {
		return errors.Join(errors.New("read models directory"), err)
	}
	for _, file := range files {
		if strings.HasSuffix(file.Name(), generator.GeneratedRenderExtension()) {
			err = os.Remove(filepath.Join(modelsDir, file.Name()))
			if err != nil {
				return errors.Join(errors.New("remove model file"), err)
			}
		}
	}
	return nil
}
