## VS Code code-server on GKE

## Description

This example shows you how to deploy the [Code Server app](https://github.com/cdr/code-server) on Selkies.

## Dependencies

- App Launcher: [v1.0.0+](https://github.com/GoogleCloudPlatform/solutions-k8s-stateful-workload-operator/tree/v1.0.0)

## Features

- Cloud Shell base image
- port forwarding to top-level domain for local development on ports 3000, 8000 and 8080
- Docker daemon sidecar for per-user image building
- Run graphical X11 apps with Xpra (start-xpra alias)
- Bring your own image, set by user from launcher.

## Installed software

- All Cloud Shell base software.
- code-server release from upstream docker image.
- Cloud Code extension (install-cloud-code alias)
- Docker
- Xpra with Software GLX.
- Chrome Browser
- Tinyfilemanager

## Tutorials

- `teachme tutorials/00_Setup.md`
- `teachme tutorials/01_Developer_Workflow.md`
- `teachme tutorials/02_Ops_Tasks.md`
