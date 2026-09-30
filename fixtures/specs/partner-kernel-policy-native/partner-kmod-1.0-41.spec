Name:           partner-kmod-1.0-41
Version:        1.0
Release:        1
Summary:        Partner module built for kernel 1.0-41
License:        MIT
BuildArch:      x86_64
Requires:       partner-kernel-policy

%description
Synthetic module built for kernel .41. The build kernel is part of the
package name so modules built for different kernels can remain installed
together. The shared policy decides which target kernels may use this module.
Storing the module does not require its build kernel to be installed.
The empty file is not a loadable module; this fixture models RPM dependencies.

%install
mkdir -p %{buildroot}/usr/lib/partner-fixture/modules
touch %{buildroot}/usr/lib/partner-fixture/modules/1.0-41.x86_64.ko

%files
/usr/lib/partner-fixture/modules/1.0-41.x86_64.ko

%changelog
