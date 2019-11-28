##
##    Docker image for ERPNext.
##    Copyright (C) 2019  Monogramm
##
##    This program is free software: you can redistribute it and/or modify
##    it under the terms of the GNU Affero General Public License as published
##    by the Free Software Foundation, either version 3 of the License, or
##    (at your option) any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU Affero General Public License for more details.
##
##    You should have received a copy of the GNU Affero General Public License
##    along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
FROM monogramm/docker-frappe:12-debian-slim

ARG TAG
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION=v12.1.8

LABEL maintainer="Monogramm Maintainers <opensource at monogramm dot io>" \
      product="ERPNext" \
      version=$VERSION \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Monogramm/docker-erpnext" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="ERPNext" \
      org.label-schema.description="Open Source ERP built for the web, supports manufacturing, distribution, retail, trading, services, education, non profits and healthcare." \
      org.label-schema.url="https://erpnext.com/" \
      org.label-schema.vendor="Frappé Technologies Pvt. Ltd" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

# Build environment variables
ENV DOCKER_TAG=${TAG} \
    DOCKER_VCS_REF=${VCS_REF} \
    DOCKER_BUILD_DATE=${BUILD_DATE} \
    ERPNEXT_BRANCH=${VERSION} \
    FRAPPE_APP_PROTECTED='frappe erpnext'

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

VOLUME /home/$FRAPPE_USER/frappe-bench/apps/erpnext/erpnext/public
