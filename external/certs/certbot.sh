#!/bin/bash

set -e

# always run from the directory this script lives in
cd "$(dirname "$0")"

# parse flags
FORCE=false
while getopts ":f" opt; do
  case $opt in
    f) FORCE=true ;;
    *) ;;
  esac
done
shift $((OPTIND - 1))

# get domain from arg 1
DOMAIN="$1"
if [[ -z "$DOMAIN" ]]; then
  echo "Usage: $0 [-f] <domain>"
  exit 1
fi

# basic domain validation to catch typos and prevent shell injection
if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9.*-]+\.[a-zA-Z]{2,}$ ]]; then
  echo "Error: '$DOMAIN' doesn't look like a valid domain."
  echo "Remember that this is doing a DNS challenge, it should probably end with rossvideo.com if you're using our EasyDNS account."
  exit 1
fi

# check docker is available
if ! command -v docker &>/dev/null; then
  echo "Error: docker is not installed or not in PATH."
  exit 1
fi

# check for creds.ini file
if [[ ! -f "creds.ini" ]]; then
  echo "Error: creds.ini file not found. Please create a creds.ini file with your EasyDNS API credentials."
  echo "Example creds.ini content:"
  echo "dns_easydns_usertoken=your_api_key"
  echo "dns_easydns_userkey=your_api_secret"
  echo "dns_easydns_endpoint=https://rest.easydns.net"
  exit 1
fi

# get the user/group ids of the current user
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# ask the user if they really want to run
if [[ "$FORCE" != true ]]; then
  read -p "This will run certbot to obtain a certificate for '$DOMAIN'. You shouldn't just run this without understanding what it does. Do you want to continue? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
  fi
fi

# ensure .gitignore exists to protect secrets and generated files
for entry in .venv/ letsencrypt/ creds.ini; do
    grep -qxF "$entry" .gitignore 2>/dev/null || echo "$entry" >> .gitignore
done

docker run --rm -u "${USER_ID}:${GROUP_ID}" -v "$(pwd):/app" -w /app python:slim bash -c "\
    python -m venv /app/.venv && \
    /app/.venv/bin/pip install certbot certbot-dns-easydns && \
    /app/.venv/bin/certbot certonly \
        --authenticator dns-easydns \
        --non-interactive \
        --agree-tos \
        --dns-easydns-credentials /app/creds.ini \
        --config-dir /app/letsencrypt \
        --work-dir /app/letsencrypt/work \
        --logs-dir /app/letsencrypt/logs \
        -d '${DOMAIN}'"