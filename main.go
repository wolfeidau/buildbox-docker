package main

import (
  "os"
  "os/exec"
  "time"
  "log"
  "fmt"
  "github.com/codegangsta/cli"
  "github.com/buildboxhq/agent-go/buildbox"
)

var AppHelpTemplate = `TODO

Usage:

  buildbox-docker --access-token [access-token]
`

type Job struct {
  // The id of the job
  ID string `json:"job_id"`

  // The access token of the agent
  AgentAccessToken string `json:"agent_access_token"`
}

func main() {
  cli.AppHelpTemplate = AppHelpTemplate

  app := cli.NewApp()
  app.Name = "buildbox-docker"
  app.Version = "0.1.alpha"

  // Define the actions for our CLI
  app.Flags = []cli.Flag {
    cli.StringFlag{"access-token", "", "The access token used to identify the agent."},
    cli.StringFlag{"docker-container", "buildboxhq/base", "The docker container to run the jobs in."},
    cli.StringFlag{"url", "https://agent.buildbox.io/v1", "The Agent API endpoint."},
    cli.BoolFlag{"debug", "Enable debug mode."},
  }

  // Setup the main action for out application
  app.Action = func(c *cli.Context) {
    if c.String("access-token") == "" {
      fmt.Printf("buildbox-docker: missing access token\nSee 'buildbox-docker --help'\n")
      os.Exit(1)
    }

    if c.String("docker-container") == "" {
      fmt.Printf("buildbox-docker: missing docker container\nSee 'buildbox-docker --help'\n")
      os.Exit(1)
    }

    // Setup the HTTP client
    var client buildbox.Client;
    client.AgentAccessToken = c.String("access-token")
    client.URL = c.String("url")
    client.Debug = c.Bool("debug")

    start(client, c.String("docker-container"))
  }

  // Run our application
  app.Run(os.Args)
}

func start(client buildbox.Client, container string) {
  // How long the agent will wait when no jobs can be found.
  idleSeconds := 5
  sleepTime := time.Duration(idleSeconds * 1000) * time.Millisecond

  for {
    req, err := client.NewRequest("GET", "/jobs/queue", nil)

    if err == nil {
      var jobs []Job
      client.DoReq(req, &jobs)

      for _, job := range jobs {
        // In the event that the run fails, we dont really care.
        err = run(client, job, container)
      }
    } else {
      log.Println("Failed to download job queue: %s", err)
    }

    // Sleep then check again later.
    time.Sleep(sleepTime)
  }
}

func run(client buildbox.Client, job Job, container string) error {
  // Create the command to run
  agentCommand := fmt.Sprintf("buildbox-agent run %s --access-token %s --url %s", job.ID, job.AgentAccessToken, client.URL)
  cmd := exec.Command("docker", "run", container, "/bin/bash", "--login", "-c", agentCommand)

  // Pipe the STDERR and STDOUT to this processes outputs
  cmd.Stdout = os.Stdout
  cmd.Stderr = os.Stderr

  // Run the command
  err := cmd.Run()
  if err != nil {
    return err
  }

  return nil
}
