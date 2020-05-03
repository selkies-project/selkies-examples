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

class AppBroker {
    /**
     * Interface to app broker
     *
     * @constructor
     */
    constructor() {
        this.rdp_credentials_api_url = "api/";
    }

    /**
     * Function to fetch ephemeral RDP credentials from API.
     * @param {*} n used for recursive retries
     */
    // Fetch RDP credentials
    getRDPCredentials(n) {
        return new Promise((resolve, reject) => {
            fetch(this.rdp_credentials_api_url, {
                mode: 'no-cors',
                cache: 'no-cache',
                credentials: 'include',
                redirect: 'follow',
            })
                .then((result) => {
                    if (result.status < 400) {
                        resolve(result.json());
                    } else {
                        setTimeout(() => {
                            this.getRDPCredentials(n - 1)
                                .then(resolve)
                                .catch(reject);
                        }, 2000);
                    }
                })
                .catch((err) => {
                    setTimeout(() => {
                        this.getRDPCredentials(n - 1)
                            .then(resolve)
                            .catch(reject);
                    }, 2000);
                });
        })
    }
}