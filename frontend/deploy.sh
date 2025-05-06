#! /bin/bash
#Если свалится одна из команд, рухнет и весь скрипт
set -xe
#Перезаливаем дескриптор сервиса на ВМ для деплоя
sudo rm -f /opt/sausage-store/static/dist/sausage-store.tar.gz||true
sudo rm -f /opt/sausage-store/static/dist/frontend/*||true
#Качаем и заспаковываем артефакты в нужную папку
echo
sudo curl -u ${NEXUS_REPO_USER}:${NEXUS_REPO_PASS} -o sausage-store.tar.gz ${NEXUS_REPO_URL}/repository/${NEXUS_REPO_FRONTEND_NAME}/${VERSION}/sausage-store-${VERSION}.tar.gz
sudo tar xfv ./sausage-store.tar.gz -C /opt/sausage-store/static/dist/frontend/||true
#Обновляем конфиг systemd с помощью рестарта
sudo systemctl daemon-reload
#Перезапускаем сервис сосисочной
sudo systemctl restart frontend
