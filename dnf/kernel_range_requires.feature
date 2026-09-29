Feature: Partner kernel range requirements preserve bootable kernel sets
  The modeled RHEL repositories contain kernel .40 and .41, but the newest
  partner module is built for .40 and requires any kernel from .40 up to,
  but not including, kernel family 1.1. It must not create a partial kernel.

  Scenario: Kernel range avoids partial .40 during upgrade within its supported family
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-requires"
     When I execute dnf with args "install kernel-1.0-39 partner-kmod-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                                                  |
        | install | kernel-0:1.0-41.x86_64                                  |
        | install | kernel-core-0:1.0-41.x86_64                             |
        | install | kernel-modules-0:1.0-41.x86_64                          |
        | upgrade | partner-kmod-0:1.0-40.x86_64                               |
        | absent  | kernel-core-0:1.0-40.x86_64                             |
        | absent  | kernel-modules-0:1.0-40.x86_64                          |
      And every installed kernel core has matching kernel modules

  Scenario: Kernel range does not prevent an unsupported next-family kernel update (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "rhel-9-next-major"
      And I use repository "partner-kernel-range-requires"
     When I execute dnf with args "install kernel-1.0-40 partner-kmod-1.0-40"
     Then the exit code is 0
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      # partner-kmod remains satisfied by the retained kernel-core-1.0-40.
      # DNF may therefore add kernel-1.1-1 as another install-only kernel;
      # it has no dependency tying the Partner module to that new kernel.
      # This intentionally failing assertion makes that remaining gap visible.
      But RPMDB Transaction contains
        | Action  | Package                                                  |
        | absent  | kernel-0:1.1-1.x86_64                                   |

  Scenario: Kernel range avoids partial .40 during fresh installation within its supported family
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-requires"
     When I execute dnf with args "install kernel partner-kmod"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                                                  |
        | install | kernel-0:1.0-41.x86_64                                  |
        | install | kernel-core-0:1.0-41.x86_64                             |
        | install | kernel-modules-0:1.0-41.x86_64                          |
        | install | partner-kmod-0:1.0-40.x86_64                               |
        | absent  | kernel-core-0:1.0-40.x86_64                             |
        | absent  | kernel-modules-0:1.0-40.x86_64                          |
      And every installed kernel core has matching kernel modules

  Scenario: Kernel range can still leave a partial .40 kernel after module installation (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-range-requires"
     When I execute dnf with args "install kernel-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "install partner-kmod"
     Then the exit code is 0
      # The lower bound requires kernel-uname-r 1.0-40 or newer. DNF satisfies
      # it by installing kernel-core-1.0-40, but the range does not require
      # kernel-modules-1.0-40. This invariant intentionally fails.
      And RPMDB Transaction contains
        | Action  | Package                                                  |
        | install | partner-kmod-0:1.0-40.x86_64                               |
      And every installed kernel core has matching kernel modules
