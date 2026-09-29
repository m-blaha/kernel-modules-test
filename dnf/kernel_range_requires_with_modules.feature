Feature: A kernel-modules range keeps supported kernel sets complete
  The partner module requires a kernel-modules-uname-r capability in its
  supported release range. The fixture's kernel-modules package requires its
  matching kernel-core package, binding the components to one release.

  Scenario: Kernel-modules range keeps the .41 upgrade complete
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-requires-with-modules"
     When I execute dnf with args "install kernel-1.0-39 partner-kmod-1.0-39"
     Then the exit code is 0
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

  Scenario: Kernel-modules range keeps a fresh .41 installation complete
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-requires-with-modules"
     When I execute dnf with args "install kernel partner-kmod"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | kernel-0:1.0-41.x86_64               |
        | install | kernel-core-0:1.0-41.x86_64          |
        | install | kernel-modules-0:1.0-41.x86_64       |
        | install | partner-kmod-0:1.0-40.x86_64         |
        | absent  | kernel-core-0:1.0-40.x86_64          |
        | absent  | kernel-modules-0:1.0-40.x86_64       |
      And every installed kernel core has matching kernel modules

  Scenario: Kernel-modules range closes the partial core gap for module installation
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-requires-with-modules"
     When I execute dnf with args "install kernel-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "install partner-kmod"
     Then the exit code is 0
      # The module requires kernel-modules-uname-r .40 or .41. Either provider
      # in this fixture requires its corresponding kernel-core, completing it.
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | partner-kmod-0:1.0-40.x86_64         |
      And every installed kernel core has matching kernel modules

  Scenario: Kernel-modules range still permits an unsupported next-family kernel (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "rhel-9-next-major"
      And I use repository "partner-kernel-range-requires-with-modules"
     When I execute dnf with args "install kernel-1.0-40 partner-kmod-1.0-40"
     Then the exit code is 0
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      # The retained .40 modules and core satisfy the partner requirements.
      # DNF can add the complete but unsupported 1.1 kernel independently.
      # This intentionally failing assertion exposes the remaining boot risk.
      But RPMDB Transaction contains
        | Action  | Package                              |
        | absent  | kernel-0:1.1-1.x86_64                |
