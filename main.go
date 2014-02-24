package main

import (
  "os"
  "os/exec"
  "log"
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

    // Find out the image of the docker container to user. To get the last
    // created image, you can run: `docker ps -l | awk 'NR==2' | awk '{print $2}'`
    // in your console.
    image := "d7694418f082"

    // The ID of the job
    job := "8a6ff1f101c200fbfb3a08224c5e308d50cc1311"

    // Create the command to run
    cmd := exec.Command("docker", "run", image, "/bin/bash", "--login", "-c", "buildbox-agent run " + job + " --access-token " + client.AgentAccessToken + " --url " + client.URL)

    // Pipe the STDERR and STDOUT to this processes outputs
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr

    // Run the command
    err := cmd.Run()
    if err != nil {
      log.Fatal(err)
    }
  }

  // Run our application
  app.Run(os.Args)
}
