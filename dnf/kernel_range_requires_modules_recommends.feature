Feature: Hard kernel range with a weak matching modules range
  The Partner module requires a supported kernel-uname-r and recommends
  kernel-modules-uname-r with identical bounds. The recommendation can help
  install modules, but it is not a hard package-set invariant.

  Scenario: Complete .41 kernel satisfies both ranges during upgrade
    Given I use repository "rhel-9-base"
      And I use repository "partner-kernel-range-requires-modules-recommends"
      And I configure dnf with
        | key               | value |
        | install_weak_deps | True  |
     When I execute dnf with args "install kernel-1.0-39 partner-kmod-1.0-39"
     Then the exit code is 0
      And I use repository "rhel-9-updates"
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | kernel-0:1.0-41.x86_64               |
        | install | kernel-core-0:1.0-41.x86_64          |
        | install | kernel-modules-0:1.0-41.x86_64       |
        | upgrade | partner-kmod-0:1.0-40.x86_64         |
        | absent  | kernel-core-0:1.0-40.x86_64          |
        | absent  | kernel-modules-0:1.0-40.x86_64       |
      And every installed kernel core has matching kernel modules

  Scenario: Fresh installation of kernel and Partner module remains complete
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-requires-modules-recommends"
      And I configure dnf with
        | key               | value |
        | install_weak_deps | True  |
     When I execute dnf with args "install kernel partner-kmod"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | kernel-0:1.0-41.x86_64               |
        | install | kernel-core-0:1.0-41.x86_64          |
        | install | kernel-modules-0:1.0-41.x86_64       |
        | install | partner-kmod-0:1.0-40.x86_64         |
        | absent  | kernel-core-0:1.0-40.x86_64          |
      And every installed kernel core has matching kernel modules

  Scenario: Enabled weak dependencies add modules on a module-only install
    Given I use repository "rhel-9-base"
      And I use repository "partner-kernel-range-requires-modules-recommends"
      And I configure dnf with
        | key               | value |
        | install_weak_deps | True  |
     When I execute dnf with args "install partner-kmod-1.0-39"
     Then the exit code is 0
      # Only .39 is available, so the hard range installs its core and the
      # weak modules range adds the matching modules. The kernel meta package
      # is not needed for this complete pair.
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | partner-kmod-0:1.0-39.x86_64         |
        | install | kernel-core-0:1.0-39.x86_64          |
        | install | kernel-modules-0:1.0-39.x86_64       |
        | absent  | kernel-0:1.0-39.x86_64               |
      And every installed kernel core has matching kernel modules

  Scenario: Disabled weak dependencies leave a partial kernel on module-only install (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-requires-modules-recommends"
      And I configure dnf with
        | key               | value |
        | install_weak_deps | False |
     When I execute dnf with args "install kernel-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "install partner-kmod"
     Then the exit code is 0
      # The hard range pulls a .40-or-newer kernel-core. With Recommends
      # disabled, nothing pulls its matching kernel-modules package.
      # This invariant intentionally fails, exposing a boot-risk gap.
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | partner-kmod-0:1.0-40.x86_64         |
      And every installed kernel core has matching kernel modules

  Scenario: Existing supported pair does not prevent an unsupported kernel update (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "rhel-9-next-major"
      And I use repository "partner-kernel-range-requires-modules-recommends"
      And I configure dnf with
        | key               | value |
        | install_weak_deps | True  |
     When I execute dnf with args "install kernel-1.0-40 partner-kmod-1.0-40"
     Then the exit code is 0
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      # The retained .40 core and modules already fulfill both Partner lines.
      # DNF can independently add a complete but unsupported 1.1 kernel.
      # This assertion intentionally fails to expose that remaining gap.
      But RPMDB Transaction contains
        | Action  | Package                              |
        | absent  | kernel-0:1.1-1.x86_64                |
