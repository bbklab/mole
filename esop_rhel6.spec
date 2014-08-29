Summary: 	agent of esop
Name: 		esop
Version: 	1.1.0
Release: 	rhel6
License: 	Commercial
Group:  	Extension
Vendor:		Beijing eYou Information Technology Co., Ltd.
Packager: 	Guangzheng Zhang<zhangguangzheng@eyou.net>
BuildRoot: 	/var/tmp/%{name}-%{version}-%{release}-root
Source0: 	esop-1.1.0-rhel6.tgz
Source1: 	esop.init
Requires: 		coreutils >= 5.97, bash >= 3.1
Requires:		e2fsprogs >= 1.39, procps >= 3.2.7
Requires:		psmisc >= 22.2, util-linux >= 2.13
Requires:		SysVinit >= 2.86, nc >= 1.84
Requires: 		gawk >= 3.1.5, sed >= 4.1.5
Requires:		perl >= 5.8.8, grep >= 2.5.1
Requires:		tar >= 1.15.1, gzip >= 1.3.5
Requires:		curl >= 7.15.5, bc >= 1.06
Requires:		findutils >= 4.2.27, gettext >= 0.14.6
Requires:		chkconfig >= 1.3.30.1
Requires:		redhat-lsb >= 3.1
Requires:		glibc-common >= 2.5
Requires(pre):		coreutils >= 5.97
Requires(post): 	chkconfig, coreutils >= 5.97
Requires(preun): 	chkconfig, initscripts
Requires(postun): 	coreutils >= 5.97
#
# All of version requires are based on OS rhel5.1 release
#

%description 
agent of esop

%prep
%setup -q

cat << \EOF > %{_builddir}/%{name}-plreq
#!/bin/sh
%{__perl_requires} $* |\
sed -e '/perl(JSON::backportPP)/d' |\
sed -e '/perl(Crypt::DES)/d' |\
sed -e '/perl(Digest::HMAC)/d' |\
sed -e '/perl(Digest::SHA1)/d' |\
sed -e '/perl(Socket6)/d'
EOF
%define __perl_requires %{_builddir}/%{name}-plreq
chmod 755 %{__perl_requires}

%build

%install 
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && /bin/rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/%{name}/
mkdir -p $RPM_BUILD_ROOT/etc/rc.d/init.d/
cp -a *  $RPM_BUILD_ROOT/usr/local/%{name}/
cp -a    %{SOURCE1} $RPM_BUILD_ROOT/etc/rc.d/init.d/%{name}

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && /bin/rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
%attr(-, eyou, eyou) /usr/local/%{name}/agent/run/
%attr(-, eyou, eyou) /usr/local/%{name}/agent/log/
%attr(-, eyou, eyou) /usr/local/%{name}/agent/etc/
%attr(-, eyou, eyou) /usr/local/%{name}/agent/app/inc/dynamic/
%attr(0755, root, root) %{_initrddir}/%{name}
/usr/local/%{name}

%config

%doc

%pre
# check instance running or not ?
MOLE_INIT="/usr/local/%{name}/agent/mole/sbin/mole"
if [ -f "${MOLE_INIT}" ] && [ -x "${MOLE_INIT}" ]; then
	if ${MOLE_INIT} status >/dev/null 2>&1; then
		echo -e "\033[1;31man esop instance is already running ? stop the instance if you want to continue.\033[0m\n" 
		exit 1		# exit with non-zero so rpm installation progress won't continue.
	fi
fi

# create system user: eyou
USER="eyou"
USERID="12037"
if id ${USER} >/dev/null 2>&1; then
	:
else
	if useradd ${USER} -m -d /usr/local/%{name}/ -u ${USERID} >/dev/null 2>&1; then
		:
	else
		echo -e "\033[1;31mcreate system user ${USER}(${USERID}) failed!\033[0m\n" 
		exit 1		# exit with non-zero so rpm installation progress won't continue.
	fi
fi

