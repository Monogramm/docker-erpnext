FROM monogramm/docker-frappe:10-stretch

LABEL maintainer="Monogramm Maintainers <opensource at monogramm dot io>"

# Build environment variables
ENV ERPNEXT_BRANCH=v10.x.x

# Setup ERPNext
RUN set -ex; \
    bench get-app --branch $ERPNEXT_BRANCH erpnext https://github.com/frappe/erpnext; \
    sudo ./env/bin/pip3 install \
        ldap3 \
    ;

VOLUME ["/home/$FRAPPE_USER/frappe-bench/apps/erpnext/erpnext/public", "/home/$FRAPPE_USER/frappe-bench/apps/frappe/frappe/public"]
