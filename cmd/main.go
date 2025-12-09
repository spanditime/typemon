package main

import (
	"fmt"
	"log"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"

	"typemon/internal/config"
)

const (
	defaultConfigPath = "configs/default.yml"
	defaultPart       = "full"
)

var (
	cfgPath string
	part    string
	scadOut string
	stepOut string
)

func main() {
	rootCmd := &cobra.Command{
		Use:   "typemon",
		Short: "typemon: parametric model generator for ergonomic keyboards",
	}

	// Global flags
	rootCmd.PersistentFlags().StringVarP(&cfgPath, "config", "c", defaultConfigPath, "path to YAML config file")
	rootCmd.PersistentFlags().StringVar(&part, "part", defaultPart, "keyboard part to generate (e.g. left, right, full)")

	// Команда generate
	genCmd := &cobra.Command{
		Use:   "generate",
		Short: "Generate OpenSCAD model from config",
		RunE:  runGenerate,
	}
	genCmd.Flags().StringVarP(&scadOut, "scad", "s", "", "output SCAD file path (default: scad/<config>.<part>.scad)")

	// Команда render
	renderCmd := &cobra.Command{
		Use:   "render",
		Short: "Generate OpenSCAD model and STEP files (stub)",
		RunE:  runRender,
	}
	renderCmd.Flags().StringVarP(&scadOut, "scad", "s", "", "output SCAD file path (default: scad/<config>.<part>.scad)")
	renderCmd.Flags().StringVarP(&stepOut, "out", "o", "", "output STEP file path (default: models/<config>.<part>.step)")

	rootCmd.AddCommand(genCmd, renderCmd)

	if err := rootCmd.Execute(); err != nil {
		log.Fatalf("command failed: %v", err)
	}
}

func runGenerate(cmd *cobra.Command, args []string) error {
	cfgFile := cfgPath
	if cfgFile == "" {
		cfgFile = defaultConfigPath
	}

	if part == "" {
		part = defaultPart
	}

	if scadOut == "" {
		scadOut = defaultScadPath(cfgFile, part)
	}

	_, err := config.Load(cfgFile)
	if err != nil {
		return fmt.Errorf("load config: %w", err)
	}

	// TODO: реализовать генерацию SCAD-файла на основе шаблонов и конфигурации.
	fmt.Printf("generate: config=%s part=%s scad=%s (generation not implemented yet)\n", cfgFile, part, scadOut)
	return nil
}

func runRender(cmd *cobra.Command, args []string) error {
	cfgFile := cfgPath
	if cfgFile == "" {
		cfgFile = defaultConfigPath
	}

	if part == "" {
		part = defaultPart
	}

	if scadOut == "" {
		scadOut = defaultScadPath(cfgFile, part)
	}
	if stepOut == "" {
		stepOut = defaultStepPath(cfgFile, part)
	}

	_, err := config.Load(cfgFile)
	if err != nil {
		return fmt.Errorf("load config: %w", err)
	}
	fmt.Printf("cfgFile: %s\n", cfgFile)
	fmt.Printf("part: %s\n", part)
	fmt.Printf("scadOut: %s\n", scadOut)
	fmt.Printf("stepOut: %s\n", stepOut)

	// TODO: реализовать генерацию SCAD и STEP-файлов.
	fmt.Printf("render: config=%s part=%s scad=%s out=%s (render not implemented yet)\n", cfgFile, part, scadOut, stepOut)
	return nil
}

func defaultScadPath(cfgFile, part string) string {
	base := strings.TrimSuffix(filepath.Base(cfgFile), filepath.Ext(cfgFile))
	return filepath.Join("scad", fmt.Sprintf("%s.%s.scad", base, part))
}

func defaultStepPath(cfgFile, part string) string {
	base := strings.TrimSuffix(filepath.Base(cfgFile), filepath.Ext(cfgFile))
	return filepath.Join("models", fmt.Sprintf("%s.%s.step", base, part))
}
