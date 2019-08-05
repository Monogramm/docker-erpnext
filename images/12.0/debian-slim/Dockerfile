FROM monogramm/docker-frappe:12-debian-slim

LABEL maintainer="Monogramm Maintainers <opensource at monogramm dot io>"

# Build environment variables
ENV ERPNEXT_BRANCH=v12.0.4

# Setup ERPNext
RUN set -ex; \
    sudo mkdir -p "/home/$FRAPPE_USER"/frappe-bench/logs; \
    sudo touch "/home/$FRAPPE_USER"/frappe-bench/logs/bench.log; \
    sudo chmod 777 \
        "/home/$FRAPPE_USER"/frappe-bench/logs \
        "/home/$FRAPPE_USER"/frappe-bench/logs/* \
    ; \
    bench get-app --branch $ERPNEXT_BRANCH erpnext https://github.com/frappe/erpnext; \
    sudo ./env/bin/pip3 install \
        ldap3 \
    ;

VOLUME ["/home/$FRAPPE_USER/frappe-bench/apps/erpnext/erpnext/public", "/home/$FRAPPE_USER/frappe-bench/apps/frappe/frappe/public"]
