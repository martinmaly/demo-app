#!/usr/bin/env bash
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )

: ${PROJECT_ID:=$(gcloud config get project)}
# Use https://cloud.google.com/sql/docs/mysql/connect-auth-proxy
: ${DATABASE_HOST:="127.0.0.1"}
: ${DATABASE_NAME:=test}

while [[ $# -gt 0 ]]; do
  case "${1}" in
    --project-id ) PROJECT_ID="${2:-}"; shift ;;
    --database   ) DATABASE_NAME="${2:-}"; shift ;;
    --host       ) DATABASE_HOST="${2:-}"; shift ;;

    *) echo "Unrecognized command line parameter: ${1}"; exit 1 ;;
  esac
  shift
done

[[ -n "${PROJECT_ID}" ]]           || { echo "--project-id flag or PROJECT_ID env variable are required"; exit 1;  }
[[ -n "${DATABASE_NAME}" ]]        || { echo "--database flag or DATABASE_NAME env variable are required"; exit 1; }

DB_PASS=$(gcloud secrets versions access latest --secret demo-application-sql-password --project "${PROJECT_ID}")

{
  cd "${ROOT}/cmd/server" ;
  INSTANCE_HOST="${DATABASE_HOST}" \
  DB_USER=backend \
  DB_PASS="${DB_PASS}" \
  DB_NAME="${DATABASE_NAME}" \
  DB_PORT=3306 \
  go run .
}
