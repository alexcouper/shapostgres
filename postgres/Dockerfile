FROM postgres:9.4

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN apt-get update && apt-get install -y wget ca-certificates

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update

RUN apt-get install -y repmgr ssh rsync

RUN apt-get install -y supervisor telnet

RUN apt-get install -y vim

RUN mkdir -p /etc/repmgr
ADD repmgr.conf.sample /etc/repmgr/repmgr.conf
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf


#hack for ssh access (all nodes have the same one)

RUN mkdir -p /home/postgres
RUN chown postgres:postgres /home/postgres
ADD keys /tmp/keys
RUN chown postgres:postgres /tmp/keys

USER postgres
RUN mkdir -p ~/.ssh
RUN chmod 700 ~/.ssh
RUN mv /tmp/keys/id_rsa ~/.ssh/
RUN cat /tmp/keys/id_rsa.pub >> ~/.ssh/authorized_keys
RUN chmod 644 ~/.ssh/authorized_keys

# end hack

USER root
RUN mkdir -p /data
RUN chown -R postgres:postgres /data
RUN chown -R postgres:postgres /home/postgres

ADD new-docker-entrypoint.sh /

ENTRYPOINT ["/new-docker-entrypoint.sh"]

# Add my postgresql conf file that will be loaded during the postgres bootup
ADD postgres-config/load-my-postgresql.sh /docker-entrypoint-initdb.d/load-my-postgresql.sh
ADD postgres-config/pg_hba.conf /tmp/pg_hba.conf
ADD postgres-config/postgresql.conf /tmp/postgresql.conf
ADD postgres-config/postgresql.replication.conf /tmp/postgresql.replication.conf

# Hack to force use of 9.5 which I luckily have for some reason.
ENV PATH=/usr/lib/postgresql/9.5/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PG_MAJOR=9.5
ENV PGDATA=/data

CMD ["/usr/bin/supervisord"]
