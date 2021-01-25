/*
 Copyright 2021 The Selkies Authors

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

package main

import (
	"encoding/json"
	"flag"
	"io/ioutil"
	"log"
	"math"
	"net/http"
	"time"
)

type codeServerStatus struct {
	Status        string `json:"status"`
	LastHeartbeat int64  `json:"lastHeartbeat"`
}

var (
	sessionTimeoutSeconds = flag.Int64("timeout", 600, "Session timeout in seconds")
	warningMinutes        = flag.Int64("warning", 2, "Watchdog expire warning message in minutes")
	healthEndpoint        = flag.String("health_endpoint", "http://localhost:3180/healthz", "Code Server healthz http endpoint")
	brokerCookie          = flag.String("broker_cookie", "", "Selkies app broker cookie used to issue shutdown action")
	brokerEndpoint        = flag.String("broker_endpoint", "", "Endpoint use to issue shutdown, example: http://istio-ingressgateway.istio-system.svc.cluster.local/broker/code-server/")
	brokerHost            = flag.String("broker_host", "", "value to set the Host header to when issuing shutdown request, useful when targeting an internal ingressgateway endpoint to match route in VirtualService.")
)

func main() {
	flag.Parse()

	sessionTimeoutMinutes := *sessionTimeoutSeconds / 60

	log.Printf("INFO: Monitoring health endpoint: %s", *healthEndpoint)
	log.Printf("INFO: Session timeout set at %d minutes with %d minute warning.", sessionTimeoutMinutes, *warningMinutes)

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	log.Printf("INFO: Waiting for server startup.")
	for {
		status, err := getStatus(client, *healthEndpoint)
		_, timedout := timeoutMet(status, sessionTimeoutMinutes)
		if err == nil && !timedout {
			log.Printf("INFO: Server startup complete, watchdog started.")
			break
		}
		time.Sleep(2 * time.Second)
	}

	warningIssued := false
	for {
		status, err := getStatus(client, *healthEndpoint)
		if err != nil {
			log.Printf("WARN: failed to get status: %v", err)
		} else {
			deltaMinute, timedout := timeoutMet(status, sessionTimeoutMinutes)
			remainingMinutes := (sessionTimeoutMinutes - deltaMinute)
			if remainingMinutes <= *warningMinutes && !warningIssued {
				log.Printf("WARN: watchdog will expire in %d minutes.", remainingMinutes)
				warningIssued = true
			}
			if timedout {
				log.Printf("INFO: Watchdog expired issuing shutdown request.")
				if err := selkiesShutdown(client, *brokerCookie, *brokerEndpoint, *brokerHost); err != nil {
					log.Printf("ERROR: Failed to shutdown instance: %v", err)
				} else {
					time.Sleep(10 * time.Second)
					break
				}
			}
		}

		time.Sleep(30 * time.Second)
	}
}

func timeoutMet(status codeServerStatus, timeoutMinutes int64) (int64, bool) {
	nowMs := time.Now().UnixNano() / 1000 / 1000
	deltaMs := int64(math.Abs(float64(nowMs - status.LastHeartbeat)))
	deltaMinute := int64(deltaMs / 1000 / 60)
	return deltaMinute, deltaMinute >= timeoutMinutes
}

func getStatus(client *http.Client, url string) (codeServerStatus, error) {
	var resp codeServerStatus

	r, err := client.Get(url)
	if err != nil {
		return resp, err
	}
	defer r.Body.Close()

	if err := json.NewDecoder(r.Body).Decode(&resp); err != nil {
		return resp, err
	}

	return resp, nil
}

func selkiesShutdown(client *http.Client, cookie, url, host string) error {
	req, err := http.NewRequest("DELETE", url, nil)
	req.Header.Set("Cookie", cookie)
	req.Host = host
	r, err := client.Do(req)
	if err != nil {
		return err
	}
	defer r.Body.Close()
	data, err := ioutil.ReadAll(r.Body)
	if err != nil {
		return err
	}
	log.Printf("INFO: response from DELETE request: %s", string(data))
	return nil
}
