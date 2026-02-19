The goal is to provide a docker-compose file that allows deploying a sandbox to run opencode inside. The goal is not to execute the compose file right now but instead to provide it.

The implementation must satisfy below limitations:

- Following first boot, containers **must** persist their data even when destroyed and recreated
- Volumes used **must** be mounted from the filesystem
- Volumes **must not** be docker volumes
- All files for the containers persisted **must** be placed under folder `./persist`
- The name of the project **should be** `ai_agent_sandbox`
- The docker **may** include a vim container to allow interactive development
- Model(s) used **must** be lightweight
- The models **must** be run locally
- Configuration **should** be minimal
- The sandbox **must** include opencode
- The setup **should** not require any user input to be configured
- The setup **may** mount the docker socket internally
- The setup **may** set environment variables to configure
- The setup **must** run as the calling user
- The setup **must not** run as root
- The setup **must** come with a `README.md` containing explanation of what was used
- The `README.md` file **must** contain usage instructions
- The setup **should** provide an easy way to increase verbosity for debugging
- The setup **may** include other containers as needed
