#! /bin/bash
set -xe
sudo docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}
sudo docker pull ${CI_REGISTRY_IMAGE}/sausage-backend:${VERSION}
sudo docker pull ${CI_REGISTRY_IMAGE}/sausage-frontend:${VERSION}
cd /tmp${CI_PROJECT_DIR}

export CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE}
export VERSION=${VERSION}
export CI_PROJECT_DIR=${CI_PROJECT_DIR}
#sudo -E docker compose --profile blue down || true
#sudo -E docker compose --profile blue up -d

wait_healthy() {
  local container_name="sausage-backend-$1"
  local retries=5
  echo "Waiting '$container_name' to become healthy..."

  while (( retries > 0 )); do
    if (docker ps -f "name=$container_name" -f health=healthy | wc -l) > 0; then
      echo "Container '$container_name' is healthy"
      exit 0;
    else
      echo "Retrying... ($retries retries left)"
      ((retries--))
      sleep 5
    fi
  done

  echo "Container '$container_name' is unhealthy"
  exit 1
}

found_active() {
  if (docker ps -f "name=sausage-backend-blue" -f "status=running" | wc -l) > 0; then
    echo "blue"
  elif (docker ps -f "name=sausage-backend-green" -f "status=running" | wc -l) > 0; then
    echo "green"
  else
    echo "none"
  fi
}

ACTIVE_COLOR=$(found_active)
echo "Starting deployment..."

if [ "$ACTIVE_COLOR" == "blue" ]; then
  echo "Switch deployment from blue to green"
  docker -E compose --profile green up -d
  wait_healthy "green"
  docker compose --profile blue down || true
elif [ "$ACTIVE_COLOR" == "green" ]; then
  echo "Switch deployment from green to blue"
  docker -E compose --profile blue up -d
  wait_healthy "blue"
  docker compose --profile green down || true
elif [ "$ACTIVE_COLOR" == "none" ]; then
  echo "Init deployment to blue"
  docker -E compose --profile blue up -d
  wait_healthy "blue"
fi

