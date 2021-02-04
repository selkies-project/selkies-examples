/*
 Copyright 2019 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

var broker = new AppBroker();
var token_service = new GuacamoleLiteToken("token/");
var ScaleLoader = VueSpinner.ScaleLoader;
var guacLite = new GuacamoleLite();

var app = new Vue({

    el: '#app',
    vuetify: new Vuetify(),

    components: {
        ScaleLoader
    },

    data() {
        return {
            appName: window.location.pathname.split("/")[1] || "rdp",
            status: 'connecting',
            loadingText: 'connecting',
        }
    },

    methods: {
        getUsername: () => {
            if (app === undefined) return "webrtc";
            return (getCookieValue("broker_" + app.appName) || "webrtc").split("#")[0];
        },
    },

    watch: {
    },

    updated: () => {
        document.title = "Remote Desktop - " + app.appName;
    },
});

$(document).ready(() => {
    navigator.permissions.query({
        name: 'clipboard-read'
    }).then(permissionStatus => {
        // Will be 'granted', 'denied' or 'prompt':
        if (permissionStatus.state === 'granted') {
            guacLite.clipboardStatus = 'enabled';
        }

        // Listen for changes to the permission state
        permissionStatus.onchange = () => {
            if (permissionStatus.state === 'granted') {
                guacLite.clipboardStatus = 'enabled';
            }
        };
    });

    // Actions to take whenever window changes focus
    window.addEventListener('focus', () => {
        // Send clipboard contents.
        navigator.clipboard.readText()
            .then(text => {
                console.log("sending clipboard content with length " + text.length);
                // Create stream with proper mimetype
                var stream = guacLite.guac.createClipboardStream("text/plain");
                writer = new Guacamole.StringWriter(stream);
                writer.sendText(text);
                writer.sendEnd();
            })
            .catch(err => {
                console.log('Failed to read clipboard contents: ' + err);
            });
    });

    // Set the target element for the guacamole display.
    guacLite.element = document.getElementById("display");

    app.loadingText = "starting instance";

    guacLite.onconnected = () => {
        app.status = "connected";
    }

    broker.getRDPCredentials()
        .then((data) => {
            app.loadingText = "connecting";
            token_service.getTokenWithCredentials(data.username, atob(data.password))
                .then((data) => {
                    guacLite.tunnel_url = data.wss;
                    guacLite.token = data.token;
                    guacLite.run();
                });
        })
});