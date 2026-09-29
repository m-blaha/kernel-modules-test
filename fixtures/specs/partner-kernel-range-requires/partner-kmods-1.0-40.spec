Name:           partner-kmod
Version:        1.0
Release:        40
Summary:        Partner module for kernel 1.0-40 through 1.0
License:        MIT
BuildArch:      x86_64
Requires:       kernel-uname-r >= 1.0-40.x86_64
Requires:       kernel-uname-r < 1.1-0.x86_64

%description
Fixture Partner module built for kernel 1.0-40 and allowed on the 1.0 kernel family.

%install
mkdir -p %{buildroot}/usr/lib/partner-fixture
touch %{buildroot}/usr/lib/partner-fixture/partner-kmod-1.0-40.x86_64.ko

%files
/usr/lib/partner-fixture/partner-kmod-1.0-40.x86_64.ko

%changelog
