#!/usr/bin/env bash

export SQUID_PORT="${SQUID_PORT:-3127}"
export E2GUARD_PORT="${E2GUARD_PORT:-3128}"
export APACHE2_PORT="${APACHE2_PORT:-8080}"

export SQUID_USER="${SQUID_USER:-squid}"
export APACHE2_USER="${APACHE2_USER:-www-data}"
export E2GUARD_USER="${E2GUARD_USER:-e2guardian}"

export SQUID_LOG_DIR="${SQUID_LOG_DIR:-/data/log/squid}"
export SQUID_CACHE_DIR="${SQUID_CACHE_DIR:-/data/cache/squid}"
export HOSTNAME="${HOSTNAME:-$(hostname -f)}"

__init() {
  mkdir -p "/config" "/data"

  for dir in apache2 e2guardian squid squidguard; do
    if [ -f "/usr/local/share/squidFiles/$dir" ]; then
      cp -Rf "/usr/local/share/squidFiles/$dir" "/config/$dir"
    elif [ -d "/usr/local/share/squidFiles/$dir" ]; then
      cp -Rf "/usr/local/share/squidFiles/$dir/." "/config/$dir/"
    else
      cp -Rf "/usr/local/share/squidFiles/data/." "/data/"
      cp -Rf "/usr/local/share/squidFiles/config/." "/config/"
    fi
  done

  mkdir -p "/data/log/squidguard" "/data/log/e2guardian" "/data/squidguard/db"
  mkdir -p "${SQUID_LOG_DIR}" "${SQUID_CACHE_DIR}" "/data/log/apache2" "/data/htdocs/cgi-bin"
  chown -Rf ${SQUID_USER}:${SQUID_USER} "/config" "/data"
  chown -Rf ${E2GUARD_USER}:${E2GUARD_USER} "/data/log/e2guardian" "/config/e2guardian"
  chown -Rf ${APACHE2_USER}:${APACHE2_USER} "/data/htdocs" "/config/apache2" "/data/log/apache2"
  chmod -Rf 777 "${SQUID_LOG_DIR}" "${SQUID_CACHE_DIR}" "/data/log/e2guardian"

  if [ "${WPAD_IP}" != "" ]; then
    sed 's/{{WPAD_IP}}/'"${WPAD_IP}"'/' -i "/data/htdocs/www/wpad.dat"
    sed 's/{{WPAD_NOPROXY_NET}}/'"${WPAD_NOPROXY_NET}"'/' -i "/data/htdocs/www/wpad.dat"
    sed 's/{{WPAD_NOPROXY_MASK}}/'"${WPAD_NOPROXY_MASK}"'/' -i "/data/htdocs/www/wpad.dat"
  fi

  if [ -f "/config/apache2/apache2.conf" ]; then
    sed -i "s|SERVERNAME|$HOSTNAME|g" "/config/apache2/apache2.conf"
    sed -i "s|REPLACE_SQUID_USER|$SQUID_USER|g" "/config/apache2/apache2.conf"
    sed -i "s|REPLACE_HTTP_PORT|$APACHE2_PORT|g" "/config/apache2/apache2.conf"
  fi

  if [ -f "/config/e2guardian/e2guardian.conf" ]; then
    sed -i "s|SQUID_PORT|$SQUID_PORT|g" "/config/e2guardian/e2guardian.conf"
    sed -i "s|E2GUARD_PORT|$E2GUARD_PORT|g" "/config/e2guardian/e2guardian.conf"
    sed -i "s|REPLACE_SQUID_USER|$SQUID_USER|g" "/config/e2guardian/e2guardian.conf"
  fi

  if [ -f "/config/squid/squid.conf" ]; then
    sed -i "s|SERVERNAME|$HOSTNAME|g" "/config/squid/squid.conf"
    sed -i "s|SQUID_PORT|$SQUID_PORT|g" "/config/squid/squid.conf"
  fi

  cp -Rf "/config/." "/etc/"

  if [ "$(find /data/squidguard/db/* 2>/dev/null | wc -l)" -eq 0 ]; then
    /usr/local/bin/create-blocklists.sh
  fi

  if [ "${UPDATE_BLACKLIST_URL}" != "" ]; then
    sudo wget -O /tmp/backlist.tar.gz ${UPDATE_BLACKLIST_URL} &&
      tar -xzf /tmp/backlist.tar.gz -C "/data/squidguard/db" &&
      rm -Rf /tmp/backlist.tar.gz &&
      chown -Rf ${SQUID_USER}:${SQUID_USER} "/data/squidguard/db"
  fi

  if [ ! -f "/data/htdocs/cgi-bin/cachemgr.cgi" ]; then
    cp -Rf "/usr/lib/cgi-bin/cachemgr.cgi" "/data/htdocs/cgi-bin/cachemgr.cgi"
  fi

  if [ ! -f "/data/htdocs/cgi-bin/e2guardian.pl" ]; then
    cp -Rf "/usr/lib/cgi-bin/e2guardian.pl" "/data/htdocs/cgi-bin/e2guardian.pl"
  fi

  # allow arguments to be passed to squid
  if [[ ${1:0:1} = '-' ]]; then
    EXTRA_ARGS=("$@")
    set --
  elif [[ ${1} == squid || ${1} == $(which squid) ]]; then
    EXTRA_ARGS=("${@:2}")
    set --
  fi
}

case "$1" in
healthcheck)
  squidclient -h localhost -p $SQUID_PORT cache_object://localhost/counters
  exit $?
  ;;

update)
  shift 1
  /usr/local/bin/create-blocklists.sh
  exit $?
  ;;

bash | shell | sh)
  exec /bin/bash -l
  ;;

*)
  __init "$@"
  if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
    echo "Initializing cache..."
    $(which squid) -N -f "/config/squid/squid.conf" -z
  fi

  echo "Starting apache web server..."
  [ -f "/var/run/apache2.pid" ] && rm -R /var/run/apache2.pid
  apache2 -D FOREGROUND -f "/config/apache2/apache2.conf" &

  echo "Starting e2guardian..."
  e2guardian -N -c "/config/e2guardian/e2guardian.conf" &

  echo "Starting squid..."
  squid -f "/config/squid/squid.conf" -NYCd 1 ${EXTRA_ARGS} &
  exec tail -f /data/log/*/*
  ;;
esac
