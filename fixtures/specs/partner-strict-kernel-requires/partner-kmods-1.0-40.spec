Name:           partner-kmod
Version:        1.0
Release:        40
Summary:        Partner module for kernel 1.0-40
License:        MIT
BuildArch:      x86_64
Requires:       kernel-uname-r = 1.0-40.x86_64

%description
Fixture Partner module built for kernel 1.0-40.

%install
mkdir -p %{buildroot}/usr/lib/partner-fixture
touch %{buildroot}/usr/lib/partner-fixture/partner-kmod-1.0-40.x86_64.ko

%files
/usr/lib/partner-fixture/partner-kmod-1.0-40.x86_64.ko

%changelog
