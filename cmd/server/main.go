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
	"database/sql"
	"demo-application/pkg/mysql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

var (
	database          *sql.DB
	service, revision string
)

func main() {
	// Initialize template parameters.
	service = os.Getenv("K_SERVICE")
	if service == "" {
		service = "???"
	}

	revision = os.Getenv("K_REVISION")
	if revision == "" {
		revision = "???"
	}

	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	db, err := mysql.ConnectToDatabase()
	if err != nil {
		return err
	}
	database = db

	// Define HTTP server.
	http.Handle("/time", loggingHandler(http.HandlerFunc(timeHandler)))

	fs := http.FileServer(http.Dir("./static"))
	http.Handle("/", loggingHandler(fs))

	// PORT environment variable is provided by Cloud Run.
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		return err
	}

	return nil
}

func queryDatabaseTime() (time.Time, error) {
	row := database.QueryRow("SELECT NOW();")
	if err := row.Err(); err != nil {
		return time.Time{}, err
	}
	var now time.Time
	if err := row.Scan(&now); err != nil {
		return time.Time{}, err
	}
	return now, nil
}

type TimeResponse struct {
	Now      time.Time `json:"now,omitempty"`
	Service  string    `json:"service,omitempty"`
	Revision string    `json:"revision,omitempty"`
}

// timeHandler responds to requests by returning current time on the SQL Server
func timeHandler(w http.ResponseWriter, r *http.Request) {
	now, err := queryDatabaseTime()
	var result any
	var status int
	if err != nil {
		status = http.StatusInternalServerError
		result = struct {
			Error string `json:"error,omitempty"`
		}{
			Error: err.Error(),
		}
	} else {
		status = http.StatusOK
		result = TimeResponse{
			Now:      now,
			Service:  service,
			Revision: revision,
		}
	}

	w.Header().Add("Content-Type", "application/json")

	out, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(fmt.Sprintf("{ \"error\": %q }", err.Error())))
		return
	}

	w.WriteHeader(status)
	w.Write(out)
}
