#!/bin/bash
set -e

service ssh restart

chown -R postgres:postgres /data

fill_repmgr_template() {
    CLUSTER_NAME=${CLUSTER_NAME:-"test_cluster"}
    NODE_ID=${NODE_ID:-"1"}
    NODE_NAME=${NODE_NAME:-"node1"}
    DB_HOST=$NODE_NAME

    sed -i s/\$\{CLUSTER_NAME\}/$CLUSTER_NAME/ /etc/repmgr/repmgr.conf
    sed -i s/\$\{NODE_ID\}/$NODE_ID/ /etc/repmgr/repmgr.conf
    sed -i s/\$\{NODE_NAME\}/$NODE_NAME/ /etc/repmgr/repmgr.conf
    sed -i s/\$\{DB_HOST\}/$DB_HOST/ /etc/repmgr/repmgr.conf
}


fill_repmgr_template

exec "$@"
