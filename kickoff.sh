#!/bin/bash

#docker run -it --net mynetwork -p 22 -p 5432 --name=node2 pgmine:test2
#docker run -it --net mynetwork -p 22 -p 5432 --name=node1 pgmine:test2

make_nodes_trust_each_other() {
    for node in $(echo "node1 node2"); do
        ip_address=$(docker inspect -f '{{.NetworkSettings.Networks.mynetwork.IPAddress}}' $node)
        echo $node
        echo $ip_address

        # docker exec node1 cat /home/postgres/.ssh/known_hosts
        echo "1"
        docker exec node1 su -c "ssh-keyscan -H $ip_address >> /home/postgres/.ssh/known_hosts" -- postgres
        echo "2"
        docker exec node1 su -c "ssh-keyscan -H $node >> /home/postgres/.ssh/known_hosts" -- postgres

        echo "3"
        docker exec node2 su -c "ssh-keyscan -H $ip_address >> /home/postgres/.ssh/known_hosts" -- postgres
        echo "4"
        docker exec node2 su -c "ssh-keyscan -H $node >> /home/postgres/.ssh/known_hosts" -- postgres
    done

}

initalise_repmgr_in_db() {

    export PGHOST=192.168.99.101
    export PGUSER=postgres
    export PGPORT=$(docker inspect node1 | grep Ports -A 20 | grep "5432/tcp" -A 3 | grep Port | tr -d '"' | awk '{print $NF}')
    createuser -s repmgr
    createdb repmgr -O repmgr
    psql -c 'ALTER USER repmgr SET search_path TO repmgr_test_cluster, "$user", public;'
    docker exec -it node1 /bin/bash -c "gosu postgres repmgr -f /etc/repmgr/repmgr.conf master register"
    docker exec -it node2 /bin/bash -c "gosu postgres repmgr -h node1 -U repmgr -d repmgr -D $PGDATA -f /etc/repmgr/repmgr.conf standby clone"
    docker exec node2 /bin/bash -c "/usr/bin/supervisord"
    docker exec -it node2 /bin/bashrepmgr -f /etc/repmgr.conf standby register
}

# make_nodes_trust_each_other
initalise_repmgr_in_db
