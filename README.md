# Pipeline Deploy

This repository contains the artifacts and scripts necessary to assemble the various pieces of AppSec Pipeline into a
deployable form.

## Build Script

The build scripts ([./build.sh](./build.sh)) handles the task of grabbing all the dependencies, building binaries, and building
Docker containers for deploying AppSec Pipeline.

### Usage

__Clean up from a previous build:__

`./build.sh -c`

__Build everything for a deployment:__

`./build.sh -d`

__Build with local packages:__

NOTE: `-l` must come before `-d`

`./build.sh -l [path_to_local_version] -d`

__Gather deps locally:__

To just gather the dependencies without building them, do:

`./build.sh -g`

### Example

Clean up the previous build, and build the deployment artifacts using a local version of `pipelib`:

`./build.sh -c && ./build.sh -l /local/version/of/pipelib -d`

## Docker Compose File

Docker Compose allows one to define a whole application, with database, application server, workers, etc. all in one place. The
[./docker-compose.yml](./docker-compose.yml) file in this repo contains that information for AppSec Pipeline.

### Example

Build the components' Docker containers and start them all in daemonized mode:

`docker-compose up --build -d`

## App Refresh Script

This is a helper script (and an imperfect one at that) for populating the contents of the `orca` database with the primitives
necessary for running Scans. It contains the `curl` commands necessary to create an Application, an Endpoint, a Tool Config, and
a Scan. You will need to modify the script as-needed.

## Full Example

To deploy AppSec Pipeline locally, here is a series of commands that should set everything up and kick off a scan:

```
git clone git@github.rackspace.com:SecurityEngineering/pipeline-deploy.git
cd pipeline-deploy
# This builds all the deployment artifacts and starts all the components in daemonized mode
./build.sh -d && cd build/deploy && docker-compose up -d --build
# This step may be unnecessary in the future, but for now it's the way to bootstrap the "root" user to start with.
# You can specify any username or password you want here, but you'll need to specify them as environment variables for the
# app_refresh.sh call below
# You only need to call this if the database is "fresh" - i.e. no user has been created
cd ../deps/pipelib/orca && go build && ./orca user -name root -password root
# If you changed the username/password from the above command, you can specify them here like so:
# env ORCA_USER=root ORCA_PASS=root ./app_refresh.sh
# If the database is "fresh", this script will work out of the box. If the database has already been populated, you'll need to
# update the "app_id", "ep_id", and "tc_id" with whatever those values are in the database (you can query them from the API)
cd ../../../../ && ./app_refresh.sh
```
