Name:           partner-kmod
Version:        1.0
Release:        39
Summary:        Partner module for kernel 1.0-39 through 1.0
License:        MIT
BuildArch:      x86_64
Requires:       (kernel-modules-uname-r >= 1.0-39.x86_64 with kernel-modules-uname-r < 1.1-0.x86_64)

%description
Fixture Partner module built for kernel 1.0-39. A matching kernel-modules
package in the supported kernel family must also be installed.

%install
mkdir -p %{buildroot}/usr/lib/partner-fixture
touch %{buildroot}/usr/lib/partner-fixture/partner-kmod-1.0-39.x86_64.ko

%files
/usr/lib/partner-fixture/partner-kmod-1.0-39.x86_64.ko

%changelog
