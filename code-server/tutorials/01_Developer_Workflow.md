## Developer Workflow

This is part of a multi-part tutorial series and assumes you have run the **Connecting** section already:

- `teachme tutorials/00_Setup.md`

Other sections include:

- `teachme tutorials/00_Setup.md`
- `teachme tutorials/02_Ops_Tasks.md`

This tutorial will walk you through the following:

- Creating a simple nodejs web application.
- Running the nodejs server with nodemon. 
- Viewing live changes made to the application in the web preview URL.
- Authenticating to the Google Cloud SDK.
- Installing extensions from the VS Code marketplace
- Using a terminal multiplexer (tmux).
- Using a custom code-server image.

## Creating the sample project

1. Open the terminal in Code Server (`CTRL + ~`).

2. Create a directory for your sample project:

```bash
mkdir -p ~/project/sample
```

```bash
cd ~/project/sample
```

3. Install [Express](https://expressjs.com/) web server:

```bash
npm install express --save
```

4. Create server.js file:

```
cat > server.js <<EOF
const express = require('express');
const app = express();

app.get('/', (req, res) => {
    res.send('hello world');
});

app.listen(8080, () => console.log('app available at: https://port-8080-${CODE_SERVER_DOMAIN}'));
EOF
```

5. Run the server.js with nodemon:

```bash
nodemon server.js
```

6. Open the url displayed in the nodemon printed output.

7. Make a change to the server.js, save it and reload the web preview page, the change should be reflected.

## Configuring Google Cloud SDK

1. Open the terminal in Code Server (`CTRL + ~`).

2. Login with your Google Cloud SDK credentials:

```bash
gcloud auth login
```

> Click the link to open a new tab where you log in and receive the authentication code. Copy this code and paste it into the code server terminal.

## VS Code extension marketplace differences

One of the major differences between code-server and VS Code is that the marketplaces are different. Many of the extensions found on the standlone VS Code are not available on code-server. 

Some extensions can be installed manually by downloading the .vsix file and installing it using the `code-server` command and then reloading the page:

```
code-server --install-extension path_to_your_extension.vsix
```

For reference, extensions are installed to:

```
cd ~/.local/share/code-server/extensions/
```

## Installing the Cloud Code extension

1. In a code-server terminal, use the script to download the Cloud Code extension and install it:

```bash
/usr/share/code-server/install-cloud-code.sh
```

2. Reload the code-server page to complete the extension install.

## Using a custom image

You can create your own image, push it to your project's GCR and run it from the pod broker.

The base image used below has code-server installed on top of the cloudshell image.

Images can be built from within your code-server session and then switched to from the pod broker interface.

1. From your code server instance terminal, create docker image based on the latest code-server cloudshell image:

```bash
mkdir -p ~/code-server-gke-custom-images && cd $_
```

```
cat > Dockerfile <<EOF
FROM gcr.io/${PROJECT_ID?}/code-server-gke-code-server-cloudshell:latest

# Insert your image modifications here.

EOF
```
> NOTE: the entrypoint is overridden in the deployment manifest by the app broker so modifying the `ENTRYPOINT` in your Dockerfile will have no effect.

2. Build your custom image using Cloud Build and push it to your projects Google Container Registry:

```bash
PROJECT=$(gcloud config get-value project)
```

```bash
IMAGE_NAME=my-custom-code-server-cloudshell:latest
```
> NOTE: use version tags to create different variants of your image, you will be able to select which tag you want to use from the pod broker web interface.

```bash
gcloud builds submit -t gcr.io/${PROJECT_ID?}/${IMAGE_NAME?} .
```
> NOTE: the cloudshell base image has several layers and this can take 5-10 minutes to complete.

3. Grant the code server cluster access to your Google Container Registry:

```bash
CLUSTER_SA_EMAIL="tf-code-server@${PROJECT_ID?}.iam.gserviceaccount.com"
```

```bash
gcloud projects add-iam-policy-binding ${PROJECT_ID?} --member="serviceAccount:${CLUSTER_SA_EMAIL?}" --role="roles/storage.objectViewer"
```

4. Open the code server pod broker URL.

    a. Click the 3 dots to open the options menu.
    
    b. In the __Image Repository__ text box, enter your image name (without the tag)

    c. Click __Save__

    d. If you used a tag other than `latest`, click the refresh icon until your tag appears in the drop down list, select it and then click __Save__ again.

    e. Close the options menu by clicking outside of it.

5. Click the __Shutdown__ button to shutdown any existing session.

6. Click the __Launch__ button to start Code Server with your custom image.

## Running X11 applications

The base code-server Cloud Shell image is built with support for [Xpra](http://xpra.org/) and contains a helper script to start Xpra with the HTML5 client.

1. Run the Xpra process in your container from a code-sever terminal session:

```bash
/usr/share/code-server/start-xpra.sh
```

2. Open the port-8080 link in a new browser tab:

```bash
echo "Open: https://${CODE_SERVER_WEB_PREVIEW_8080}"
```

There is now an X11 server running on `:0`, any X11 programs you install and run will appear in the Xpra HTML5 client.

## Installing Jetbrains Toolbox

Jetbrains toolbox is used to install and run IDEs such as IntelliJ IDEA, PyCharm, and Android Studio.

The toolbox installer uses an AppImage format, which requires libfuse and is not supported in the code-server user runtime pod. 
To workaround this issue, use Docker to manually extract the contents of the AppImage and copy them out of the container.

1. Create Docker image that extracts Jetbrains toolbox AppImage contents:

```bash
mkdir -p $HOME/Downloads/jetbrains-toolbox && \
  cd $HOME/Downloads/jetbrains-toolbox
```

```
cat - > Dockerfile <<EOF
# Download Jetbrains Toolbox
FROM ubuntu:16.04 as appimage
WORKDIR /tmp
ADD https://download.jetbrains.com/toolbox/jetbrains-toolbox-1.16.6319.tar.gz ./jetbrains-toolbox.tar.gz
RUN tar --strip-components=1 -zxvf jetbrains-toolbox.tar.gz

# Extract the AppImage, output will be in /tmp/appimage
RUN chmod +x jetbrains-toolbox && \
    "./jetbrains-toolbox" --appimage-extract && \
    find squashfs-root -type d -exec chmod ugo+rx {} \; && \
    chown -R 1000:1000 squashfs-root && \
    mv squashfs-root appimage
EOF
```

```bash
docker build -t jetbrains-toolbox .
```

2. Copy the extracted AppImage contents out of the container:

```bash
mkdir -p $HOME/bin && docker create --name jetbrains-toolbox jetbrains-toolbox && \
  docker cp jetbrains-toolbox:/tmp/appimage ${HOME}/bin/appimage && \
  docker rm jetbrains-toolbox
```

3. Create launcher script for Jetbrains Toolbox:

```
cat - > ${HOME}/bin/start-jetbrains.sh <<'EOF'
#!/bin/bash

export APPDIR=${HOME}/bin/jetbrains-toolbox
${APPDIR}/AppRun
EOF
```

```bash
chmod +x $HOME/bin/start-jetbrains.sh
```

4. Open the Xpra HTML5 client by visiting the port-8080 forwarded URL:

```bash
echo "Open: https://${CODE_SERVER_WEB_PREVIEW_8080}"
```

5. In the xterm window start the Jetbrains Toolbox:

```bash
$HOME/bin/start-jetbrains.sh
```

> From the toolbox, you can install and run the Jetbrains products.

## Whats next

Open the next Cloud Shell Tutorial: __Ops Tasks__:

```bash
teachme ~/k8s-stateful-workload-operator-examples/tutorials/02_Ops_Tasks.md
```