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
  container_name="sausage-backend-$1"
  line_count = 1
  retries=5
  echo "Waiting '$container_name' to become healthy..."

  while (( retries > 0 )); do
    healthy_count=$(docker ps -f "name=$container_name" -f health=healthy | wc -l)
    if [[ $healthy_count -gt $line_count ]]
      then
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
  line_count=1
  blue_count=$(docker ps -f "name=sausage-backend-blue" -f "status=running" | wc -l)
  green_count=$(docker ps -f "name=sausage-backend-green" -f "status=running" | wc -l)
  if [[ $blue_count -gt $line_count ]]; then
    echo "blue"
  elif [[ $green_count -gt $line_count ]]; then
    echo "green"
  else
    echo "none"
  fi
}

ACTIVE_COLOR="$(found_active)"
BLUE="blue"
GREEN="green"
NONE="none"
echo "Starting deployment..."

if [[ $ACTIVE_COLOR == $BLUE ]]; then
  echo "Switch deployment from blue to green"
  # sudo -E docker compose --profile green up -d
  # wait_healthy "green"
  # sudo -E docker compose --profile blue down || true
elif [[ $ACTIVE_COLOR == $GREEN ]]; then
  echo "Switch deployment from green to blue"
  # sudo -E docker compose --profile blue up -d
  # wait_healthy "blue"
  # sudo -E docker compose --profile green down || true
elif [[ $ACTIVE_COLOR == $NONE ]]; then
  echo "Init deployment to blue"
  # sudo -E docker compose --profile blue up -d
  # wait_healthy "blue"
fi

