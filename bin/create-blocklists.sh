#!/usr/bin/env bash

SQUID_USER="${SQUID_USER:-squid}"
SQUID_LOG_DIR="${SQUID_LOG_DIR:-/data/log/squid}"
REDIRECT_URL="${REDIRECT_URL:-}"
BLOCKLIST="${BLOCKLIST:-https://github.com/casjay/resources/raw/main/files/shallalist.tar.gz}"
BLOCKED_CATEGORIES="${BLOCKED_CATEGORIES:-adv,aggressive,porn,spyware,violence,warez}"

CONFIG_FILE="/etc/squidguard/squidGuard.conf"
DB_LOCATION="/data/squidguard/db"
LOG_LOCATION="/data/log"

echo "Downloading blocklist..."
wget -q "${BLOCKLIST}" -O /tmp/blocklist.tgz

echo "Extracting blocklist..."
mkdir -p /tmp/blocklist
tar xzf /tmp/blocklist.tgz --strip-components=1 -C /tmp/blocklist

echo "Creating config file..."
rm "${CONFIG_FILE}"
touch "${CONFIG_FILE}"

echo "dbhome ${DB_LOCATION}" >>"${CONFIG_FILE}"
echo "logdir ${LOG_LOCATION}" >>"${CONFIG_FILE}"

for CATEGORY in $(echo ${BLOCKED_CATEGORIES} | sed "s/,/ /g"); do
  if [ ! -d "/tmp/blocklist/${CATEGORY}" ]; then
    echo "Category ${CATEGORY} not available!"
    exit 1
  fi

  cp -r "/tmp/blocklist/${CATEGORY}" "${DB_LOCATION}/"

  echo "dest ${CATEGORY} {" >>"${CONFIG_FILE}"

  if [ -e "${DB_LOCATION}/${CATEGORY}/domains" ]; then
    echo "  domainlist ${CATEGORY}/domains" >>"${CONFIG_FILE}"
  fi

  if [ -e "${DB_LOCATION}/${CATEGORY}/urls" ]; then
    echo "  urllist ${CATEGORY}/urls" >>"${CONFIG_FILE}"
  fi

  if [ -e "${DB_LOCATION}/${CATEGORY}/expressions" ]; then
    echo "  expressionlist ${CATEGORY}/expressions" >>"${CONFIG_FILE}"
  fi

  echo "}" >>"${CONFIG_FILE}"
done

NOT_LIST="${BLOCKED_CATEGORIES//,/ !}"

{
  echo "acl {"
  echo "  default {"
  echo "    pass !${NOT_LIST} all"
  echo "    redirect $REDIRECT_URL"
  echo "  }"
  echo "}"
} >>"${CONFIG_FILE}"

squidGuard -b -d -C all

chown -R ${SQUID_USER}:${SQUID_USER} "${DB_LOCATION}"
chown -R ${SQUID_USER}:${SQUID_USER} "${LOG_LOCATION}"
chown -R ${SQUID_USER}:${SQUID_USER} "${CONFIG_FILE}"

echo "Cleanup..."
rm -rf /tmp/*
