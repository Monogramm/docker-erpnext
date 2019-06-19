FROM monogramm/docker-frappe:develop-stretch-slim

LABEL maintainer="Monogramm Maintainers <opensource at monogramm dot io>"

ENV ERPNEXT_BRANCH=develop

RUN set -ex; \
    bench get-app erpnext https://github.com/frappe/erpnext --branch $ERPNEXT_BRANCH; \
    rm -rf /home/$FRAPPE_USER/frappe-bench/apps/erpnext/.git; \
    sudo ./env/bin/pip3 install \
        ldap3 \
    ;

VOLUME ["/home/$FRAPPE_USER/frappe-bench/apps/erpnext/erpnext/public", "/home/$FRAPPE_USER/frappe-bench/apps/frappe/frappe/public"]
