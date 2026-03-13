# AI_SANDBOX

This project concerns building a sandbox environment, where AI agents can be safely deployed and used to run
autonomously

## Motivation

AI agents are becoming ubiquitous and indispensable in developing code. At the same time, there's more than one horror
stories about agents that did serious damage by deleting files they were never meant to and accessing information they
weren't supposed to.

At the same time, agents work on context, so a broad environment means that the agent will be reading way more
information than it needs. By using the sandbox, the context seen by the agent is minimized even further.

## Design
A two-level agent sandbox is created, with each level usable independently if the developer so desires. A
`Vagrant`-deployed Ubuntu VM has `docker` installed automatically upon deployment and gets a copy of the files
in the repository. The user can then use `docker compose` commands directly or `make` commands to deploy a
docker-compose environment and within that environment run agents.

Configuration files can be stored under the `confirguration` directory and mapped internally into the docker
containers

## Use

### Vagrant

Vagrant can be installed following instructions by Hashicorp, found
[here](https://developer.hashicorp.com/vagrant/install)

The provided `Vagrantfile` uses the `libvirt` provider and runs an Ubuntu 22.04 VM. Below are the commands to
use with Vagrant. **NOTE** the commands are not part of the `Makefile` because the use of Vagrant is much more
simplistic than that of compose

| Command                   | Usage                                                                     |
| :------------------------ | :------------------------------------------------------------------------ |
| `vagrant up`              | Starts the VM if stopped. Provisions and start if not present.            |
| `vagrant destroy [-f]`    | Stops and completely removes the VM. With `-f`, non-interactive           |
| `vagrant start`           | Powers-on a VM that exists and has been halted                            |
| `vagrant halt`            | Powers-down the VM                                                        |
| `vagrant ssh`             | Connects to the console of the VM                                         |

### Makefile
The section below lists the commands to use in conjunction with the `Makefile`. Commands can also be run
manually, however it is up to the user to review the `Makefile` contents and understand the steps. Should the
`Makefile` become overtly complicated it will be subject to being re-written, however until such time, it
remains the selected way to deploy and access the containers

| Command           | Usage                                                                     |
| :---------------- | :------------------------------------------------------------------------ |
| `make status`     | Shows if the containers are running                                       |
| `make up`         | Creates and starts the containers                                         |
| `make down`       | Stops and removes the containers                                          |
| `make start`      | Starts the containers. Will call `up` if they don't exist                 |
| `make stop`       | Stops the containers. Will not remove them.                               |
| `make gemini`     | Executes and connects to a bash process inside the `gemini` container     |
| `make cursor`     | Executes and connects to a bash process inside the `cursor` container     |

### Notes
* The `stop` and `down` rules do not have `start` and `up` as dependencies, otherwise they would start /
  create the containers to in order to stop / delete them. Instead, the recipe is left to fail.
* There are rules that do the setup and are listed as dependencies. They are not mentioned because they are
  not meant to be used directly
* There is no `clean` rule, as user discretion is enforced
* The compose environment can be used without first using Vagrant. In that case, user carries all the risks
  that come with docker containers being run on the host

### File hierarchy
* `persist` directory (does not exist in repository, created upon use)
    * Created during setup
    * It is meant to hold files and configuration that survive multiple reboots.
    * *WILL NOT* survive a destruction and recreation of the Vagrant VM. User must save the contents on the
      host if that is required
* `configuration`
    * Contains static configuration that is shared with the VMs
    * Persists configuration for each agent type, to avoid the need to reconfigure constantly
    * Contains files that are not saved in the repository for safety reasons
* `/opt/sandbox` (within Vagrant VM)
    * Location where the repository files are made accessible
    * Is **not** a repository itself as `git` related files are filtered-out
* `Vagrantfile`
    * Contains Vagrant description on how to create the VM sandbox and copy required files within
    * Uses `rsync` file provisioner to select files that get communicated within the VM
* `Makefile`
    * Contains rules to deploy the containerized part of the sandbox
    * Within the VM, resides under `/opt/sandbox`
* `docker-compose.yml`
    * Compose file defining the build and deploy rules for the agents
* `AI.md`
    * RIS file used to give the operational directives to the agent

# Links
* **Vagrant installation instructions:**
    [https://developer.hashicorp.com/vagrant/install](https://developer.hashicorp.com/vagrant/install)
