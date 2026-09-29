Name:           kernel
Version:        1.0
Release:        41
Summary:        Fixture kernel 1.0-41
License:        MIT
BuildArch:      x86_64
Requires:       kernel-core = %{version}-%{release}
Requires:       kernel-modules = %{version}-%{release}

%description
Fixture kernel meta package for the updates repository.

%package core
Summary:        Fixture kernel core 1.0-41
Provides:       kernel-uname-r = 1.0-41.x86_64

%description core
Fixture kernel core package for 1.0-41.

%package modules
Summary:        Fixture kernel modules 1.0-41
Requires:       kernel-core = %{version}-%{release}

%description modules
Fixture kernel modules package for 1.0-41.

%install
mkdir -p %{buildroot}/usr/share/kernel-fixture/1.0-41.x86_64
mkdir -p %{buildroot}/usr/lib/kernel-fixture/1.0-41.x86_64
touch %{buildroot}/usr/share/kernel-fixture/1.0-41.x86_64/kernel
touch %{buildroot}/usr/lib/kernel-fixture/1.0-41.x86_64/core
touch %{buildroot}/usr/lib/kernel-fixture/1.0-41.x86_64/modules

%files
/usr/share/kernel-fixture/1.0-41.x86_64/kernel

%files core
/usr/lib/kernel-fixture/1.0-41.x86_64/core

%files modules
/usr/lib/kernel-fixture/1.0-41.x86_64/modules

%changelog
