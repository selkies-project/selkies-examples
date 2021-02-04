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


/**
 * Helper function to keep track of attached event listeners.
 * @param {Object} obj
 * @param {string} name
 * @param {function} func
 * @param {Object} ctx
 */
function addListener(obj, name, func, ctx) {
    const newFunc = ctx ? func.bind(ctx) : func;
    obj.addEventListener(name, newFunc);

    return [obj, name, newFunc];
}

class GuacamoleLite {
    /**
     * Interface to Guacamole Lite
     *
     * @constructor
     */
    constructor() {
        this.element;
        this.tunnel_url;
        this.token;
        this.guac = null;
        this.guacDisplay = null;
        this.connected = false;
        this.scaling = false;
        this.mouselock = false;
        this.clipboardStatus = "disabled";

        this.lockedX = null;
        this.lockedY = null;
        this.maxWidth = $(window).width();
        this.maxHeight = $(window).height();

        // Tunnel state enumerations.
        this.TUNNEL_STATE_CONNECTING = 0;
        this.TUNNEL_STATE_OPEN = 1;
        this.TUNNEL_STATE_CLOSED = 2;
        this.TUNNEL_STATE_UNSTABLE = 3;

        // Guacamole state enumerations.
        this.STATE_CONNECTING = 1;
        this.STATE_WAITING = 2;
        this.STATE_CONNECTED = 3;
        this.STATE_DISCONNECTING = 4;
        this.STATE_DISCONNECTED = 5;

        // Event handlers that can be bound.
        this.onconnected = null;
    }

    /**
     * Sends the given mouseState to guacamole with x,y positions scaled for the client display size.
     * @param {Object} mouseState 
     */
    sendScaledMouseState(mouseState) {
        // Scale event by current scale
        // Correct for the position of the centered display element by dividing the offset by 2
        var scaledState = new Guacamole.Mouse.State(
            (mouseState.x + this.element.offsetWidth / 2) / this.guacDisplay.getScale(),
            (mouseState.y + this.element.offsetHeight / 2) / this.guacDisplay.getScale(),
            mouseState.left,
            mouseState.middle,
            mouseState.right,
            mouseState.up,
            mouseState.down);

        // Send mouse event
        this.guac.sendMouseState(scaledState);
    }

    /**
     * When this.scale=true, this rescales the client display to fit the remote display.
     * Assumes that guacd was connected with the resize-method=none 
     */
    rescale() {
        var scale;
        if ($(window).height() > this.guacDisplay.getHeight()) {
            // Constrain by height (letterboxing)
            scale = $(window).height() / this.guacDisplay.getHeight();
        } else {
            scale = this.element.offsetWidth / this.guacDisplay.getWidth();
        }

        this.guacDisplay.scale(scale);

        this.maxWidth = this.guacDisplay.getWidth() * scale;
        this.maxHeight = this.guacDisplay.getHeight() * scale;
    }

    /**
     * Bind mouse and keyboard events to guacamole messages. 
    */
    bindInputs() {
        const guacElement = this.guac.getDisplay().getElement();
        const mouse = new Guacamole.Mouse(guacElement);

        document.onpointerlockchange = (e) => {
            if (document.pointerLockElement) return;
            this.lockedX = null;
            this.lockedY = null;
        }

        guacElement.onmousedown =
            guacElement.onmouseup =
            guacElement.onmousemove = (e) => {
                if (!document.pointerLockElement) return;
                if (this.lockedX === null) {
                    this.lockedX = e.clientX;
                    this.lockedY = e.clientY;
                }
                this.lockedX = Math.max(0, Math.min(this.maxWidth, this.lockedX + e.movementX));
                this.lockedY = Math.max(0, Math.min(this.maxHeight, this.lockedY + e.movementY));
                mouse.currentState.fromClientPosition(guacElement, this.lockedX, this.lockedY);
                this.sendScaledMouseState(mouse.currentState);
            }

        mouse.onmousedown =
            mouse.onmouseup =
            mouse.onmousemove = (mouseState) => {
                if (document.pointerLockElement) return;
                this.sendScaledMouseState(mouseState);
            }

        const keyboard = new Guacamole.Keyboard(document);
        keyboard.onkeydown = (keysym) => this.guac.sendKeyEvent(1, keysym);
        keyboard.onkeyup = (keysym) => this.guac.sendKeyEvent(0, keysym);

        const touch = new Guacamole.Mouse.Touchpad(document);
        touch.onmousedown =
            touch.onmousemove =
            touch.onmouseup = (state) => this.guac.sendMouseState(state);
    }

    run() {
        // Guacamole init.
        this.tunnel = new Guacamole.WebSocketTunnel(this.tunnel_url);
        this.guac = new Guacamole.Client(this.tunnel);
        this.guacDisplay = this.guac.getDisplay();

        this.guac.onaudio = (stream, mimetype) => {
            const context = Guacamole.AudioContextFactory.getAudioContext()
            context.resume();
            return Guacamole.AudioPlayer.getInstance(stream, mimetype);
        }

        this.guac.onclipboard = (stream, mimetype) => {
            var reader;

            // If the received data is text, read it as a simple string
            if (/^text\//.exec(mimetype)) {
                reader = new Guacamole.StringReader(stream);
                // Assemble received data into a single string
                var data = '';
                reader.ontext = (text) => {
                    data += text;
                };
                reader.onend = () => {
                    console.log("read clipboard data, length: " + data.length);
                    console.log("clipboardStatus: " + this.clipboardStatus);
                    if (this.clipboardStatus === 'enabled') {
                        navigator.clipboard.writeText(data)
                            .catch(err => {
                                console.log('Could not write text to local clipboard: ' + err);
                            });
                    }
                }
            } else {
                console.log("unsupported clipboard mimetype: " + mimetype);
            }
        }

        // Add the display element
        this.element.appendChild(this.guacDisplay.getElement());

        // Bind the pointer lock handler.
        this.guacDisplay.getElement().addEventListener('click', (e) => {
            if (this.mouselock) e.srcElement.requestPointerLock();
        }, false);

        // Bind scaling resize handler
        window.onresize = () => {
            if (this.scaling) this.rescale();
            this.guac.sendSize($(window).width(), $(window).height());
        };

        // Bind unload event
        window.onunload = () => this.guac.disconnect();

        // Watch changes to the guacamole state
        this.guac.onstatechange = (state) => {
            console.log("Client state:", state);
            if (state == this.STATE_CONNECTED) {
                console.log("Connected to websocket");
                this.connected = true;
                this.bindInputs();

                if (this.onconnected !== null) this.onconnected();
            }
        }

        // Bind guac error handler
        this.guac.onerror = (status) => {
            console.error(`disconnected with code ${status.code}: ${status.message}`);

            this.guac.disconnect();

            // reconnect after 1 seconds
            setTimeout(() => {
                this.guac.connect(`token=${this.token}`);
            }, 1000);
        }

        // Connect to the guacamole websocket
        this.guac.connect(`token=${this.token}`);
        this.tunnel.onstatechange = (state) => {
            console.log("Tunnel state:", state);
            if (state == this.TUNNEL_STATE_UNSTABLE) {
                console.log("Tunnel is unstable.");
            }
        }

        // Reconnect automatically on disconnect.
        setInterval(() => {
            if (!this.connected) {
                console.log("Reconnecting");
                this.tunnel.disconnect();
                this.guac.disconnect();
                this.guac.connect(`token=${this.token}`);
            }
        }, 5000);
    }
}
