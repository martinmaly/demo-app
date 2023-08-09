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
[[ -n "${PROJECT_ID}" ]] || { echo "Invoke PROJECT_ID=project-id ${0}"; exit 1; }

: ${BUCKET:="${PROJECT_ID}-terraform"}
gsutil mb "gs://${BUCKET}" > /dev/null 2>&1 || echo "Bucket ${BUCKET} likely already exists ..."

. "${ROOT}/scripts/tf-backend.sh"

cd ${ROOT}/infra && \
  terraform init -backend-config="bucket=${BUCKET}"
