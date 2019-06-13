FROM monogramm/docker-frappe:10.1-alpine

LABEL maintainer="Monogramm Maintainers <opensource at monogramm dot io>"

ENV ERPNEXT_BRANCH=v10.1.81

RUN set -ex; \
    bench get-app erpnext https://github.com/frappe/erpnext --branch $ERPNEXT_BRANCH; \
    sudo ./env/bin/pip3 install \
        ldap3 \
    ;

VOLUME ["/home/$FRAPPE_USER/frappe-bench/apps/erpnext/erpnext/public", "/home/$FRAPPE_USER/frappe-bench/apps/frappe/frappe/public"]
