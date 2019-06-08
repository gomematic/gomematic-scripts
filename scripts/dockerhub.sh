#!/usr/bin/env bash

#
# Copyright 2018 Thomas Boerger <thomas@webhippie.de>
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
#

set -eo pipefail

if [ -z "${DOCKER_USERNAME}" ]; then
    echo "Please export DOCKER_USERNAME!"
    exit 1
fi

if [ -z "${DOCKER_PASSWORD}" ]; then
    echo "Please export DOCKER_PASSWORD!"
    exit 1
fi

echo "> fetching token"
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'"${DOCKER_USERNAME}"'", "password": "'"${DOCKER_PASSWORD}"'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

echo "> fetching repos"
REPOS=$(curl -s -H "Authorization: JWT ${TOKEN}" -H "Content-Type: application/json" https://hub.docker.com/v2/repositories/gomematic/?page_size=1000 | jq -r '.results|.[]|.name')

for REPO in ${REPOS}; do
    case "${REPO}" in
        *-cli)
            TITLE="Gomematic: CLI client"
            ;;
        *-api)
            TITLE="Gomematic: API server"
            ;;
        *-ui)
            TITLE="Gomematic: Web UI"
            ;;
        *)
            echo "> skipping ${REPO}"
            continue
            ;;
    esac

    DESCRIPTION=(
        '# '"${TITLE}"' [![Build Status](https://cloud.drone.io/api/badges/gomematic/'"${REPO}"'/status.svg)](https://cloud.drone.io/gomematic/'"${REPO}"') [![](https://images.microbadger.com/badges/image/gomematic/'"${REPO}"'.svg)](http://microbadger.com/images/gomematic/'"${REPO}"' \"Get your own image badge on microbadger.com\")'
        '\n'
        'Managed by [gomematic/'"${REPO}"'](https://github.com/gomematic/'"${REPO}"'), built and pushed with [Drone CI](https://cloud.drone.io/gomematic/'"${REPO}"').'
    )

    PAYLOAD=$(mktemp)
    echo '{"description": "'"${TITLE}"'", "full_description": "'"${DESCRIPTION[*]}"'"}' >| "${PAYLOAD}"

    echo "> updating ${REPO}"
    curl --fail -o /dev/null -H "Authorization: JWT ${TOKEN}" -H "Content-Type: application/json" -X PATCH --data-binary @"${PAYLOAD}" https://hub.docker.com/v2/repositories/gomematic/"${REPO}"/
done
