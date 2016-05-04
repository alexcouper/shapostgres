#!/bin/bash

#docker run -it --net mynetwork -p 22 -p 5432 --name=node2 pgmine:test2
#docker run -it --net mynetwork -p 22 -p 5432 --name=node1 pgmine:test2


make_nodes_trust_each_other() {
    # Only needed for rsync restores
    for node in $(echo "node1 node2 node3"); do
        ip_address=$(docker inspect -f '{{.NetworkSettings.Networks.mynetwork.IPAddress}}' $node)
        echo $node
        echo $ip_address

        for other_node in $(echo "node1 node2 node3"); do
            # docker exec node1 cat /home/postgres/.ssh/known_hosts
            echo "1"
            docker exec $other_node su -c "ssh-keyscan -H $ip_address >> /home/postgres/.ssh/known_hosts" -- postgres
            echo "2"
            docker exec $other_node su -c "ssh-keyscan -H $node >> /home/postgres/.ssh/known_hosts" -- postgres
        done
    done

}

initalise_repmgr_in_db() {

    export PGHOST=192.168.99.100
    export PGUSER=postgres
    export PGPORT=$(docker inspect node1 | grep Ports -A 20 | grep "5432/tcp" -A 3 | grep Port | tr -d '"' | awk '{print $NF}')
    createuser -s repmgr
    createdb repmgr -O repmgr
    psql -c 'ALTER USER repmgr SET search_path TO repmgr_test_cluster, "$user", public;'
    docker exec -it node1 /bin/bash -c "gosu postgres repmgr -f /etc/repmgr/repmgr.conf master register"
    for node in $(echo "node2 node3"); do
        docker exec -it $node /bin/bash -c "gosu postgres repmgr -h node1 -U repmgr -d repmgr -D \$PGDATA -f /etc/repmgr/repmgr.conf standby clone"
        docker exec -d $node /bin/bash -c "/usr/bin/supervisord"
        sleep 3
        docker exec -it $node /bin/bash -c "gosu postgres repmgr -F -f /etc/repmgr/repmgr.conf standby register"
        docker exec -d $node /bin/bash -c "gosu postgres /usr/bin/repmgrd -f /etc/repmgr/repmgr.conf -p /tmp/repmgrd.pid -d --verbose > /var/log/repmgrd.log 2>&1"
    done

}

echo "..."
# make_nodes_trust_each_other
initalise_repmgr_in_db


docker exec -it node2 /bin/bash -c "gosu postgres repmgr -h node1 -U repmgr -d repmgr -D \$PGDATA -f /etc/repmgr/repmgr.conf standby clone"
docker exec -d node2 /bin/bash -c "/usr/bin/supervisord"
sleep 3
docker exec -it node2 /bin/bash -c "gosu postgres repmgr -F -f /etc/repmgr/repmgr.conf standby register"
docker exec -d node2 /bin/bash -c "gosu postgres /usr/bin/repmgrd -f /etc/repmgr/repmgr.conf -p /tmp/repmgrd.pid -d --verbose > /var/log/repmgrd.log 2>&1"
