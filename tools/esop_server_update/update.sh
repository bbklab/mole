#!/bin/bash

base_dir="$(cd $(dirname $0) && pwd)"
inst_dir="/usr/local/eyou/toolmail"
updatename=$1

if [ -z "${updatename}" ]; then
	echo "update directory name required!"
	exit 1
fi

if [ "$(id -u)" != "0" ]; then
	echo "root privileges required!"
	exit 2
fi

update_path="${base_dir}/${updatename}"
update_back="${update_path}/pre-backup"
update_fcfg="${update_path}/update.cfg"
update_flog="${update_path}/update.log"

[ -f "${update_fcfg}" -a -s "${update_fcfg}" ] || {
	echo "${update_fcfg} not exist!"
	exit 3
}


#### Function Def ####


# Read INI File Section
# Usage		: read_ini {ini_file} {section}
# Example	: read_ini "${update_fcfg}" modify
#
read_ini() {
	cat "${1}" 2>&- | tr '\t' ' ' | awk -F"=" '\
		($0~/^ *\[ *'${2}' *\] *$/){k=1;x=1;next} \
		( x==1 && $0~/^ *\[ *.* *\] *$/ && $0!~/^ *\[ *'${2}' *\] *$/ ){exit} \
		(k==1 && x==1 && $0!~/^[ \t]*$/ && $0!~/^[ \t]*;/){print $1}' |\
	sed -e 's/^[ \t]*//; s/[ \t]*$//; s/^\"//; s/\"$//' 2>&-
}

# Write Log
# 
log() {
	echo "$(date +%s)" "$(date +%F_%T)" "${*}"  | tee -a ${update_flog}
}

# Term Color
echo_green() {
  local content=$*
  echo -e "\033[1;32m${content}\033[0m\c "
}
echo_yellow() {
  local content=$*
  echo -e "\033[1;33m${content}\033[0m\c "
}
echo_red() { 
  local content=$* 
  echo -e "\033[1;31m${content}\033[0m\c "
}

# update copy
do_copy() {
	local src="$1"  dst="$2"
	/bin/cp -f "$src" "$dst" >> ${update_flog} 2>&1
	if [ "$?" == "0" ]; then
		log "$(echo_green "[OK]"): update [$src] to [$dst]"
	else
		log "$(echo_red "[ERROR]"): update [$src] to [$dst]"
		exit 1
	fi
}

# check md5sum
md5sum_check() {
	local src="$1"  dst="$2"
	local md51=$( /usr/bin/md5sum "$src" 2>&- | awk '{print $1}' )
	local md52=$( /usr/bin/md5sum "$dst" 2>&- | awk '{print $1}' )
	if [ "${md51}" == "${md52}" ]; then
		log "$(echo_green "[OK]"): md5sum check [$src] and [$dst] (${md51})"
	else
		log "$(echo_red "[ERROR]"): md5sum check [$src](${md51}) and [$dst](${md52})"
		exit 1
	fi
}

# update remove
do_remove() {
	local file="$1"
	/bin/rm -f "$file" >> ${update_flog} 2>&1
	if [ "$?" == "0" ]; then
		log "$(echo_green "[OK]"): remove [$file]"
	else
		log "$(echo_red "[ERROR]"): remove [$file]"
		exit 1
	fi
}

# check remove
remove_check() {
	local file="$1"
	if [ ! -e "$file" ]; then
		log "$(echo_green "[OK]"): remove check [$file]"
	else
		log "$(echo_red "[ERROR]"): remove check [$file]"
		exit 1
	fi
}

# backup
do_backup() {
	local src="$1"
	/bin/cp -afL "${src}" "${backup_path}" >> ${update_flog} 2>&1
	if [ "$?" == "0" ]; then
		log "$(echo_green "[OK]"): backup [$src]"
	else
		log "$(echo_red "[ERROR]"): backup [$src]"
		exit 1
	fi
}


# Main Begin ...
#

# 1. log start
log
log
log "update start ..."

# 2. read change lst
newaddlst=$( read_ini "${update_fcfg}" add 2>&- )
removelst=$( read_ini "${update_fcfg}" remove 2>&- )
modifylst=$( read_ini "${update_fcfg}" modify 2>&- )
backuplst=$( read_ini "${update_fcfg}" backup 2>&- )

log "newadd: ${newaddlst}"
log "remove: ${removelst}"
log "modify: ${modifylst}"
log "backup: ${backuplst}"

# 3. action do backup
if [ -n "${backuplst}" ]; then
	backup_path="${update_back}/$(date +%F_%T)"
	/bin/mkdir -p "${backup_path}"  >> ${update_flog} 2>&1
	if [ -d "${backup_path}" ]; then
		log "$(echo_green "[OK]"): create backup directory [${backup_path}]"
		for fbackup in `echo "${backuplst}"`
		do
			fbackup="${inst_dir}/${fbackup}"
			do_backup "${fbackup}"
		done
	else
		log "$(echo_red "[ERROR]"): create backup directory [${backup_path}]"
		exit 1
	fi
fi

# 4. action do update
if [ -n "${removelst}" ]; then
	for fremove in `echo "${removelst}"`
	do
		fremove_dst="${inst_dir}/${fremove}"
		do_remove "${fremove_dst}"
		remove_check "${fremove_dst}"
	done
fi

if [ -n "${newaddlst}" ]; then
	for fadd in `echo "${newaddlst}"`
	do
		fadd_src=$(echo -e "${fadd}" | awk -F "~~~" '{print $2}')
		fadd_dst=$(echo -e "${fadd}" | awk -F "~~~" '{print $1}')
		fadd_src="${update_path}/${fadd_src}/${fadd_dst}"
		fadd_dst="${inst_dir}/${fadd_dst}"
		do_copy "${fadd_src}" "${fadd_dst}"
		md5sum_check "${fadd_src}" "${fadd_dst}"
	done
fi

if [ -n "${modifylst}" ]; then
	for fmodify in `echo "${modifylst}"`
	do
		fmodify_src=$(echo -e "${fmodify}" | awk -F "~~~" '{print $2}')
		fmodify_dst=$(echo -e "${fmodify}" | awk -F "~~~" '{print $1}')
		fmodify_src="${update_path}/${fmodify_src}/${fmodify_dst}"
		fmodify_dst="${inst_dir}/${fmodify_dst}"
		do_copy "${fmodify_src}" "${fmodify_dst}"
		md5sum_check "${fmodify_src}" "${fmodify_dst}"
	done
fi

# 5. log finished
log "update finished."
