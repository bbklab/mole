Summary: 	agent of esop
Name: 		esop
Version: 	1.0
Release: 	beta2
License: 	GPLv3
Group:  	Extension
Vendor:		eYou
Packager: 	Guangzheng Zhang<zhangguangzheng@eyou.net>
BuildRoot: 	/var/tmp/%{name}-%{version}-%{release}-root
Source0: 	esop-1.0-beta2.tgz
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
Requires:		redhat-lsb >= 3.1, sysstat >= 7.0.0
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
sed -e '/perl(JSON::backportPP)/d'
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

#%config(noreplace)
%config
/usr/local/%{name}/agent/etc/etm_agent.ini
/usr/local/%{name}/agent/etc/etm_phptd.ini
/usr/local/%{name}/agent/mole/conf/.mole.ini

%doc
/usr/local/%{name}/agent/mole/docs/

%pre
# check instance running or not ?
MOLE_INIT="/usr/local/%{name}/agent/mole/sbin/mole"
if [ -f "${MOLE_INIT}" -a -x "${MOLE_INIT}" ]; then
	if ${MOLE_INIT} status >/dev/null 2>&1; then
		echo -e "\033[1;31man esop instance is already running ? stop the instance if you want to continue.\033[0m\n" 
		exit 1		# exit with non-zero so rpm installation progress won't continue.
	fi
fi

# create system user: eyou
USER="eyou"
if id ${USER} >/dev/null 2>&1; then
	:
else
	useradd ${USER} -m -d /usr/local/%{name}/ -u 12037 >/dev/null 2>&1
fi

# save original mole config file
MOLE_CONFIG="/usr/local/%{name}/agent/mole/conf/.mole.ini"
MOLE_CONFIG_SAVE="/tmp/.mole.ini.saveold"
if [ -f "${MOLE_CONFIG}" -a -s "${MOLE_CONFIG}" ]; then
	/bin/cp -f "${MOLE_CONFIG}" "${MOLE_CONFIG_SAVE}"
else
	:
fi
:

%post
# init mole id
/bin/bash /usr/local/%{name}/agent/mole/bin/setinit rpminit

# restore original mole configs, init all plugin configs
/bin/bash /usr/local/%{name}/agent/mole/bin/autoconf rpminit all

# remove original mole config file
MOLE_CONFIG_SAVE="/tmp/.mole.ini.saveold"
if [ -f "${MOLE_CONFIG_SAVE}" ]; then
	/bin/rm -f "${MOLE_CONFIG_SAVE}" 2>&-
else
	:
fi

# register as linux startups
/sbin/chkconfig --add %{name} >/dev/null 2>&1
/sbin/chkconfig --level 345 %{name} on >/dev/null 2>&1

# create symbolic link for esop,mole
/bin/ln -s /usr/local/%{name}/agent/mole/sbin/%{name} /bin/%{name} >/dev/null 2>&1
/bin/ln -s /usr/local/%{name}/agent/mole/sbin/mole /bin/mole >/dev/null 2>&1
if [ -L /usr/bin/mole ]; then
	rm -f /usr/bin/mole 2>&-
fi
if [ -L /usr/bin/%{name} ]; then
	rm -f /usr/bin/%{name} 2>&-
fi
:

%preun
# save original mole config file
MOLE_CONFIG="/usr/local/%{name}/agent/mole/conf/.mole.ini"
MOLE_CONFIG_SAVE="/tmp/.mole.ini.saveold"
if [ -f "${MOLE_CONFIG}" -a -s "${MOLE_CONFIG}" ]; then
        /bin/cp -f "${MOLE_CONFIG}" "${MOLE_CONFIG_SAVE}"
else
        :   
fi
/sbin/service %{name} stop >/dev/null 2>&1
/sbin/chkconfig --del %{name} >/dev/null 2>&1
:

%postun
:

%changelog
* Fri Apr  4 2014 ESOP WORKGROUP <esop_workgroup@eyou.net>
- 发布: 1.0-beta2 版本
- 新增: 两个自带基础插件: process, disk_iostat
- 新增: DAEMON运行定期检查目录文件完整性, 文件丢失则自动退出DAEMON, 事件标志:MIS00000
- 新增: rpm安装后自动化配置插件参数, 主要根据eYou邮件8版的配置自动激活插件和配置插件参数
- 新增: rpm安装后自动恢复旧版MOLE的若干配置参数: id,parter_id,name,mail_receviers
- 修正: rpm包的依赖关系, 新增sysstat,redhat-lsb依赖, 将gmp打入包内, 去除gmp依赖
- 修正: 插件配置maxerr_times大于1时偶尔误发"恢复"(recovery)类型邮件的问题
- 调整: 上报地址和发邮件地址统一为 mole.eyousop.com, 端口分别为8538,5210
- 调整: 若干插件的结果输出, 使更方便阅读和理解: disk_fs,memory,sysload,traffic,tcp_conn
- 调整: 增强函数文件中的若干函数: is_sub, read_mole_config, init_plugin
* Wed Mar 19 2014 ESOP WORKGROUP <esop_workgroup@eyou.net>
- 发布: 1.0-beta1 版本
- 新增: 重启proxy时增加em_dynamic_config刷新配置的动作
- 新增: 首次启动mole初始化的时候, 对用户输入的服务器角色, 客户ID做合法性检查
- 新增: 对插件返回结果进行安全性过滤, 过滤部分有安全风险的HTML字符
- 新增: 添加"恢复"(recovery)事件的响应, 包括发信,上报,快照,自动响应处理等配置
- 新增: 基础插件disk_fs增加参数exclude, 允许跳过某些设备或挂载点的检查或测试
- 修正: mole的DAEMON启动流程标准化
- 调整: mole发送的信件套用HTML模板来生成
* Mon Mar  3 2014 ESOP WORKGROUP <esop_workgroup@eyou.net>
- 发布: 1.0-rc1 版本
