## Selkies Demo Environment

This example shows uses Deployment Manager to provision a fully configured Selkies environment.

Core Components:
- App Launcher

Addons:
- WebRTC Streaming
- VDI VM Orchestration

Apps:
- Jupyter Notebook
- XFCE Desktop
- Code Server
- Windows Server 2019
- Ubuntu 19.10
- Blender 3D
- SuperTuxKart
- Unigine Heaven
- Unigine Valley
- Unreal Car Configurator
- Xonotic

## Deployment

1. Set the PROJECT_ID variable:

```bash
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
```

2. Build the images in your project:

```bash
(cd demo-images && gcloud builds submit --project ${PROJECT_ID?} --config build-images-cloudbuild.json)
```

> NOTE: this will take 25-35 minutes.

3. Run deployment manager using the helper script:

```bash
./qwiklabs_test.sh
```

> NOTE: this will take 25-35 minutes. Defailed progress can be monitored from the [Cloud Build cloud console page](https://console.cloud.google.com/cloud-build/builds?project=).


## Open Launcher

1. Connect to the App Launcher web interface at the URL output below:

```bash
echo "https://broker.endpoints.${PROJECT_ID?}.cloud.goog/"
```