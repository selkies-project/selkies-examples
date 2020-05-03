#!/usr/bin/env node

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

const process = require('process');
const GuacamoleLite = require('guacamole-lite');
const http = require('http');

const guacdOptions = {
    host: process.env.GUACD_HOST,
    port: 4822 // port of guacd
};

const clientOptions = {
    crypt: {
        cypher: 'AES-256-CBC',
        key: process.env.GUACD_SECRET_KEY
    },
    log: {
        level: "ERRORS"
    }
};

const app = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('OK');
});

const websocketOptions = {
    server: app,
    path: "/ws"
};

console.log("Creating guacd websocket on port 8080 at path /ws")
const guacServer = new GuacamoleLite(websocketOptions, guacdOptions, clientOptions);

guacServer.on('open', (clientConnection) => {
    console.log(`Opened connection for ${clientConnection.connectionSettings.username} on ${clientConnection.connectionSettings.podname}`)
});

guacServer.on('close', (clientConnection) => {
    console.log(`Closed connection for ${clientConnection.connectionSettings.username} on ${clientConnection.connectionSettings.podname}`)
});

guacServer.on('error', (clientConnection, error) => {
    console.log(`Connection error for ${clientConnection.connectionSettings.username} on ${clientConnection.connectionSettings.podname}: ${error}`)
});

var port = parseInt(process.env.GUACAMOLE_LITE_WEB_PORT || "8080")
console.log("Starting server on port " + port);
app.listen(port, '0.0.0.0');