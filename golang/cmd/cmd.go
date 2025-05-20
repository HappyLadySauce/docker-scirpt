package cmd

import (
	"github.com/spf13/cobra"
	"github.com/HappyLadySauce/docker-script/cmd/args/version"
	"fmt"
)

func NewDockerScriptCommand() *cobra.Command{
	cmd := &cobra.Command {
		Use: "docker-script",
		Short: "A command to modify Docker scripts",
		Long: "A Fast and Convenient to modify Docker scripts",
		RunE: func(_ *cobra.Command, _ []string) error {
			fmt.Println("run docker script.")
			return nil
		},
		Args: func(cmd *cobra.Command, args []string) error {
			if len(args) < 1 {
				return fmt.Errorf("requires at least one argument")
			}
			return nil
		},
	}
	cmd.AddCommand(version.VersionCmd)
	return cmd
}
