FROM monogramm/docker-frappe:11.1-stretch-slim

LABEL maintainer="Monogramm Maintainers <opensource at monogramm dot io>"

ENV ERPNEXT_BRANCH=v11.1.35

RUN set -ex; \
    bench get-app erpnext https://github.com/frappe/erpnext --branch $ERPNEXT_BRANCH; \
    bench --site localhost install-app erpnext; \
    rm -rf /home/$FRAPPE_USER/frappe-bench/apps/erpnext/.git

VOLUME ["/home/$FRAPPE_USER/frappe-bench/sites/assets", "/home/$FRAPPE_USER/frappe-bench/apps/erpnext/erpnext/public", "/home/$FRAPPE_USER/frappe-bench/apps/frappe/frappe/public"]
