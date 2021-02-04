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

class GuacamoleLiteToken {
    /**
     * Interface to Guacamole Lite Token server
     *
     * @constructor
     * @param {String} [token_url]
     *    Path to token service
     */
    constructor(token_url) {
        /**
         * @type {String}
         */
        this.token_url = token_url;
    }

    /**
     * Fetches token with user credentials.
     *
     * @param {String} username
     * @param {String} password
     * 
     * Returns:
     *   {Promise}
     */
    getTokenWithCredentials(username, password, n) {
        // Full list of guacd settings:
        //   https://guacamole.apache.org/doc/gug/configuring-guacamole.html#rdp
        // Some of thse settings are overriden on the backend such as conn-type, hostname, port and security.
        return new Promise((resolve, reject) => {
            fetch(this.token_url, {
                cache: 'no-cache',
                credentials: 'include',
                redirect: 'follow',
                headers: {
                    'x-guacd-setting-width': $(window).width(),
                    'x-guacd-setting-height': $(window).height(),
                    'x-guacd-setting-resize-method': "display-update",
                    'x-guacd-setting-cursor': "remote",
                    'x-guacd-setting-enable-wallpaper': "false",
                    'x-guacd-setting-username': username,
                    'x-guacd-setting-password': btoa(password),
                    'x-guacd-setting-color-depth': "32",
                    'x-guacd-setting-disable-audio': "false",
                }
            })
                .then((result) => {
                    if (result.status < 400) {
                        resolve(result.json());
                    } else {
                        setTimeout(() => {
                            this.getTokenWithCredentials(username, password, n - 1)
                                .then(resolve)
                                .catch(reject);
                        }, 2000);
                    }
                })
                .catch((err) => {
                    setTimeout(() => {
                        this.getTokenWithCredentials(username, password, n - 1)
                            .then(resolve)
                            .catch(reject);
                    }, 2000);
                });
        })
    }
}
