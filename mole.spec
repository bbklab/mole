Summary: 	a little mole
Name: 		mole
Version: 	1.0
Release: 	beta1
License: 	GPLv3
Group:  	Extension
Packager: 	Zhang Guangzheng <zhang.elinks@gmail.com>
BuildRoot: 	/var/tmp/%{name}-%{version}-%{release}-root
Source0: 	mole-1.0-beta1.tgz
Source1: 	mole.init
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
Requires(post): 	chkconfig
Requires(preun): 	chkconfig, initscripts
Requires(postun): 	coreutils >= 5.97
#
# All of version requires are based on OS rhel5.1 release
#

%description 
a little mole

%prep
%setup -q

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
%defattr(-,root,root,-)
%attr(0755, root, root) %{_initrddir}/%{name}
/usr/local/esop/agent/%{name}

%post
/sbin/chkconfig --add %{name}
if [ -L /usr/bin/%{name} ]; then
	:
else
	/bin/ln -s /usr/local/%{name}/%{name} /usr/bin/%{name}
fi
/bin/bash /usr/local/esop/agent/%{name}/bin/setinit rpminit

%preun
/sbin/service %{name} stop >/dev/null 2>&1
/sbin/chkconfig --del %{name}

%postun
if [ -L /usr/bin/%{name} ]; then
	/bin/rm -f /usr/bin/%{name}
else
	:
fi

%changelog
* Wed Mar  5 2014 Zhang Guangzheng<zhang.elinks@gmail.com>
- init buildrpm for mole-1.0-beta1.rpm
