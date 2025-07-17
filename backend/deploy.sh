#! /bin/bash
set -xe
docker context create remote --docker "host=ssh://${DEV_USER}@${DEV_HOST}"
docker context use remote
docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}
docker pull ${CI_REGISTRY_IMAGE}/sausage-backend:${VERSION}
docker pull ${CI_REGISTRY_IMAGE}/sausage-frontend:${VERSION}

export CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE}
export VERSION=${VERSION}
export CI_PROJECT_DIR=${CI_PROJECT_DIR}
#sudo -E docker compose --profile blue down || true
#sudo -E docker compose --profile blue up -d
export BLUE_COLOR="blue"
export GREEN_COLOR="green"
export NONE_COLOR="none"

wait_healthy() {
  local container_name="sausage-backend-$1"
  local line_count=1
  local retries=5
  echo "Waiting '$container_name' to become healthy..."

  while (( retries > 0 )); do
      healthy_count=$(docker ps -f "name=$container_name" -f health=healthy | wc -l)
      if [[ "$healthy_count" -gt "$line_count" ]]
          then
              echo "Container '$container_name' is healthy"
              return 1;
          else
              echo "Retrying... ($retries retries left)"
              ((retries--))
              sleep 5
      fi
  done

  echo "Container '$container_name' is unhealthy"
  return 0
}

found_active() {
    local line_count=1
    local blue_count=$(docker ps -f "name=sausage-backend-blue" -f "status=running" | wc -l)
    local green_count=$(docker ps -f "name=sausage-backend-green" -f "status=running" | wc -l)

    if [[ "$blue_count" -gt "$line_count" ]]; then
        echo "blue"
    elif [[ "$green_count" -gt "$line_count" ]]; then
        echo "green"
    else
        echo "none"
    fi
}

export ACTIVE_COLOR="$(found_active)"

echo "Starting deployment..."

if [[ "$ACTIVE_COLOR" == "$GREEN_COLOR" ]]; then
    echo "Switch deployment from green to blue"
    scp ./frontend/conf/blue/default.conf ${DEV_USER}@${DEV_HOST}:/tmp${CI_PROJECT_DIR}/frontend/
    docker compose --profile blue up -d
    wait_healthy "blue"
    docker stop sausage-backend-green || true
    docker rm sausage-backend-green || true
elif [[ "$ACTIVE_COLOR" == "$BLUE_COLOR" ]]; then
    echo "Switch deployment from blue to green"
    scp ./frontend/conf/green/default.conf ${DEV_USER}@${DEV_HOST}:/tmp${CI_PROJECT_DIR}/frontend/
    docker compose --profile green up -d
    wait_healthy "green"
    docker stop sausage-backend-blue || true
    docker rm sausage-backend-blue || true
elif [[ "$ACTIVE_COLOR" == "$NONE_COLOR" ]]; then
    echo "Init deployment to blue"
    scp ./frontend/conf/blue/default.conf ${DEV_USER}@${DEV_HOST}:/tmp${CI_PROJECT_DIR}/frontend/
    docker compose --profile blue up -d
    wait_healthy "blue"
fi

echo "Deployment success!"
