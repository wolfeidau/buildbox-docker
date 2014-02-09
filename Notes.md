# Notes

- cat Dockerfile | docker -H tcp://0.0.0.0:4243 build -
- Tagging while creating: `docker build -t tag-name - < Dockerfile`

- Running the agent from inside the container:

```
docker run 35bfb72038de buildbox-agent start --bootstrap-script /home/buildbox/.buildbox/bootstrap.sh \
                                             --access-token 123 \
                                             --url "http://agent.buildbox.192.168.1.101.xip.io/v1" \
                                             --exit-on-complete
```
