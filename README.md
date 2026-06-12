# docker-github-runner

You want to deploy a container with github runner ready to use ? 

**In a 5 step bash scrip, get it running**

You will need:
- `Repo URL`
- `Location of the worker files` on your local machine in __UNIX path__
- `Registration Token` for your worker
- Container name: default is `github-runner`

> Hints:
    Find the `Registration token` and the `Project URL` on the page to create a _self-hosted runner_ on your _project page_.

## Interactive setup

Step by step
```bash
./setup.sh
```

```bash
docker compose up -d
```

# Simple setup

copy this in the ``.env`` file the following:

```.env
REPO_URL=https://github.com/JeanrodevCherry/docker-github-runner
LOCATION_TMP=/c/Users/jeanr/docker/
GITHUB_RUNNER_TOKEN=TOKEN
RUNNER_NAME=github-runner
```

then execute ```docker compose up -d```