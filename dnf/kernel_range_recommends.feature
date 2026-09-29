Feature: Partner kernel range recommendations do not enforce a bootable supported kernel
  The Partner module weakly recommends a kernel-uname-r range from its build
  release through the 1.0 family. Recommendations are optional and do not
  perform weak-module linking; this feature models only DNF package selection.

  Scenario: Kernel range recommendation avoids an extra .40 core during upgrade
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-recommends"
     When I execute dnf with args "install kernel-1.0-39 partner-kmod-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | kernel-0:1.0-41.x86_64               |
        | install | kernel-core-0:1.0-41.x86_64           |
        | install | kernel-modules-0:1.0-41.x86_64        |
        | upgrade | partner-kmod-0:1.0-40.x86_64         |
        | absent  | kernel-core-0:1.0-40.x86_64          |
        | absent  | kernel-modules-0:1.0-40.x86_64       |
      And every installed kernel core has matching kernel modules

  Scenario: Kernel range recommendation can pull a partial core for a module-only install (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-recommends"
      And I configure dnf with
        | key               | value |
        | install_weak_deps | True  |
     When I execute dnf with args "install kernel-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "install partner-kmod"
     Then the exit code is 0
      # DNF follows the recommendation by installing a kernel-core provider,
      # but Recommends does not pull that provider's kernel-modules package.
      # The newest provider is kernel-core-1.0-41. Its matching modules are not
      # a recommendation, so this intentionally failing table exposes the gap.
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | partner-kmod-0:1.0-40.x86_64         |
        | install | kernel-core-0:1.0-41.x86_64          |
        | install | kernel-modules-0:1.0-41.x86_64       |
      And every installed kernel core has matching kernel modules

  Scenario: Disabled weak dependencies allow an unsupported module-only install (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-recommends"
      And I configure dnf with
        | key               | value |
        | install_weak_deps | False |
     When I execute dnf with args "install kernel-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "install partner-kmod"
     Then the exit code is 0
      # With weak dependencies disabled, the range has no enforcement effect:
      # partner-kmod .40 installs although no .40-or-newer kernel is installed.
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | partner-kmod-0:1.0-40.x86_64         |
        | absent  | kernel-core-0:1.0-40.x86_64          |
        | absent  | kernel-core-0:1.0-41.x86_64          |
      And every installed kernel core has matching kernel modules

  Scenario: Kernel range recommendation does not prevent an unsupported next-family kernel update (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "rhel-9-next-major"
      And I use repository "partner-kernel-range-recommends"
     When I execute dnf with args "install kernel-1.0-40 partner-kmod-1.0-40"
     Then the exit code is 0
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      # The existing 1.0-40 core already satisfies the recommendation. DNF can
      # add kernel-1.1-1 as another install-only kernel without a Partner module.
      # This intentionally failing assertion exposes the missing enforcement.
      But RPMDB Transaction contains
        | Action  | Package                              |
        | absent  | kernel-0:1.1-1.x86_64                |
