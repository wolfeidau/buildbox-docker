package main

import (
  "os"
  "fmt"
  "github.com/codegangsta/cli"
  "github.com/buildboxhq/agent-go/buildbox"
)

var AppHelpTemplate = `TODO

Usage:

  buildbox-docker --access-token [access-token]
`

func main() {
  cli.AppHelpTemplate = AppHelpTemplate

  app := cli.NewApp()
  app.Name = "buildbox-docker"
  app.Version = "0.1"

  // Define the actions for our CLI
  app.Flags = []cli.Flag {
    cli.StringFlag{"access-token", "", "The access token used to identify the agent."},
    cli.StringFlag{"url", "https://agent.buildbox.io/v1", "The Agent API endpoint."},
    cli.BoolFlag{"debug", "Enable debug mode."},
  }

  // Default the default action
  app.Action = func(c *cli.Context) {
    if c.String("access-token") == "" {
      fmt.Printf("buildbox-docker: missing access token\nSee 'buildbox-docker --help'\n")
      os.Exit(1)
    }

    var client buildbox.Client;
    client.AgentAccessToken = c.String("access-token")
    client.URL = c.String("url")
    client.Debug = c.Bool("debug")
  }

  app.Run(os.Args)
}
