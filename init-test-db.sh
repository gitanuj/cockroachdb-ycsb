#!/bin/bash
cockroach sql --url="postgresql://root@128.111.44.237:26267?sslmode=disable" --execute="create database test"
java -cp bin/jdbc-binding-0.11.0.jar:bin/postgresql-9.4.1212.jre7.jar com.yahoo.ycsb.db.JdbcDBCreateTable -P cockroachdb.properties -n usertable -p db.url=jdbc:postgresql://128.111.44.237:26267/test