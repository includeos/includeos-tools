package cmd

import (
	"fmt"
	"martin/lotto/instance"
	"martin/lotto/instanceStatus"
	"martin/lotto/server"
	"os"

	"github.com/spf13/cobra"
)

var (
	mothershipBin      string
	mothershipHost     string
	mothershipUsername string
	mothershipPassword string
)

var RootCmd = &cobra.Command{
	Use: "lotto",
	Run: func(cmd *cobra.Command, args []string) {
		var statusHandler instanceStatus.StatusGetter
		statusHandler = instanceStatus.NewMothership(mothershipBin, mothershipHost, mothershipUsername, mothershipPassword)

		var instances []*instance.Instance
		var err error
		if instances, err = instance.LoadPages(statusHandler); err != nil {
			fmt.Printf("Error loading existing monitor entries: %v", err)
			os.Exit(1)
		}

		server.Serve(statusHandler, instances)
	},
}

func init() {
	RootCmd.Flags().StringVar(&mothershipBin, "mBin", "", "Location of mothership binary")
	RootCmd.Flags().StringVar(&mothershipHost, "mHost", "", "Mothership host to connect to")
	RootCmd.Flags().StringVar(&mothershipUsername, "mUser", "", "Mothership username to authenticate with")
	RootCmd.Flags().StringVar(&mothershipPassword, "mPwd", "", "Mothership password to authenticate with")

	/*
		RootCmd.MarkFlagRequired("mBin")
		RootCmd.MarkFlagRequired("mHost")
		RootCmd.MarkFlagRequired("mUser")
		RootCmd.MarkFlagRequired("mPwd")
	*/
}
