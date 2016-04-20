# Hacks

- SSH access is done at the moment by giving all nodes the same ssh key pair


docker network create mynetwork
Make sure the network is created by listing all networks

docker network ls
2. ATTACH CONTAINERS TO YOUR NETWORK

Open a terminal and run one of your containers as following:

docker run -it --publish-service web.mynetwork web
Open another terminal tab and run the other container as following:

docker run -it --publish-service redis.mynetwork redis

docker run -it --publish-service db_node1.mynetwork pgmine:test2
docker run -it --publish-service db_node2.mynetwork pgmine:test2

docker run -it --net mynetwork -p 22 -p 5432 pgmine:test2
docker run -it --net mynetwork -p 22 -p 5432 pgmine:test2


$ docker network inspect bridge


# Turn off strict host checking
Use the StrictHostKeyChecking option, for example:

ssh -oStrictHostKeyChecking=no $h uptime
This option can also be added to ~/.ssh/config, e.g.:

Host somehost
    Hostname 10.0.0.1
    StrictHostKeyChecking no
Note that when the host keys have changed, you'll get a warning, even with this option:

# possibly as a thing we do after nodes have kicked off?
ssh-keyscan -H <ip-address> >> ~/.ssh/known_hosts
ssh-keyscan -H <hostname> >> ~/.ssh/known_hosts



 docker exec node1 su -c "whoami" -- postgres



 docker run -it --rm --net mynetwork -p 22 -p 5432 --name=node1 pgmine:test2 /bin/bash
 docker run -it --net mynetwork -p 22 -p 5432 --name=node2 pgmine:test2 /bin/bash
 ./kickoff.sh


docker run --rm  --net mynetwork -v /Users/alex/Work/pyprogs/hapostgres/postgres/data/node1:/data -e PGDATA=/data -p 22 -p 5432 --name=node1 pgmine:test2



# Current process
1. Run one node in docker:

    docker run -it --rm  --net mynetwork -p 22 -p 5432 --name=node1 pgmine:test2

2. Run kickoff.sh in order to create the db stuff we need
    3. exec onto the node

        docker exec -it node1 /bin/bash

    3. Attempt to run:

        gosu postgres repmgr -f /etc/repmgr/repmgr.conf master register

        ERROR:  could not access file "$libdir/repmgr_funcs": No such file or directory
        - fixed by hack to make things use pg9.5 (since that's where repmgr had installed itself)

4. Run the second node without postgres:

    docker run -it --rm  --net mynetwork -p 22 -p 5432 -e NODE_NAME=node2 -e NODE_ID=2 --name=node2 pgmine:test2 /bin/bash

5. Start the backup

    gosu postgres repmgr -h node1 -U repmgr -d repmgr -D $PGDATA -f /etc/repmgr/repmgr.conf standby clone

6. Unchartered:
 - need to start the db on the slave, and continue with the tutorial.
