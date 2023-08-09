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
	"demo-application/pkg/mysql"
	"log"
	"time"
)

func run() error {
	database, err := mysql.ConnectToDatabase()
	if err != nil {
		return err
	}

	row := database.QueryRow("SELECT NOW();")
	if err := row.Err(); err != nil {
		return err
	}
	var now time.Time
	if err := row.Scan(&now); err != nil {
		return err
	}

	log.Printf("Server time: %s", now)
	return nil
}

func main() {
	if err := run(); err != nil {
		log.Fatalf("Error: %v", err)
	}
}
