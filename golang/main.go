package main

import (
	"github.com/HappyLadySauce/docker-script/cmd"
	"fmt"
)

func main() {
	cmd := cmd.NewDockerScriptCommand()
	if err := cmd.Execute(); err != nil {
		fmt.Println(err)
	}
}