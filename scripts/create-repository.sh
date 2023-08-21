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

[[ -n "${PROJECT_ID}" ]]          || { echo "PROJECT_ID env variable are required"; exit 1; }
[[ -n "${REPOSITORY_NAME}" ]]     || { echo "REPOSITORY_NAME env variable are required"; exit 1; }
[[ -n "${REPOSITORY_LOCATION}" ]] || { echo "REPOSITORY_LOCATION env variable are required"; exit 1; }

set -x
gcloud artifacts repositories describe "${REPOSITORY_NAME}" --project="${PROJECT_ID}" --location=us > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  gcloud artifacts repositories create ${REPOSITORY_NAME} --project="${PROJECT_ID}" --location=us --repository-format=docker 
fi
