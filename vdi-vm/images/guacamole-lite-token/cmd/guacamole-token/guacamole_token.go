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

package main

import (
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	"gcp.solutions/guacamole-token/pkg/guaclite"
)

func init() {
	guacdSecretKey := os.Getenv("GUACD_SECRET_KEY")
	if len(guacdSecretKey) == 0 {
		log.Fatal("Missing env GUACD_SECRET_KEY")
	}
	wssHostPath := os.Getenv("WSS_HOSTPATH")
	if len(wssHostPath) == 0 {
		log.Fatal("Missing env WSS_HOSTPATH")
	} else if wssHostPath[:6] != "wss://" {
		log.Fatal("invalid WSS_HOSTPATH env, does not start with wss://")
	}
	http.HandleFunc("/healthz", healthzHandler)
	http.HandleFunc("/", newTokenHandler(guacdSecretKey, wssHostPath))
}

func main() {
	port := flag.Int64("port", 8080, "port to expose metrics on")
	flag.Parse()

	log.Printf("Starting to listen on :%d", *port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", *port), nil))
}

type statusResponse struct {
	Code   int    `json:"code"`
	Status string `json:"status"`
}

func healthzHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "OK")
}

func newTokenHandler(guacdSecretKey, wssHostPath string) func(w http.ResponseWriter, r *http.Request) {

	return func(w http.ResponseWriter, r *http.Request) {
		headerPrefix := "x-guacd-"
		guacdParams := getPrefixedHeaders(r, headerPrefix)

		// Verify required headers were passed.
		requiredParams := []string{
			"conn-type",
			"setting-hostname",
			"setting-port",
			"setting-username",
			"setting-password",
		}
		for _, k := range requiredParams {
			if _, ok := guacdParams[k]; !ok {
				writeResponse(w, http.StatusBadRequest, fmt.Sprintf("missing header: %s%s", headerPrefix, k))
				return
			}
		}

		// Default values for optional params
		if len(guacdParams["setting-cursor"]) == 0 {
			guacdParams["setting-cursor"] = "local"
		}
		if len(guacdParams["setting-security"]) == 0 {
			guacdParams["setting-security"] = "any"
		}

		// Decode base64 password
		password, err := base64.StdEncoding.DecodeString(guacdParams["setting-password"])
		if err != nil {
			writeResponse(w, http.StatusBadRequest, "failed to base64 decode password")
			return
		}

		// Make guacamole-lite token data
		guacdConn := guaclite.GuacdConnection{
			Connection: guaclite.GuacdConnectionSpec{
				Type: guacdParams["conn-type"],
				Settings: guaclite.GuacdConnectionSettings{
					Hostname:        guacdParams["setting-hostname"],
					Port:            guacdParams["setting-port"],
					Username:        guacdParams["setting-username"],
					Password:        string(password),
					Width:           guacdParams["setting-width"],
					Height:          guacdParams["setting-height"],
					Cursor:          guacdParams["setting-cursor"],
					Security:        guacdParams["setting-security"],
					IgnoreCert:      (guacdParams["setting-ignore-cert"] == "true"),
					EnableDrive:     (guacdParams["setting-enable-drive"] == "true"),
					CreateDrivePath: (guacdParams["setting-create-drive-path"] == "true"),
					EnableWallpaper: (guacdParams["setting-enable-wallpaper"] == "true"),
					ResizeMethod:    (guacdParams["setting-resize-method"]),
				},
			},
		}

		// Make token
		tokenResp, err := guaclite.NewTokenResponse(guacdSecretKey, guacdConn, wssHostPath)
		if err != nil {
			log.Printf("%v", err)
			writeResponse(w, http.StatusInternalServerError, "internal error")
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(tokenResp)
	}
}

func getPrefixedHeaders(r *http.Request, prefix string) map[string]string {
	headerMap := make(map[string]string, 0)

	for k, v := range r.Header {
		if len(k) > len(prefix) && strings.ToLower(k[0:len(prefix)]) == strings.ToLower(prefix) {
			headerMap[strings.ToLower(k[len(prefix):])] = v[0]
		}
	}

	return headerMap
}

func getRequiredHeader(name string, r *http.Request) (string, error) {
	value := r.Header.Get(name)
	if len(value) == 0 {
		return "", fmt.Errorf("missing header: %s", name)
	}
	return value, nil
}

func writeResponse(w http.ResponseWriter, statusCode int, message string) {
	status := statusResponse{
		Code:   statusCode,
		Status: message,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(status)
}
