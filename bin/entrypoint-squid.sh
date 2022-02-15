#!/usr/bin/env bash
set -e

if [ "$1" = "healthcheck" ]; then
  squidclient -h localhost cache_object://localhost/counters
  exit $?
fi

SQUID_USER="${SQUID_USER:-squid}"
SQUID_LOG_DIR="${SQUID_LOG_DIR:-/data/log/squid}"
SQUID_CACHE_DIR="${SQUID_CACHE_DIR:-/data/cache/squid}"
HOSTNAME="${HOSTNAME:-$(hostname -f)}"

mkdir -p "/config" "/data"

for dir in apache2 e2guardian squid squidguard; do
  if [ -f "/usr/local/share/squidFiles/$dir" ]; then
    cp -Rf "/usr/local/share/squidFiles/$dir" "/config/$dir"
  elif [ -d "/usr/local/share/squidFiles/$dir" ]; then
    cp -Rf "/usr/local/share/squidFiles/$dir/." "/config/$dir/"
  else
    cp -Rf "/usr/local/share/squidFiles/data/." "/data/"
    cp -Rf "usr/local/share/squidFiles/config/." "/config/"
  fi
done

mkdir -p "${SQUID_LOG_DIR}" "${SQUID_CACHE_DIR}"
mkdir -p "/data/log/squidguard" "/data/log/e2guardian" "/data/squidguard/db"
chown -Rf ${SQUID_USER}:${SQUID_USER} "/config" "/data"
chmod -Rf 755 "${SQUID_LOG_DIR}"

cp -Rf "/config/." "/etc/"

if [ "${UPDATE_BLACKLIST_URL}" != "" ]; then
  sudo wget -O backlist.tar.gz ${UPDATE_BLACKLIST_URL} &&
    tar -xzf backlist.tar.gz -C "/data/squidguard/db" &&
    rm -Rf backlist.tar.gz &&
    chown -Rf ${SQUID_USER}:${SQUID_USER} "/data/squidguard/db"
fi

if [ "${WPAD_IP}" != "" ]; then
  sed 's/{{WPAD_IP}}/'"${WPAD_IP}"'/' -i "/data/htdocs/www/wpad.dat"
  sed 's/{{WPAD_NOPROXY_NET}}/'"${WPAD_NOPROXY_NET}"'/' -i "/data/htdocs/www/wpad.dat"
  sed 's/{{WPAD_NOPROXY_MASK}}/'"${WPAD_NOPROXY_MASK}"'/' -i "/data/htdocs/www/wpad.dat"
fi

# allow arguments to be passed to squid
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == squid || ${1} == $(which squid) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# start apache to serve wpad.dat file and or block.html
sudo /etc/init.d/apache2 restart

# default behaviour is to launch squid
if [[ -z ${1} ]]; then
  if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
    echo "Initializing cache..."
    $(which squid) -N -f /etc/squid/squid.conf -z
  fi
  echo "Starting squid..."
  exec $(which squid) -f /etc/squid/squid.conf -NYCd 1 ${EXTRA_ARGS}
else
  exec "$@"
fi
