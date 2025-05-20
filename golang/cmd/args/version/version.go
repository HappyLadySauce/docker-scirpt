package version

import (
	"fmt"
	"github.com/spf13/cobra"
)

var VersionCmd = &cobra.Command {
	Use: "version",
	Short: "Display the current version",
	Long: "This command shows the current version of the application.",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Current version: 1.0.0")
	},
}