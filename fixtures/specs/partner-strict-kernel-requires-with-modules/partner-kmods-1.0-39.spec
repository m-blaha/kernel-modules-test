Name:           partner-kmod
Version:        1.0
Release:        39
Summary:        Partner module for kernel 1.0-39
License:        MIT
BuildArch:      x86_64
Requires:       kernel-uname-r = 1.0-39.x86_64
Requires:       kernel-modules = 1.0-39

%description
Fixture Partner module built for kernel 1.0-39.

%install
mkdir -p %{buildroot}/usr/lib/partner-fixture
touch %{buildroot}/usr/lib/partner-fixture/partner-kmod-1.0-39.x86_64.ko

%files
/usr/lib/partner-fixture/partner-kmod-1.0-39.x86_64.ko

%changelog
