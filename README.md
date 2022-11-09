# HSA L18 Database: Replication

 - Create 3 docker containers: mysql-m, mysql-s1, mysql-s2
 - Setup master slave replication (Master: mysql-m, Slave: mysql-s1, mysql-s2)
 
##Step to setup master:

1. Up master with commented `log_bin` setting.
2. Run `Script to add permission to folder` below
3. Add log_bin setting
4. docker restart mysql_m
5. Run SQL
````
CREATE USER 'yk_slave_user'@'%' IDENTIFIED WITH mysql_native_password BY 'yk_slave_pwd';
GRANT REPLICATION SLAVE ON *.* TO 'yk_slave_user'@'%';
FLUSH PRIVILEGES;

USE yk;

RESET MASTER;

FLUSH TABLES WITH READ LOCK;

SHOW MASTER STATUS;

#Save positions and log file

UNLOCK TABLES;
````
![Master Status](./screenshots/master_status.png?raw=true "Master Status")


##Step to setup slave:
1. Up master with commented `log_bin` and `relay` settings.
2. Run `Script to add permission to folder` below
3. Add log_bin setting
4. Run Inside(`docker exec -ti mysql_s1 sh`) container
````
mysqld -u root stop
mysqld start --skip-slave-start
````
5. Run Script to load sql
6. RUN SQL with saved before Master positions and log file
````
slave 1,2
#SHOW BINARY LOGS;
#RESET SLAVE;

CHANGE MASTER TO MASTER_HOST='mysql_m', MASTER_PORT=3306, MASTER_USER='yk_slave_user', MASTER_PASSWORD='yk_slave_pwd',
    MASTER_LOG_FILE = 'mysql-bin.000001', MASTER_LOG_POS = 157;

START SLAVE;
show slave status;

#STOP SLAVE;
````

7. Check slave status

![Slave1 Status](./screenshots/slave1.png?raw=true "Slave1 Status")
![Slave2 Status](./screenshots/slave1.png?raw=true "Slave2 Status")

### Scripts

##### Script to add permission to folder
````
docker exec -u root mysql_m /bin/bash -c 'chown -R mysql:mysql /var/log/mysql'

docker exec -u root mysql_m /bin/bash -c 'chmod 644 /var/log/mysql'
````

##### Script to dump sql
````
docker exec mysql_m /usr/bin/mysqldump -u root --password=root yk > yk.sql
````

##### Script to load sql
````
docker exec mysql_s1 /usr/bin/mysql -u root --password=root yk < yk.sql
````

### When we try to delete column
````
mysql_s1  | 2022-11-09T18:09:31.830030Z 7 [ERROR] [MY-010584] [Repl] Slave SQL for channel '': Worker 1 failed executing transaction 'ANONYMOUS' at master log mysql-bin.000001, end_log_pos 2737; Error 'Unknown column 't.name' in 'field list'' on query. Default database: 'yk'. Query: '/* ApplicationName=PhpStorm 2021.3.1 */ UPDATE yk.users t SET t.name = 'Mike-5' WHERE t.id = 1', Error_code: MY-001054
mysql_s1  | 2022-11-09T18:09:31.837784Z 6 [Warning] [MY-010584] [Repl] Slave SQL for channel '': ... The slave coordinator and worker threads are stopped, possibly leaving data in inconsistent state. A restart should restore consistency automatically, although using non-transactional storage for data or info tables or DDL queries could lead to problems. In such cases you have to examine your data (see documentation for details). Error_code: MY-001756
mysql_s1  | 2022-11-09T18:12:07.846813Z 6 [ERROR] [MY-010586] [Repl] Error running query, slave SQL thread aborted. Fix the problem, and restart the slave SQL thread with "SLAVE START". We stopped at log 'mysql-bin.000001' position 2395
````
After adding column and restart mysql replica automatically ON.