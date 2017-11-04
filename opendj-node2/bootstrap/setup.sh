#!/usr/bin/env sh
# Default setup script
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

echo "Setting up default OpenDJ instance."

INIT_OPTION="--addBaseEntry"

if [ -n "${NUMBER_SAMPLE_USERS+set}" ]; then
    INIT_OPTION="--sampleData ${NUMBER_SAMPLE_USERS}"
fi

secondary=`hostname -f`
primary=`echo $secondary | sed 's/node2/node1/g'`
remote_node=$primary
local_node=$secondary

# todo: We may want to specify a keystore using --usePkcs12keyStore, --useJavaKeystore
/opt/opendj/setup -p 1389 --ldapsPort 1636 --enableStartTLS  \
  --adminConnectorPort 4444 \
  --baseDN $BASE_DN -h localhost --rootUserPassword "$PASSWORD" \
  --acceptLicense \
  ${INIT_OPTION}

# If any optional LDIF files are present, load them.

if [ -d /opt/opendj/bootstrap/ldif ]; then
   echo "Found optional schema files in bootstrap/ldif. Will load them"
  for file in /opt/opendj/bootstrap/ldif/*;  do
      echo "Loading $file"
       sed -e "s/@BASE_DN@/$BASE_DN/" <${file}  >/tmp/file.ldif
      /opt/opendj/bin/ldapmodify -D "cn=Directory Manager" -h localhost -p 1389 -w ${PASSWORD} -f /tmp/file.ldif
  done
fi

# Configuring Replication
echo "Enabling Replication..."
/opt/opendj/bin/dsreplication \
configure \
--adminUID admin \
--adminPassword password \
--baseDN $BASE_DN \
--host1 $primary \
--port1 4444 \
--bindDN1 "cn=Directory Manager" \
--bindPassword1 ${PASSWORD} \
--replicationPort1 8989 \
--secureReplication1 \
--host2 $secondary \
--port2 4444 \
--bindDN2 "cn=Directory Manager" \
--bindPassword2 ${PASSWORD} \
--replicationPort2 8989 \
--secureReplication2 \
--trustAll \
--no-prompt

echo "Replication Enabled."
echo "Initialising replication..."

/opt/opendj/bin/dsreplication \
initialize-all \
--hostname $local_node \
--port 4444 \
--adminUID admin \
--adminPassword password \
--baseDN $BASE_DN \
--trustAll \
--no-prompt

echo "Replication initialized"
