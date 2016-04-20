#!/bin/bash

mv /tmp/postgresql.conf $PGDATA/postgresql.conf
mv /tmp/postgresql.replication.conf $PGDATA/postgresql.replication.conf
mv /tmp/pg_hba.conf $PGDATA/pg_hba.conf
