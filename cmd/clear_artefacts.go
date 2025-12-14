package cmd

import (
	"errors"
	"log"
	"os"
	"path/filepath"
	"strings"
	"typemon/internal/generator"

	"github.com/spf13/cobra"
)

var clearArtefactsCmd = &cobra.Command{
	Use:   "clear-artefacts",
	Short: "Clear artefacts from the project",
	RunE:  runClearArtefacts,
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
	if err != nil && os.IsNotExist(err) {
		log.Println("models directory not found, skipping")
		return nil
	} else if err != nil {
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
