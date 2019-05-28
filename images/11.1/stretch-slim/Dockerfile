FROM monogramm/docker-frappe:stretch-slim

LABEL maintainer="Monogramm Maintainers <opensource at monogramm dot io>"

ENV ERPNEXT_BRANCH=v11.1.34

USER $FRAPPE_USER
WORKDIR /home/$FRAPPE_USER/frappe-bench

RUN bench get-app erpnext https://github.com/frappe/erpnext --branch $ERPNEXT_BRANCH; \
    rm -rf /home/$FRAPPE_USER/frappe-bench/apps/erpnext/.git

VOLUME ["/home/$FRAPPE_USER/frappe-bench/sites/assets", "/home/$FRAPPE_USER/frappe-bench/apps/erpnext/erpnext/public", "/home/$FRAPPE_USER/frappe-bench/apps/frappe/frappe/public"]
