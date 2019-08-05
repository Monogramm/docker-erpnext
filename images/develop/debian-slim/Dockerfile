FROM monogramm/docker-frappe:develop-debian-slim

LABEL maintainer="Monogramm Maintainers <opensource at monogramm dot io>"

# Build environment variables
ENV ERPNEXT_BRANCH=develop

# Setup ERPNext
RUN set -ex; \
    mkdir -p "/home/$FRAPPE_USER/frappe-bench/logs"; \
    chmod 777 "/home/$FRAPPE_USER/frappe-bench/logs"; \
    bench get-app --branch $ERPNEXT_BRANCH erpnext https://github.com/frappe/erpnext; \
    sudo ./env/bin/pip3 install \
        ldap3 \
    ;

VOLUME ["/home/$FRAPPE_USER/frappe-bench/apps/erpnext/erpnext/public", "/home/$FRAPPE_USER/frappe-bench/apps/frappe/frappe/public"]
