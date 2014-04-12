Summary: 	application for esop server
Name: 		esop-app
Version: 	1.0.1
Release: 	rhel5
License: 	Commercial
Group:  	Extension
Vendor:		Beijing eYou Information Technology Co., Ltd.
Packager: 	Guangzheng Zhang<zhangguangzheng@eyou.net>
BuildRoot: 	/var/tmp/%{name}-%{version}-%{release}-root
Source0: 	esop-app-1.0.1-rhel5.tgz
Source1:	esop-app.init
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
application for esop server

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
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/etc/
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/web/
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/app/
%attr(-, eyou, eyou) /usr/local/eyou/toolmail/implements/
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
/sbin/chkconfig --add %{name} >/dev/null 2>&1
/sbin/chkconfig --level 345 %{name} on >/dev/null 2>&1

%preun
/sbin/service %{name} stop >/dev/null 2>&1
/sbin/chkconfig --del %{name} >/dev/null 2>&1

%postun

%changelog
* Tue May 13 2014 ESOP WORKGROUP <esop_workgroup@eyou.net>
- first buildrpm
