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
MYSQL_DATA="${PATH_ESOP}/data/mysql/"

# SUDO DEF
SUDO="sudo -u eyou"

# DATABASE DEF
DATABASE="eyou_monitor"

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

if [ -f ${MYSQL_CLI} -a -x ${MYSQL_CLI} ]; then
	MYSQL_CLI="${MYSQL_CLI} -h 127.1 -P 3308"
else
	echo "${MYSQL_CLI} not prepared!"
	exit 1
fi

# init install mysql db
init_db() {
	cd "${PATH_MYSQL}" >/dev/null 2>&1
	check_rc "chaning directory into ${PATH_MYSQL}"

	${SUDO} ./scripts/mysql_install_db --defaults-file=${MYSQL_CONF} --datadir=${MYSQL_DATA}
	check_rc "init install mysql db to ${MYSQL_DATA}"
}

# start mysql db
start_mysql() {
	${INIT_SH} start mysql
	wait
	# check mysql start succeed here!
}

# create eyou_monitor
${MYSQL_CLI} -s -e "create database ${DATABASE};"
${MYSQL_CLI} -s -e "drop database test;"
${MYSQL_CLI} -s -e "delete from mysql.user where User='';"

# create tables
${MYSQL_CLI} -s -e -D ${DATABASE} < sql/eyou_monitor.schema.sql 
${MYSQL_CLI} -s -e -D ${DATABASE} < sql/eyou_monitor.plugin_desc.sql 
${MYSQL_CLI} -s -e -D ${DATABASE} < sql/eyou_monitor.industry.sql 

# grant
${MYSQL_CLI} -s -e "GRANT ALL PRIVILEGES ON eyou_monitor.* TO eyou@127.0.0.1 IDENTIFIED BY 'eyou' WITH GRANT OPTION;" 
${MYSQL_CLI} -s -e "GRANT ALL PRIVILEGES ON eyou_monitor.* TO eyou@localhost IDENTIFIED BY 'eyou' WITH GRANT OPTION;"
