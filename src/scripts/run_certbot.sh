#!/bin/bash

# Source in util.sh so we can have our nice tools
. $(cd $(dirname $0); pwd)/util.sh

# We require an email to register the ssl certificate for
if [ -z "$CERTBOT_EMAIL" ]; then
    error "CERTBOT_EMAIL environment variable undefined; certbot will do nothing"
    exit 1
fi

if [ -z "$CERTBOT_SYNC_CONFIG" ]; then
    error "CERTBOT_SYNC_CONFIG environment variable undefined; /etc/letsencrypt cannot be backed up"
    exit 1
fi

if [ -z "$CERTBOT_SYNC_CONFIG_TARBALL_FILEPATH" ]; then
    error "CERTBOT_SYNC_CONFIG_TARBALL_FILEPATH environment variable undefined; /etc/letsencrypt cannot be backed up"
    exit 1
fi

if [ -z "$NGINX_SYNC_CONFIG_TARBALL_FILEPATH" ]; then
    error "NGINX_SYNC_CONFIG_TARBALL_FILEPATH environment variable undefined; /etc/nginx/conf.d cannot be backed up"
    exit 1
fi

exit_code=0
set -x

if [ "$CERTBOT_SYNC_CONFIG" = 1 ] || [ "$(echo "$CERTBOT_SYNC_CONFIG" | tr '[:upper:]' '[:lower:]')" = true ]; then
    echo "Pulling Certbot config from storage"
    rm -fr /etc/letsencrypt
    mkdir -m 755 /etc/letsencrypt
    if [ -f "$CERTBOT_SYNC_CONFIG_TARBALL_FILEPATH" ]; then
        cd /etc/letsencrypt && tar xf "$CERTBOT_SYNC_CONFIG_TARBALL_FILEPATH"
    else
        echo "Could not find CERTBOT_SYNC_CONFIG_TARBALL_FILEPATH: $CERTBOT_SYNC_CONFIG_TARBALL_FILEPATH"
    fi

    echo "Pulling nginx config from storage"
    if [ -f "$NGINX_SYNC_CONFIG_TARBALL_FILEPATH" ]; then
        rm -fr /etc/nginx/conf.d
        mkdir -m 755 /etc/nginx/conf.d
        cd /etc/nginx/conf.d && tar xf "$NGINX_SYNC_CONFIG_TARBALL_FILEPATH"
    else
        echo "Could not find NGINX_SYNC_CONFIG_TARBALL_FILEPATH: $NGINX_SYNC_CONFIG_TARBALL_FILEPATH"
    fi
fi

# Loop over every domain we can find
for domain in $(parse_domains); do
    if is_renewal_required $domain; then
        # Renewal required for this doman.
        # Last one happened over a week ago (or never)
        if ! get_certificate $domain $CERTBOT_EMAIL; then
            error "Cerbot failed for $domain. Check the logs for details."
            exit_code=1 
        fi
    else
        echo "Not run certbot for $domain; last renewal happened just recently."
    fi
done

if [ "$CERTBOT_SYNC_CONFIG" = 1 ] || [ "$(echo "$CERTBOT_SYNC_CONFIG" | tr '[:upper:]' '[:lower:]')" = true ]; then
    echo "Pushing Certbot config to storage"
    cd /etc/letsencrypt && tar cvf "$CERTBOT_SYNC_CONFIG_TARBALL_FILEPATH" .
    
    echo "Pushing nGinx config to storage"
    cd /etc/nginx/conf.d && tar cvf "$NGINX_SYNC_CONFIG_TARBALL_FILEPATH" .
fi

# After trying to get all our certificates, auto enable any configs that we
# did indeed get certificates for
# auto_enable_configs

set +x
exit $exit_code
