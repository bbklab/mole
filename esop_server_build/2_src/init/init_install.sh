#!/usr/bin/env bash


export PATH="${PATH}:/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

### GLOBAL DEF
BASE_DIR="$(cd $(dirname $0); pwd)"
LOGFILE="${BASE_DIR}/${0##*/}.log"

# DIR DEF
PATH_ESOP="/usr/local/eyou/toolmail"
PATH_OPT="${PATH_ESOP}/opt"
PATH_MYSQL="${PATH_OPT}/mysql"
PATH_APP="${PATH_ESOP}/app"
PATH_SBIN="${PATH_APP}/sbin"
PATH_ETC="${PATH_ESOP}/etc"

# FILE DEF
INIT_SH="${PATH_SBIN}/eyou_toolmail"
MYSQL_CLI="${PATH_MYSQL}/bin/mysql"
MYSQL_CONF="${PATH_ECT}/mysql/my.cnf"


# Global Func Def

# - check_rc
check_rc() {
  if [ $? == 0 ]; then
        echo -e " -- $(date +%F_%T)  succed!  ${*} " | tee -a $LOGFILE
  else
        echo -e " -- $(date +%F_%T)  failed!  ${*} " | tee -a $LOGFILE
        exit 1
  fi
}


### Main Body Begin

# init install mysql db
init_db() {
	cd /usr/local/eyou/toolmail/opt/mysql/
	sudo -u eyou ./scripts/mysql_install_db --defaults-file=/usr/local/eyou/toolmail/etc/mysql/my.cnf --datadir=/usr/local/eyou/toolmail/data/mysql/
}

# start mysql db
/usr/local/eyou/toolmail/app/sbin/eyou_toolmail watch
/usr/local/eyou/toolmail/app/sbin/eyou_toolmail start mysql

# create eyou_monitor
/usr/local/eyou/toolmail/opt/mysql/bin/mysql -h 127.1 -P 3308 -s -e "create database eyou_monitor;"
/usr/local/eyou/toolmail/opt/mysql/bin/mysql -h 127.1 -P 3308 -s -e "drop database test;"
/usr/local/eyou/toolmail/opt/mysql/bin/mysql -h 127.1 -P 3308 -s -e "delete from mysql.user where User='';"

# create tables
/usr/local/eyou/toolmail/opt/mysql/bin/mysql -h 127.1 -P 3308 -D eyou_monitor  < sql/eyou_monitor.schema.sql 
/usr/local/eyou/toolmail/opt/mysql/bin/mysql -h 127.1 -P 3308 -D eyou_monitor  < sql/eyou_monitor.plugin_desc.sql 
/usr/local/eyou/toolmail/opt/mysql/bin/mysql -h 127.1 -P 3308 -D eyou_monitor  < sql/eyou_monitor.industry.sql 

# grant
/usr/local/eyou/toolmail/opt/mysql/bin/mysql -h 127.1 -P 3308 -s -e "GRANT ALL PRIVILEGES ON eyou_monitor.* TO eyou@127.0.0.1 IDENTIFIED BY 'eyou' WITH GRANT OPTION;" 
/usr/local/eyou/toolmail/opt/mysql/bin/mysql -h 127.1 -P 3308 -s -e "GRANT ALL PRIVILEGES ON eyou_monitor.* TO eyou@localhost IDENTIFIED BY 'eyou' WITH GRANT OPTION;"
