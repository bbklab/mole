Summary: 	server of esop
Name: 		esopserver
Version: 	1.0
Release: 	beta1
License: 	GPLv3
Group:  	Extension
Vendor:		eYou
Packager: 	Guangzheng Zhang<zhangguangzheng@eyou.net>
BuildRoot: 	/var/tmp/%{name}-%{version}-%{release}-root
Source0: 	esopserver-1.0-beta1.tgz
Source1: 	esopserver.init
Requires: 		coreutils >= 5.97, bash >= 3.1
Requires:		e2fsprogs >= 1.39, procps >= 3.2.7
Requires:		psmisc >= 22.2, util-linux >= 2.13
Requires: 		gawk >= 3.1.5, sed >= 4.1.5
Requires:		grep >= 2.5.1
Requires:		chkconfig >= 1.3.30.1
Requires(pre):		coreutils >= 5.97
Requires(post): 	chkconfig, coreutils >= 5.97
Requires(preun): 	chkconfig, initscripts
Requires(postun): 	coreutils >= 5.97
#
# All of version requires are based on OS rhel5.1 release
#

%description 
server of esop

%prep
%setup -q

%build

%install 
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && /bin/rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/eyou/toolmail
mkdir -p $RPM_BUILD_ROOT/etc/rc.d/init.d/
cp -a *  $RPM_BUILD_ROOT/usr/local/eyou/toolmail
cp -a    %{SOURCE1} $RPM_BUILD_ROOT/etc/rc.d/init.d/%{name}

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && /bin/rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/run/
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/log/
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/tmp/
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/etc/
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/data/
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/web/
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/app/inc/dynamic/
%attr(0755, root, root) %{_initrddir}/%{name}
/usr/local/eyou/toolmail

%pre
USER="eyou"
if id ${USER} >/dev/null 2>&1; then
	:
else
	useradd ${USER} -m -d /usr/local/eyou/toolmail -u 37012 >/dev/null 2>&1
fi

%post
if [ -L /usr/bin/%{name} ]; then
	:
else
	/bin/ln -s /usr/local/eyou/toolmail/app/sbin/eyou_toolmail /usr/bin/%{name} >/dev/null 2>&1
fi
/bin/bash /usr/local/eyou/toolmail/tmp_install/sbin/init_install.sh
/sbin/chkconfig --add %{name} >/dev/null 2>&1
/sbin/chkconfig --level 345 %{name} on >/dev/null 2>&1

%preun
/sbin/service %{name} stop >/dev/null 2>&1
/sbin/chkconfig --del %{name} >/dev/null 2>&1

%postun
if [ -L /usr/bin/%{name} ]; then
	/bin/rm -f /usr/bin/%{name} >/dev/null 2>&1
else
	:
fi

%changelog
* Thu Mar 27 2014 ESOP WORKGROUP <esop_workgroup@eyou.net>
- init buildrpm