# backup old version config files / save old version
if /bin/rpm -qi "esop" >/dev/null 2>&1; then
	OLD_ESOP_VERSION=$( /bin/rpm -q --queryformat "%{version}" "esop" 2>&- )
	if [ -n "${OLD_ESOP_VERSION}" ]; then
		OLD_ESOP_SAVEDIR="/var/tmp/oldesop-rpmsavedir"
		OLD_ESOP_VERFILE="${OLD_ESOP_SAVEDIR}/.version_upgrade"
		if /bin/mkdir -p "${OLD_ESOP_SAVEDIR}" >/dev/null 2>&1; then
			if echo -en "${OLD_ESOP_VERSION}" > "${OLD_ESOP_VERFILE}" 2>/dev/null; then
				PROXY_CONF_PATH="/usr/local/esop/agent/etc"
				MOLE_CONF_PATH="/usr/local/esop/agent/mole/conf"
				/bin/cp -arf  "${PROXY_CONF_PATH}" "${MOLE_CONF_PATH}" "${OLD_ESOP_SAVEDIR}" >/dev/null 2>&1
			fi
		fi
	fi
fi
:

%post
# init mole id
/bin/bash /usr/local/%{name}/agent/mole/bin/setinit rpminit

# init all basic plugins' configs
/bin/bash /usr/local/%{name}/agent/mole/bin/autoconf rpminit all

# upgrade old version
ESOP_UPGRADE_MODE=1 ESOP_RPM_UPGRADE=1 /bin/bash /usr/local/%{name}/agent/mole/upgrade/upgrade

# register as linux system startups
/sbin/chkconfig --add %{name} >/dev/null 2>&1
/sbin/chkconfig --level 345 %{name} on >/dev/null 2>&1

# create symbolic link for esop,mole
/bin/ln -s /usr/local/%{name}/agent/mole/sbin/%{name} /bin/%{name} >/dev/null 2>&1
/bin/ln -s /usr/local/%{name}/agent/mole/sbin/mole /bin/mole >/dev/null 2>&1

# clear old tmp status file if exists
if [ -f "/usr/local/esop/agent/mole/tmp/.status.dat" ]; then
	rm -f "/usr/local/esop/agent/mole/tmp/.status.dat" 2>&-
fi
if [ -f "/usr/local/esop/agent/mole/tmp/.posthost.status" ]; then
	rm -f "/usr/local/esop/agent/mole/tmp/.posthost.status" 2>&-
fi
if [ -f "/usr/local/esop/agent/mole/tmp/.smtphost.status" ]; then
	rm -f "/usr/local/esop/agent/mole/tmp/.smtphost.status" 2>&-
fi
:

%preun
if [ "$1" == "0" ]; then	# if uninstall indeed
	# save original mole config file
	/usr/local/%{name}/agent/mole/sbin/mole saveconf

	# stop instance
	/sbin/service %{name} stop >/dev/null 2>&1
	
	# remove system startups
	/sbin/chkconfig --del %{name} >/dev/null 2>&1
fi
:

%postun
:

%changelog
* Mon Aug 18 2014 ESOP WORKGROUP <esop_workgroup@eyou.net>
- 发布: 正式版 1.1.0
- 新增: 客户端通知(SMS/Email)的策略控制,可配置通知次数和时间范围
- 新增: 客户端部分插件允许分别设定告警阈值和故障阈值
- 新增: RPM升级过程中自动进行旧版保留数据的升级和校验
- 优化: 大幅加速plugin协议数据的搜集速度,且大幅减少CPU开销
- 调整: 调整安装后的自动化插件配置,减少默认配置情况下的告警通知
- 调整: 代理通道proxy的日志内容和格式
- 调整: 其他优化和调整
* Mon May 26 2014 ESOP WORKGROUP <esop_workgroup@eyou.net>
- 发布: 正式版 1.0.1
- 新增: 插件调度主程序(mole)和14个基础运维插件
- 新增: 增加客户端数据上报代理通道功能(proxy)
