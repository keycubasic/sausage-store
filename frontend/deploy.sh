#! /bin/bash
set -xe
docker context create remote-frontend --docker "host=ssh://${DEV_USER}@${DEV_HOST}"
docker context use remote-frontend
docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}

NOT_ACTIVE="inactive"

found_active() {
    local line_count=1
    local front_count=$(docker ps -f "name=sausage-frontend" -f "status=running" | wc -l)

    if [[ "$front_count" -gt "$line_count" ]]; then
        echo "active"
    else
        echo "inactive"
    fi
}

FRONT_ACTIVE="$(found_active)"

echo "Starting deployment frontend..."

if [[ "$FRONT_ACTIVE" == "$NOT_ACTIVE" ]]; then
    echo "Init frontend deployment with blue"
    scp ./frontend/conf/blue/default.conf ${DEV_USER}@${DEV_HOST}:/tmp${CI_PROJECT_DIR}/frontend/
    docker compose up frontend
fi

docker context rm -f remote-frontend
echo "Deployment frontend success!"

