FROM casjaysdevdocker/debian:latest AS build

ARG BUILD_DATE="$(date +'%Y-%m-%d %H:%M')" 

LABEL \
  org.label-schema.name="Full proxy server" \
  org.label-schema.description="" \
  org.label-schema.url="https://hub.docker.com/r/casjaysdevdocker/squid" \
  org.label-schema.vcs-url="https://github.com/casjaysdevdocker/squid" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$BUILD_DATE \
  org.label-schema.vcs-ref=$BUILD_DATE \
  org.label-schema.license="WTFPL" \
  org.label-schema.vcs-type="Git" \
  org.label-schema.schema-version="latest" \
  org.label-schema.vendor="CasjaysDev" \
  maintainer="CasjaysDev <docker-admin@casjaysdev.com>" 

ENV \
  HOSTNAME=proxy \
  SQUID_HOME_DIR=/var/lib/squid \
  SQUID_CACHE_DIR=/data/cache/squid \
  SQUID_LOG_DIR=/data/log/squid \
  SQUID_USER=squid

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yy \
  net-tools \
  postfix \
  apache2 \
  apache2-bin \
  libapache2-mod-fcgid \
  libapache2-mod-geoip \
  libapache2-mod-proxy-uwsgi \
  libapache2-mod-fcgid \
  libapache2-mod-wsgi-py3 \
  squid \
  squid-cgi \
  squidclient \
  e2guardian \
  c-icap \
  && apt-get remove -yy --purge exim* \
  && rm -rf /var/lib/apt/lists/* /etc/apache2/* \
  && mkdir -p /config /data \
  && { grep -qs "$SQUID_USER" /etc/passwd || useradd -d "$SQUID_HOME_DIR" -r -U -m "$SQUID_USER"; } \
  && chown -R "$SQUID_USER":"$SQUID_USER" "/config" "/data"

ADD ./config/. /etc/
ADD ./bin/. /usr/local/bin/

ADD ./data/. /usr/local/share/squidFiles/data/
ADD ./config/. /usr/local/share/squidFiles/config/

FROM scratch

COPY --from=build /. /

EXPOSE 3128 8080
WORKDIR /config
VOLUME ["/config", "/data"]

HEALTHCHECK --start-period=1m --interval=10m --timeout=3s CMD ["/usr/local/bin/entrypoint-squid.sh","healthcheck"]
ENTRYPOINT ["/usr/local/bin/entrypoint-squid.sh"]
