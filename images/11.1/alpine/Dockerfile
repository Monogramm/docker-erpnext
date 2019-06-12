FROM monogramm/docker-frappe:11.1-alpine

LABEL maintainer="Monogramm Maintainers <opensource at monogramm dot io>"

ENV ERPNEXT_BRANCH=v11.1.38

RUN set -ex; \
    bench get-app erpnext https://github.com/frappe/erpnext --branch $ERPNEXT_BRANCH; \
    rm -rf /home/$FRAPPE_USER/frappe-bench/apps/erpnext/.git; \
    sudo pip install \
        ldap3 \
    ;

VOLUME ["/home/$FRAPPE_USER/frappe-bench/apps/erpnext/erpnext/public", "/home/$FRAPPE_USER/frappe-bench/apps/frappe/frappe/public"]
