package main

import (
  "os"
  "os/exec"
  "time"
  "log"
  "fmt"
  "errors"
  "sync"
  "github.com/codegangsta/cli"
  "github.com/buildboxhq/buildbox-agent/buildbox"
)

var AppHelpTemplate = `TODO

Usage:

  buildbox-docker --access-token [access-token]
`

type Options struct {
  // How much memory is allowed
  Memory string

  // The name of the Docker continer to use
  Container string
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
    cli.StringFlag{"memory", "4g", "Memory limit (format: <number><optional unit>, where unit = b, k, m or g)"},
    cli.IntFlag{"workers", 2, "How many builds the machine is able to perform at any one time"},
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

    workers := c.Int("workers")
    if workers <= 0 {
      fmt.Printf("buildbox-docker: worker count must be greater than 0\nSee 'buildbox-docker --help'\n")
      os.Exit(1)
    }

    // Set the agent options
    var agent buildbox.Agent;
    agent.Debug = c.Bool("debug")

    // Client specific options
    agent.Client.AgentAccessToken = c.String("access-token")
    agent.Client.URL = c.String("url")
    agent.Client.Debug = agent.Debug

    // Job specific options
    var options Options
    options.Memory = c.String("memory")
    options.Container = c.String("docker-container")

    // Tell the user that debug mode has been enabled
    if agent.Debug {
      log.Printf("Debug mode enabled")
    }

    // Setup the agent
    agent.Setup()

    // A nice welcome message
    log.Printf("Started buildbox-docker with agent `%s` (version %s)\n", agent.Name, buildbox.Version)

    // Create a wait group
    var w sync.WaitGroup
    w.Add(workers)

    // Start the workers
    for i := 0; i < workers; i++ {
      go func(index int) {
        // Start the client
        start(fmt.Sprintf("%d/%d", index + 1, workers), agent.Client, options)

        w.Done()
      }(i)
    }

    // Wait for the workers to finish
    w.Wait()
  }

  // Run our application
  app.Run(os.Args)
}

func start(name string, client buildbox.Client, options Options) {
  // How long the agent will wait when no jobs can be found.
  idleSeconds := 5
  sleepTime := time.Duration(idleSeconds * 1000) * time.Millisecond

  // A nice message about the client
  log.Printf("Starting worker (%s)", name)

  for {
    job, err := client.JobNext()

    if err != nil {
      log.Printf("Failed to get next job: %s\n", err)
    } else {
      // Do we have a job to perform?
      if job.ID != "" {
        log.Printf("Worker (%s) is performing job %s", name, job.ID)

        err = run(client, job, options)
        if err != nil {
          log.Printf("Failed to run job %s (%s)", job.ID, err)
        }

        log.Printf("Worker (%s) is now free", name)
      }
    }

    // Sleep then check again later.
    time.Sleep(sleepTime)
  }
}

func run(client buildbox.Client, job *buildbox.Job, options Options) error {
  // Extract the agent access token
  agentAccessToken := ""

  // Add the environment variables from the API to the process
  for key, value := range job.Env {
    if key == "BUILDBOX_AGENT_ACCESS_TOKEN"{
      agentAccessToken = value
    }
  }

  // If one couldn't be found, no job!
  if agentAccessToken == "" {
    return errors.New("BUILDBOX_AGENT_ACCESS_TOKEN could not be found")
  }

  // Create the command to run
  agentCommand := fmt.Sprintf("buildbox-agent run %s --access-token %s --url %s", job.ID, agentAccessToken, client.URL)
  memoryOption := fmt.Sprintf("--memory=%s", options.Memory)
  cmd := exec.Command("docker", "run", "--rm=true", memoryOption, options.Container, "/bin/bash", "--login", "-c", agentCommand)

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
