#! /bin/bash
set -xe
docker context create remote --docker "host=ssh://${DEV_USER}@${DEV_HOST}"
docker context use remote
docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}
docker compose up sausage-frontend
docker context rm remote

