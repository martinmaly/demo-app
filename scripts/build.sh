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

set -x

REGISTRY='demo-application'

gcloud artifacts repositories describe ${REGISTRY} --location=us > /dev/null 2>&1
if [ $? -ne 0 ]; then
  gcloud artifacts repositories create ${REGISTRY} --repository-format=docker --location=us
fi

TAG_NAME="$(git rev-parse --short HEAD)"
gcloud builds submit --project=${PROJECT_ID} --config="${ROOT}/cloudbuild.yaml" --substitutions=TAG_NAME=${TAG_NAME} "${ROOT}"
