// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

type lw struct {
	status int
	w      http.ResponseWriter
}

var _ http.ResponseWriter = &lw{}

func (w *lw) Header() http.Header {
	return w.w.Header()
}

func (w *lw) Write(b []byte) (int, error) {
	return w.w.Write(b)
}

func (w *lw) WriteHeader(statusCode int) {
	w.status = statusCode
	w.w.WriteHeader(statusCode)
}

func loggingHandler(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t := time.Now()
		lw := &lw{w: w}

		h.ServeHTTP(lw, r)

		fmt.Fprintf(os.Stderr, "[%s] %s %s %s -> %d %s\n", t.Format(time.StampMilli), r.RemoteAddr, r.Method, r.RequestURI, lw.status, http.StatusText(lw.status))
	})
}
