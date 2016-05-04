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


docker run -it --rm  --net mynetwork -p 22 -p 5432 --name=node1 pgmine:test2
docker run -it --rm  --net mynetwork -p 22 -p 5432 -e NODE_NAME=node2 -e NODE_ID=2 --name=node2 pgmine:test2 /bin/bash
docker run -it --rm  --net mynetwork -p 22 -p 5432 -e NODE_NAME=node3 -e NODE_ID=3 --name=node3 pgmine:test2 /bin/bash
./kickoff.sh

You can now create tables in node1 and see them reflect in node2 and 3!
Note that you can't create nodes in node 2 as it's read only.

Now kill off node 1 and after a minute one of the other 2 will be elected.


Considerations for K8s

I want to upgrade the cluster with ~0 db downtime.

Service: master db
API-DB
MASTER

DEPLOYMENT
api-db

Other services: standby (load balanced)

master goes down.

New pod is created that should just be a standby trying to join master (which will fail for a while!)

Standby elected

repmgrd_failover_promote fired, setting the standby label to be master




Easy HA Postgres on K8s

I can use repmgr to easily provide standby/replication of a pg master.
I'm wanting to deal with the case where I upgrade the cluster or resize and
just want everything to work(TM)

I'm thinking of:
 - 2 services: 1 to `role: master; app: db`, 1 to `role: standby; app: db`
 - 3 deployments:
     - Each with a single pod running postgres and repmgr
     - Each with `app: db; id:<unique_id>`
     - I believe I require 3 different due to persistent disk read/write issues
 - In the beginning I elect the first ever master:
     - I run some repmgr script that does the actual master election process
     - I update the labels on the pod to include role: master;
     - All other nodes I make sure have role: standby;
 - When the master goes down, repmgrd will elect a new master (after 30 secs or so)
 - I hook into the event `repmgrd_failover_promote` fired when a standby is
   elected and alter the labels on this pod (using an env var that correlates
   to the unique_id so I can "find myself") such that it is now `role:master`
   after making sure that any current `role:master app:db` pods are deleted.
 - I can perform similar hooking into other events such that pg nodes (pods)
   ensure their own labels are accurate when any of the master/standby
   register/unregister events occur.
