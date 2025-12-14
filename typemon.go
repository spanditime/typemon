package main

import (
	"log"
	"os"
	"typemon/cmd"
)

func main() {
	err := cmd.Execute()
	if err != nil {
		log.Fatalf("command failed")
	}
	os.Exit(0)
}
