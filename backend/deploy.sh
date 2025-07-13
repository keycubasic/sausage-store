#! /bin/bash
set -xe
sudo docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}
sudo docker pull ${CI_REGISTRY_IMAGE}/sausage-backend:${VERSION}
sudo docker pull ${CI_REGISTRY_IMAGE}/sausage-frontend:${VERSION}
#sudo docker network create -d bridge sausage_network || true
#sudo docker rm -f sausage-backend || true
#sudo docker run --rm -d --name sausage-backend -p 8080:8080 --network=sausage_network "${CI_REGISTRY_IMAGE}"/sausage-backend:${VERSION}
cd /tmp${CI_PROJECT_DIR}

export CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE}
export VERSION=${VERSION}
export CI_PROJECT_DIR=${CI_PROJECT_DIR}
sudo -E docker compose down || true
sudo -E docker compose up -d


#found_healthy() {
#  local container_name="sausage-backend-$1"
#  if (docker ps -f "name=$container_name" -f health=healthy | wc -l) > 0; then
#    echo "Container '$container_name' is healthy"
#    return 1;
#  fi

#  echo "Container '$container_name' is unhealthy"
#  return 0
#}
