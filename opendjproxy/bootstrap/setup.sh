#!/usr/bin/env sh
# Default setup script
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

#echo "Setting up default OpenDJ instance."
echo "Setting up OpenDJ Proxy Server."

#INIT_OPTION="--addBaseEntry"

#if [ -n "${NUMBER_SAMPLE_USERS+set}" ]; then
#    INIT_OPTION="--sampleData ${NUMBER_SAMPLE_USERS}"
#fi

# todo: We may want to specify a keystore using --usePkcs12keyStore, --useJavaKeystore
echo "Creating Proxy Server..."
/opt/opendj/bin/setup \
 proxy-server \
 --rootUserDN "cn=Directory Manager" \
 --rootUserPassword "$PASSWORD" \
 --hostname localhost \
 --ldapPort 1389 \
 --ldapsPort 1636 \
 --adminConnectorPort 4444 \
 --staticPrimaryServer opendjuser-0.opendjuser.dev.svc.cluster.local:1636 \
 --baseDN $BASE_DN \
 --proxyUserBindDN "cn=Directory Manager" \
 --proxyUserBindPassword "$PASSWORD" \
 --proxyUsingSSL \
 --acceptLicense

echo "Creating Service Discovery Mechanism..."
/opt/opendj/bin/dsconfig \
 create-service-discovery-mechanism \
 --hostname localhost \
 --port 4444 \
 --bindDN "cn=Directory Manager" \
 --bindPassword "$PASSWORD" \
 --mechanism-name "Static Service Discovery Mechanism" \
 --type static \
 --set primary-server:opendjuser-0.opendjuser.dev.svc.cluster.local:1636 \
 --set use-ssl:true \
 --set trust-manager-provider:"JVM Trust Manager" \
 --trustAll \
 --no-prompt

echo "Creating Backend..."
/opt/opendj/bin/dsconfig \
 create-backend \
 --hostname localhost \
 --port 4444 \
 --bindDN "cn=Directory Manager" \
 --bindPassword "$PASSWORD" \
 --backend-name proxyAll \
 --type proxy \
 --set enabled:true \
 --set route-all:true \
 --set proxy-user-dn:"cn=Directory Manager" \
 --set proxy-user-password:"$PASSWORD" \
 --set load-balancing-algorithm:least-requests \
 --set service-discovery-mechanism:"Static Service Discovery Mechanism" \
 --trustAll \
 --no-prompt

echo "Set up of OpenDJ Proxy Server complete."

# If any optional LDIF files are present, load them.

#if [ -d /opt/opendj/bootstrap/ldif ]; then
#   echo "Found optional schema files in bootstrap/ldif. Will load them"
#  for file in /opt/opendj/bootstrap/ldif/*;  do
#      echo "Loading $file"
#       sed -e "s/@BASE_DN@/$BASE_DN/" <${file}  >/tmp/file.ldif
#      /opt/opendj/bin/ldapmodify -D "cn=Directory Manager" -h localhost -p 1389 -w ${PASSWORD} -f /tmp/file.ldif
#  done
#fi
