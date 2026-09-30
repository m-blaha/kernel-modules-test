Name:           partner-kernel-policy
Version:        1.0
Release:        2
Summary:        Partner kernel policy revision 2
License:        MIT
BuildArch:      x86_64
Requires:       (partner-kmod-1.0-39 = 1.0-1 if kernel-uname-r = 1.0-39.x86_64)
Recommends:     (kernel-modules-uname-r = 1.0-39.x86_64 if kernel-uname-r = 1.0-39.x86_64)
Requires:       (partner-kmod-1.0-40 = 1.0-1 if kernel-uname-r = 1.0-40.x86_64)
Recommends:     (kernel-modules-uname-r = 1.0-40.x86_64 if kernel-uname-r = 1.0-40.x86_64)
Requires:       (partner-kmod-1.0-40 = 1.0-1 if kernel-uname-r = 1.0-41.x86_64)
Recommends:     (kernel-modules-uname-r = 1.0-41.x86_64 if kernel-uname-r = 1.0-41.x86_64)
Conflicts:      kernel-uname-r < 1.0-39.x86_64
Conflicts:      kernel-uname-r >= 1.0-42.x86_64

%description
One shared policy selects the partner module for every installed kernel
in this fixture's supported set.
Kernel .39 uses the module built for .39.
Kernel .40 uses the module built for .40.
Kernel .41 uses the module built for .40.
Matching kernel modules are recommended when weak dependencies are enabled.
The policy does not itself require installation of an initial kernel.
The bounds exclude kernels outside the fixture's enumerated support history.

%install
mkdir -p %{buildroot}/usr/share/partner-fixture
touch %{buildroot}/usr/share/partner-fixture/kernel-policy

%files
/usr/share/partner-fixture/kernel-policy

%changelog
