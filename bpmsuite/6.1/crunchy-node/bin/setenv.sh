#!/bin/bash
PGROOT=/usr/pgsql-9.3
PGDATA=/pgdata
PG_LOG=/tmp/pg.log
PATH=/cluster/bin:$PGROOT/bin:$PATH
LD_LIBRARY_PATH=$PGROOT/lib
DOMAIN=crunchy.lab
