package main

import (
	//"errors"
	"fmt"
	"github.com/buildbox/buildbox-agent/buildbox"
	"github.com/codegangsta/cli"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

var AppHelpTemplate = `TODO

Usage:

  buildbox-docker --agent-access-token [access-token]
`

type Options struct {
	// How much memory is allowed
	Memory string

	// The name of the Docker continer to use
	Container string

	// The cache directory
	CacheDirectory string
}

func main() {
	cli.AppHelpTemplate = AppHelpTemplate

	app := cli.NewApp()
	app.Name = "buildbox-docker"
	app.Version = "0.1.alpha.3"

	// Define the actions for our CLI
	app.Flags = []cli.Flag{
		cli.StringFlag{"agent-access-token", "", "The access token used to identify the agent."},
		cli.StringFlag{"docker-container", "buildbox/base", "The docker container to run the jobs in."},
		cli.StringFlag{"docker-memory", "4g", "Memory limit (format: <number><optional unit>, where unit = b, k, m or g)"},
		cli.StringFlag{"cache-directory", "tmp/cache", "A directory to cache directores between builds"},
		cli.IntFlag{"workers", 2, "How many builds the machine is able to perform at any one time"},
		cli.StringFlag{"url", "https://agent.buildbox.io/v1", "The Agent API endpoint."},
		cli.BoolFlag{"debug", "Enable debug mode."},
	}

	// Setup the main action for out application
	app.Action = func(c *cli.Context) {
		if c.String("agent-access-token") == "" {
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
		agent.Client.AgentAccessToken = c.String("agent-access-token")
		agent.Client.URL = c.String("url")

		// Job specific options
		var options Options
		options.Memory = c.String("docker-memory")
		options.Container = c.String("docker-container")

		// Always in debug mode
		buildbox.LoggerInitDebug()

		// Turn the cache directory into an absolute path and confirm it exists
		options.CacheDirectory, _ = filepath.Abs(c.String("cache-directory"))
		fileInfo, err := os.Stat(options.CacheDirectory)
		if err != nil {
			buildbox.Logger.Fatalf("Could not find information about destination: %s", options.CacheDirectory)
		}
		if !fileInfo.IsDir() {
			buildbox.Logger.Fatalf("%s is not a directory", options.CacheDirectory)
		}

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
	agentAccessToken := ""
	args := []string{"run"}

	// Remove the container after running
	args = append(args, "--rm=true")

	// Restrict memory usage in the container
	// args = append(args, fmt.Sprintf("--memory=%s", options.Memory))

	// Add the environment variables from the API to the process
	for key, value := range job.Env {
		args = append(args, "--env", fmt.Sprintf("%s=%s", key, value))

		// While we're here, also look out for the agent access token
		if key == "BUILDBOX_AGENT_ACCESS_TOKEN" {
			agentAccessToken = value
		}
	}

	// Prepare and set the cache directory
	hostCacheDirectory, _ := prepareCacheDirectory(options.CacheDirectory, agentAccessToken)
	clientCacheDirectory := "/home/buildbox/.buildbox/cache"
	args = append(args, "-v", fmt.Sprintf("%s:%s", hostCacheDirectory, clientCacheDirectory))
	args = append(args, "--env", fmt.Sprintf("BUILDBOX_CACHE_DIRECTORY=%s", clientCacheDirectory))

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

func prepareCacheDirectory(cacheDirectory string, agentAccessToken string) (string, error) {
	agentCachePaths := []string{cacheDirectory, agentAccessToken}
	agentCacheDirectory := strings.Join(agentCachePaths, string(os.PathSeparator))

	err := os.MkdirAll(agentCacheDirectory, 0777)
	if err != nil {
		buildbox.Logger.Errorf("Failed to create folder %s (%T: %v)", agentCacheDirectory, err, err)
		return "", err
	}

	return agentCacheDirectory, nil
}
