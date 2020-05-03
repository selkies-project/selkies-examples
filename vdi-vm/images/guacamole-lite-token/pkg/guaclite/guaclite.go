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

import (
	"crypto/aes"
	"crypto/cipher"
	"encoding/base64"
	"encoding/json"
	"math/rand"
)

// Encrypt CBC encrypts the given input with a given key using a random 16 byte IV.
func Encrypt(key []byte, input []byte) (string, error) {
	var crypted string

	c, err := aes.NewCipher(key)
	if err != nil {
		return crypted, err
	}

	iv := make([]byte, 16)
	rand.Read(iv)

	encrypter := cipher.NewCBCEncrypter(c, iv)

	padded := pad(input)

	data := make([]byte, len(padded))
	copy(data, padded)

	encrypter.CryptBlocks(data, data)

	tokenData := guacdTokenData{
		IV:    base64.StdEncoding.EncodeToString(iv),
		Value: base64.StdEncoding.EncodeToString(data),
	}

	jsonData, _ := json.Marshal(tokenData)

	crypted = base64.StdEncoding.EncodeToString(jsonData)

	return crypted, nil
}

// Decrypt decrypts a given base64 encoded token string with a given key and iv.
func Decrypt(encKey, b64iv, stringtodecrypt string) string {

	ciphertext, err := base64.StdEncoding.DecodeString(stringtodecrypt)
	if err != nil {
		panic(err)
	}

	block, err := aes.NewCipher([]byte(encKey))
	if err != nil {
		panic(err)
	}

	if len(ciphertext)%aes.BlockSize != 0 {
		panic("ciphertext is not a multiple of the block size")
	}

	iv, err := base64.StdEncoding.DecodeString(b64iv)
	if err != nil {
		panic(err)
	}

	mode := cipher.NewCBCDecrypter(block, iv)
	mode.CryptBlocks(ciphertext, ciphertext)

	return string(ciphertext)
}

// NewTokenResponse generates a new encrypted token from the given connection and user info for use with a guacamole-lite tunnel.
func NewTokenResponse(key string, conn GuacdConnection, wssHostPath string) (GuacamoleLiteResponse, error) {
	var resp GuacamoleLiteResponse
	var token string

	inputData, err := json.Marshal(conn)
	if err != nil {
		return resp, err
	}

	if len(key) > 0 {
		inputKey := []byte(key)

		token, err = Encrypt(inputKey, inputData)
		if err != nil {
			return resp, err
		}
	}

	resp.Token = token
	resp.WSS = wssHostPath

	return resp, nil
}

// Pad applies the PKCS #7 padding scheme on the buffer.
// https://leanpub.com/gocrypto/read#leanpub-auto-encrypting-and-decrypting-data-with-aes-cbc
func pad(in []byte) []byte {
	padding := aes.BlockSize - (len(in) % aes.BlockSize)
	if padding == 0 {
		padding = aes.BlockSize
	}
	for i := 0; i < padding; i++ {
		in = append(in, byte(padding))
	}
	return in
}
