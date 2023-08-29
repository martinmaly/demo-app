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
: ${SHORT_SHA:=$(git rev-parse --short HEAD)}

[[ -n "${PROJECT_ID}" ]] || { echo "Invoke PROJECT_ID=project-id ${0}"; exit 1; }

set -x
gcloud builds submit --project=${PROJECT_ID} --config="${ROOT}/setup.cloudbuild.yaml" "${ROOT}"
gcloud builds submit --project=${PROJECT_ID} --config="${ROOT}/cloudbuild.yaml" \
  --substitutions=SHORT_SHA=${SHORT_SHA},_SERVICE_ACCOUNT=projects/mmaly-dev-01/serviceAccounts/demo-application-deployer@mmaly-dev-01.iam.gserviceaccount.com \
  "${ROOT}"
