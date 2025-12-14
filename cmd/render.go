package cmd

import "github.com/spf13/cobra"

// Команда render
var renderCmd = &cobra.Command{
	Use:   "render",
	Short: "Generate OpenSCAD model and STEP files (stub)",
	RunE:  runRender,
}

func runRender(cmd *cobra.Command, args []string) error {
	return nil
}
