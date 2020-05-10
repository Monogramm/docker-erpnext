FROM monogramm/docker-erpnext:13-alpine

COPY docker_test.sh /docker_test.sh

RUN set -ex; \
    sudo chmod 755 /docker_test.sh;

CMD ["/docker_test.sh"]
