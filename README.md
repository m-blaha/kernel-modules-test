# Partner kernel-module DNF test models

This suite models DNF transactions involving RHEL kernel packages and a partner
kernel module. The fixture versions are synthetic: kernel releases `.39`, `.40`,
and `.41` represent successive z-stream releases in kernel family `1.0`.

## Build and run in a container

The container uses CentOS Stream 9 by default, which supplies the RPM build
tools needed to generate the local fixture repositories.

```console
./container-test build
./container-test run dnf/strict_kernel_requires.feature
```

## Fixtures and features

Fixture RPM specs live under `fixtures/specs/<repository>/`. Each container run
rebuilds them into local repositories used only by the isolated test installroot:
the RHEL fixture repositories supply complete kernel sets, and each partner
repository supplies one distribution model.

Each `dnf/*.feature` exercises one model. A scenario marked as a gap may
intentionally fail: the failed expectation documents unsafe behavior that the
model does not prevent.

## Model: exact kernel Requires

```console
./container-test run dnf/strict_kernel_requires.feature
```

### Approach

Each partner module has an exact hard dependency on the `kernel-uname-r`
capability of the kernel release it was built for.

```spec
Requires: kernel-uname-r = 1.0-40.x86_64
```

### Pros

- Enforces installation of the exact build kernel core.
- Does not rely on weak-module compatibility.

### Gaps

- `kernel-uname-r` is provided by `kernel-core`, not by the complete kernel
  set. DNF can install `kernel-core-.40` without `kernel-modules-.40`.
- The feature intentionally fails to show this partial-kernel boot risk for
  upgrade, fresh installation, and module-only installation.
- It cannot use a .40 module with a newer .41 kernel.

## Model: exact kernel Requires plus kernel-modules Requires

```console
./container-test run dnf/strict_kernel_requires_with_modules.feature
```

### Approach

The exact `kernel-uname-r` dependency is retained and the module also has an
exact `kernel-modules` dependency.

```spec
Requires: kernel-uname-r = 1.0-40.x86_64
Requires: kernel-modules = 1.0-40
```

### Pros

- Closes the partial-kernel gap in the exact-Require model.
- Keeps the .40 boot entry complete.

### Gaps

- Installs the complete .40 kernel set even when .41 is available.
- Does not achieve the desired weak-module fallback from a .40 module to
  .41.

## Model: range Requires

```console
./container-test run dnf/kernel_range_requires.feature
```

### Approach

The partner module requires a supported kernel range. The `with` operator
ensures both bounds match the same `kernel-core` provider.

```spec
Requires: (kernel-uname-r >= 1.0-40.x86_64 with kernel-uname-r < 1.1-0.x86_64)
```

### Pros

- A complete .41 kernel can satisfy the .40 module's range.
- Upgrade and fresh-install paths avoid adding a separate .40 core.
- Can support a weak-module fallback, provided the .40 module has actually
  been certified and activated for .41.

### Gaps

- A module-only installation can still pull only a matching `kernel-core`;
  the feature intentionally fails on the complete-kernel invariant.
- An already installed .40 core satisfies the range, so DNF can add an
  unsupported 1.1 install-only kernel. The feature intentionally fails to
  expose this.

## Model: kernel-modules range Requires

```console
./container-test run dnf/kernel_range_requires_with_modules.feature
```

### Approach

The partner module requires a `kernel-modules-uname-r` capability in the
supported range. The `kernel-modules` provider requires its matching
`kernel-core` in the fixtures, so one dependency selects a complete pair.
The `with` operator binds both bounds to the same provider.

```spec
Requires: (kernel-modules-uname-r >= 1.0-40.x86_64 with kernel-modules-uname-r < 1.1-0.x86_64)
```

### Pros

- The `.41` kernel and its modules satisfy the `.40` partner module during a
  normal upgrade; no additional `.40` core is needed.
- A module-only install pulls a supported `kernel-modules` package, which in
  these fixtures requires its matching `kernel-core`. This closes the partial
  core gap of the plain range model.

### Gaps

- An installed supported kernel set still satisfies the partner dependencies
  after DNF adds an unsupported `1.1` install-only kernel. That scenario
  intentionally fails; the new kernel could become the default boot entry.

## Model: kernel range Requires plus modules range Recommends

```console
./container-test run dnf/kernel_range_requires_modules_recommends.feature
```

### Approach

The Partner module hard-requires a supported `kernel-uname-r` and weakly
recommends `kernel-modules-uname-r` with the same bounds.

```spec
Requires: (kernel-uname-r >= 1.0-40.x86_64 with kernel-uname-r < 1.1-0.x86_64)
Recommends: (kernel-modules-uname-r >= 1.0-40.x86_64 with kernel-modules-uname-r < 1.1-0.x86_64)
```

### Pros

- A complete `.41` kernel satisfies both ranges without installing `.40`.
- With weak dependencies enabled, DNF can pull modules when a Partner module
  is installed on a system that lacks them.

### Gaps

- With `install_weak_deps=False`, a module-only installation pulls only a
  supported core. The feature intentionally fails on this incomplete set.
- An already installed supported pair satisfies both lines while DNF adds an
  unsupported `1.1` install-only kernel. That feature scenario intentionally
  fails; package dependencies do not police the default boot kernel.

## Model: range Recommends

```console
./container-test run dnf/kernel_range_recommends.feature
```

### Approach

