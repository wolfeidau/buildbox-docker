package main

import (
	//"errors"
	"fmt"
	"github.com/buildbox/buildbox-agent/buildbox"
	"github.com/codegangsta/cli"
	"os"
	"os/exec"
	"sync"
	"time"
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
	app.Version = "0.1.alpha.3"

	// Define the actions for our CLI
	app.Flags = []cli.Flag{
		cli.StringFlag{"access-token", "", "The access token used to identify the agent."},
		cli.StringFlag{"docker-container", "buildbox/base", "The docker container to run the jobs in."},
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
		var agent buildbox.Agent

		// Client specific options
		agent.Client.AgentAccessToken = c.String("access-token")
		agent.Client.URL = c.String("url")

		// Job specific options
		var options Options
		options.Memory = c.String("memory")
		options.Container = c.String("docker-container")

		// Always in debug mode
		buildbox.LoggerInitDebug()

		// TODO: Confirm agent can connect to docker

		// Setup the agent
		agent.Setup()

		// A nice welcome message
		buildbox.Logger.Printf("Started buildbox-docker with agent `%s` (version %s)\n", agent.Name, buildbox.Version)

		// Create a wait group
		var w sync.WaitGroup
		w.Add(workers)

		// Start the workers
		for i := 0; i < workers; i++ {
			go func(index int) {
				// Start the client
				start(fmt.Sprintf("%d/%d", index+1, workers), agent.Client, options)

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
	sleepTime := time.Duration(idleSeconds*1000) * time.Millisecond

	// A nice message about the client
	buildbox.Logger.Printf("Starting worker (%s)", name)

	for {
		job, err := client.JobNext()

		if err != nil {
			buildbox.Logger.Printf("Failed to get next job: %s\n", err)
		} else {
			// Do we have a job to perform?
			if job.ID != "" {
				buildbox.Logger.Printf("Worker (%s) is performing job %s", name, job.ID)

				err = run(client, job, options)
				if err != nil {
					buildbox.Logger.Printf("Failed to run job %s (%s)", job.ID, err)

					// TODO: mark the job as failed
				}

				buildbox.Logger.Printf("Worker (%s) is now free", name)
			}
		}

		// Sleep then check again later.
		time.Sleep(sleepTime)
	}
}

func run(client buildbox.Client, job *buildbox.Job, options Options) error {
	args := []string{"run"}

	// Remove the container after running
	args = append(args, "--rm=true")

	// Restrict memory usage in the container
	// args = append(args, fmt.Sprintf("--memory=%s", options.Memory))

	// Add the environment variables from the API to the process
	for key, value := range job.Env {
		args = append(args, "--env", fmt.Sprintf("%s=%s", key, value))
	}

	// Add our custom agent url ENV variable
	args = append(args, "--env", fmt.Sprintf("BUILDBOX_AGENT_URL=%s", client.URL))

	// Define which container to run in
	args = append(args, options.Container)

	// Run the build prep script as the command for the container
	args = append(args, "/home/buildbox/.buildbox/prepare.sh")

	// Create the command to run
	cmd := exec.Command("docker", args...)

	// Pipe the STDERR and STDOUT to this processes outputs
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// Run the command
	if err := cmd.Run(); err != nil {
		return err
	}

	return nil
}
