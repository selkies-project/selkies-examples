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

package guaclite

// GuacamoleLiteResponse is the JSON response from the web service back to the browser after a reservation has been completed.
type GuacamoleLiteResponse struct {
	Token string `json:"token,omitempty"`
	WSS   string `json:"wss,omitempty"`
}

// GuacdConnection is the connection data encrypted in the guacamole-lite token
type GuacdConnection struct {
	Connection GuacdConnectionSpec `json:"connection"`
}

// GuacdConnectionSpec is the structure of a connection type and its settings.
type GuacdConnectionSpec struct {
	Type     string                  `json:"type"`
	Settings GuacdConnectionSettings `json:"settings"`
}

type GuacdConnectionSettings struct {
	Hostname            string `json:"hostname"`
	Port                string `json:"port"`
	Username            string `json:"username"`
	Password            string `json:"password"`
	Width               string `json:"width"`
	Height              string `json:"height"`
	Cursor              string `json:"cursor"`
	Security            string `json:"security"`
	IgnoreCert          bool   `json:"ignore-cert"`
	EnableDrive         bool   `json:"enable-drive"`
	CreateDrivePath     bool   `json:"create-drive-path"`
	EnableWallpaper     bool   `json:"enable-wallpaper"`
	ResizeMethod        string `json:"resize-method"`
	EnableFontSmoothing bool   `json:"enable-font-smoothing"`
}

type guacdTokenData struct {
	IV    string `json:"iv"`
	Value string `json:"value"`
}
