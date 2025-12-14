package cmd

import (
	"github.com/spf13/cobra"
)

const (
	defaultConfigPath = "default"
)

var (
	configName string
)

var rootCmd = &cobra.Command{
	Use:   "typemon",
	Short: "typemon: parametric model generator for ergonomic keyboards",
}

func init() {

	// Global flags
	rootCmd.PersistentFlags().StringVarP(&configName, "config", "c", defaultConfigPath, "YAML config file name (without extension)")

	rootCmd.AddCommand(genCmd, renderCmd, clearArtefactsCmd)
}

func Execute() error {
	return rootCmd.Execute()
}