The kernel range is a weak `Recommends`, not a hard `Requires`.

```spec
Recommends: (kernel-uname-r >= 1.0-40.x86_64 with kernel-uname-r < 1.1-0.x86_64)
```

### Pros

- When DNF installs weak dependencies, an upgrade with a complete .41 kernel
  does not need an additional .40 core.
- It is an advisory compatibility hint rather than a hard kernel pin.

### Gaps

- With weak dependencies enabled, a module-only install can pull only
  `kernel-core-.41`; that scenario intentionally fails.
- With `install_weak_deps=False`, the module installs with no compatible
  kernel at all.
- It cannot block an unsupported next-family kernel

## Model: range Requires plus exact Recommends

```console
./container-test run dnf/kernel_range_requires_exact_recommends.feature
```

### Approach

The Partner module has a hard supported-kernel range and weakly recommends the
exact kernel release it was built for.

```spec
Requires: (kernel-uname-r >= 1.0-40.x86_64 with kernel-uname-r < 1.1-0.x86_64)
Recommends: kernel-uname-r = 1.0-40.x86_64
```

### Pros

- Retains the hard range, so a supported-family kernel is mandatory.
- Expresses the build kernel as an advisory preference.

### Gaps

- The exact recommendation is an additional request, not a preference among
  range providers. With weak dependencies enabled, it adds
  `kernel-core-.40` alongside a complete .41 kernel.
- Nothing adds `kernel-modules-.40`, reintroducing the partial-kernel
  failure. Both scenarios intentionally fail to demonstrate it.
- It still does not block an unsupported next-family kernel

## Model: one shared policy plus module packages

```console
./container-test run dnf/kernel_policy.feature
```

### Packages

There are only two kinds of partner package:

| Package | Job |
| --- | --- |
| `partner-kernel-policy` | Lists allowed kernels and selects the module required for each installed kernel. |
| `partner-kmod-1.0-39`, `partner-kmod-1.0-40`, `partner-kmod-1.0-41` | Contain modules built for the named kernel; several can remain installed for recovery. |

For example, a machine with kernels .39 and .41 using the .40 module needs three
partner packages: the policy, the .39 module, and the .40 module.
Each module requires the shared policy without pinning its version.

### Policy rules

For each known kernel, the policy says which partner module is required.
Revision 2 includes these rules for .41:

```spec
Requires: (partner-kmod-1.0-40 = 1.0-1 if kernel-uname-r = 1.0-41.x86_64)
Recommends: (kernel-modules-uname-r = 1.0-41.x86_64 if kernel-uname-r = 1.0-41.x86_64)
Conflicts: kernel-uname-r >= 1.0-42.x86_64
```

This means: if .41 is installed, require the .40 partner module. The ceiling
blocks unapproved newer kernels even when an older supported kernel remains
installed. Rules for .39 and .40 preserve their partner-module coverage.
The recommendation can add matching kernel modules when weak dependencies are
enabled; it does not make those packages mandatory.

When the native .41 module arrives, revision 3 changes the first rule to require
`partner-kmod-1.0-41 = 1.0-1`. The rules for .39 and .40 stay in place. A normal
upgrade installs the new policy and native module together. Policy revisions
1, 2, and 3 are independent of kernel release numbers.

### Publication stages

| Repository | Policy revision | Approved kernel-to-module mapping | New module package |
| --- | --- | --- | --- |
| `partner-kernel-policy-base` | 1 | .39 uses .39 | `partner-kmod-1.0-39` |
| `partner-kernel-policy-updates` | 2 | .39 uses .39; .40 and .41 use .40 | `partner-kmod-1.0-40` |
| `partner-kernel-policy-native` | 3 | .39 uses .39; .40 uses .40; .41 uses .41 | `partner-kmod-1.0-41` |

The feature enables these repositories progressively and keeps earlier ones
available for recovery packages. Production can publish successive updates in
one repository. The existing RHEL fixture repositories provide the kernels,
and the fixture build script discovers these specs automatically.

### Scenarios and limits

The ten scenarios cover weak dependencies enabled and disabled, policy
installation through a module dependency,
recovery-pair retention, direct core installation, stale policy, missing modules,
unsupported kernels with both `best` settings, removal of a build kernel while
its module is still needed, and migration to the native .41 module.

The policy is explicitly installed in most scenarios so it remains selected
when individual kernels are removed. A production client package could require
it. Conditional rules alone do not install an initial kernel; fresh installation
must request both a kernel and the policy, for example `install kernel
partner-kernel-policy`.

Kernel component selection remains the responsibility of the kernel packages
and the caller. In these fixtures, installing the `kernel` meta package pulls
matching core and modules. The partner module does not pull in its build kernel,
so using the .40 module on .41 does not introduce an extra .40 core. Explicitly
installing only `kernel-core` remains possible; the policy adds the approved
partner module but does not promise a complete or bootable kernel installation.
The recommendation helps with core-only installs when weak dependencies are
enabled. The scenarios also document that disabling weak dependencies permits
cores without matching kernel-modules.

## Possible implementation: DNF kernel filtering plugin

[dnf-plugin-kpatchfilter](https://github.com/m-blaha/dnf-plugin-kpatchfilter)

Proof of concept demonstrating how certain kernel versions can be hidden from
the solver, preventing users from installing them. In this case, filtering is
based on whether a version is supported by kpatch. Partner modules will require
different criteria.
