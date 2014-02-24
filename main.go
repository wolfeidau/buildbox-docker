package main

import (
  "os"
  "fmt"
  "log"
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
  app.Version = "0.1.alpha"

  // Define the actions for our CLI
  app.Flags = []cli.Flag {
    cli.StringFlag{"access-token", "", "The access token used to identify the agent."},
    cli.StringFlag{"url", "https://agent.buildbox.io/v1", "The Agent API endpoint."},
    cli.BoolFlag{"debug", "Enable debug mode."},
  }

  // Setup the main action for out application
  app.Action = func(c *cli.Context) {
    if c.String("access-token") == "" {
      fmt.Printf("buildbox-docker: missing access token\nSee 'buildbox-docker --help'\n")
      os.Exit(1)
    }

    // Setup the HTTP client
    var client buildbox.Client;
    client.AgentAccessToken = c.String("access-token")
    client.URL = c.String("url")
    client.Debug = c.Bool("debug")

    // Find out the image of the docker container to user
    image := "d7694418f082"

    // The ID of the job
    job := "1234"

    command := fmt.Sprintf("docker run %s /bin/bash --login -c 'buildbox-agent run %s --access-token %s --url %s'", image, job, client.AgentAccessToken, client.URL)

    log.Printf(command)

  }

  // Run our application
  app.Run(os.Args)
}
