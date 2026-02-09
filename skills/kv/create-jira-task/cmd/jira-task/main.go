// jira-task manages Jira internal tasks and sprints.
//
// NOTE FOR AI AGENTS: Never create test issues to verify this tool works.
// Only create issues when the user explicitly requests a real task.
// You MAY run the "sprints" subcommand for sanity checks since it has no side effects.
package main

import (
	"os"

	"github.com/spf13/cobra"
)

const envHelp = `
Environment variables:
  export JIRA_EMAIL="<youremail>@cockroachlabs.com"
  # Generate from https://id.atlassian.com/manage-profile/security/api-tokens.export
  export JIRA_API_TOKEN="your-token-here"
  # The "Engineering Team" dropdown in Jira.
  export JIRA_ENG_TEAM="KV"
  # From your board's URL.
  export JIRA_KV_BOARD_ID=400
`

func main() {
	rootCmd := &cobra.Command{
		Use:   "jira-task",
		Short: "Manage Jira internal tasks and sprints",
	}
	rootCmd.SetHelpTemplate(rootCmd.HelpTemplate() + envHelp)

	rootCmd.AddCommand(newCreateCmd())
	rootCmd.AddCommand(newSprintsCmd())

	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}
