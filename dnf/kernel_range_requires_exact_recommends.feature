Feature: Exact kernel recommendation reintroduces a partial kernel
  The Partner module requires a supported kernel range and weakly recommends
  its exact build kernel. The exact recommendation is a separate request:
  it does not choose the provider of the hard range requirement.

  Scenario: Exact kernel recommendation adds a partial .40 core during upgrade (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-requires-exact-recommends"
     When I execute dnf with args "install kernel-1.0-39 partner-kmod-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      # kernel-core-1.0-41 satisfies the hard range. The exact Recommends is
      # then followed separately, adding kernel-core-1.0-40 but not its modules.
      # This intentionally failing assertion demonstrates the reintroduced gap.
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | kernel-0:1.0-41.x86_64               |
        | install | kernel-core-0:1.0-41.x86_64          |
        | install | kernel-modules-0:1.0-41.x86_64       |
        | upgrade | partner-kmod-0:1.0-40.x86_64         |
        | install | kernel-core-0:1.0-40.x86_64          |
        | install | kernel-modules-0:1.0-40.x86_64       |

  Scenario: Exact kernel recommendation adds a partial .40 core during fresh installation (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-requires-exact-recommends"
     When I execute dnf with args "install kernel partner-kmod"
     Then the exit code is 0
      # The kernel meta package installs a complete .41 set. The recommendation
      # independently adds only kernel-core-1.0-40. This assertion intentionally
      # fails because kernel-modules-1.0-40 is not a dependency or recommendation.
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | kernel-0:1.0-41.x86_64               |
        | install | kernel-core-0:1.0-41.x86_64          |
        | install | kernel-modules-0:1.0-41.x86_64       |
        | install | partner-kmod-0:1.0-40.x86_64         |
        | install | kernel-core-0:1.0-40.x86_64          |
        | install | kernel-modules-0:1.0-40.x86_64       |
