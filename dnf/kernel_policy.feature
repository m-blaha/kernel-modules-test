Feature: One shared policy selects modules for all installed kernels
  The model has a policy package and coinstallable module packages.
  The policy directly requires each installed kernel's approved partner module
  and recommends matching kernel-modules when weak dependencies are enabled.
  Revision 2 uses the .40 module for .41; revision 3
  switches .41 to its native module. No activation packages are needed.
  These fixtures model RPM dependencies, not actual module loading.

  Background:
    Given I use repository "rhel-9-base"
      And I use repository "partner-kernel-policy-base"
      And I configure dnf with
        | key               | value |
        | install_weak_deps | False |

  Scenario: Disabled weak dependencies allow the partner module without kernel modules
     When I execute dnf with args "install kernel-core-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "install partner-kmod-1.0-39"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action    | Package                              |
        | install   | partner-kmod-1.0-39-0:1.0-1.x86_64    |
        | install   | partner-kernel-policy-0:1.0-1.x86_64  |
        | unchanged | kernel-core-0:1.0-39.x86_64           |
        | absent    | kernel-modules-0:1.0-39.x86_64        |
        | absent    | kernel-0:1.0-39.x86_64                |

  Scenario: Enabled weak dependencies add the recommended matching kernel modules
    Given I configure dnf with
        | key               | value |
        | install_weak_deps | True  |
     When I execute dnf with args "install kernel-core-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "install partner-kmod-1.0-39"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action    | Package                              |
        | install   | partner-kmod-1.0-39-0:1.0-1.x86_64    |
        | install   | partner-kernel-policy-0:1.0-1.x86_64  |
        | unchanged | kernel-core-0:1.0-39.x86_64           |
        | install   | kernel-modules-0:1.0-39.x86_64        |
        | absent    | kernel-0:1.0-39.x86_64                |
      And every installed kernel core has matching kernel modules

  Scenario: Updating the policy permits .41 and retains the .39 recovery pair
     When I execute dnf with args "install kernel-1.0-39 partner-kernel-policy"
     Then the exit code is 0
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-policy-updates"
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action    | Package                              |
        | upgrade   | partner-kernel-policy-0:1.0-2.x86_64  |
        | absent    | partner-kernel-policy-0:1.0-1.x86_64  |
        | install   | kernel-0:1.0-41.x86_64                |
        | install   | kernel-core-0:1.0-41.x86_64           |
        | install   | kernel-modules-0:1.0-41.x86_64        |
        | install   | partner-kmod-1.0-40-0:1.0-1.x86_64    |
        | unchanged | kernel-0:1.0-39.x86_64                |
        | unchanged | kernel-core-0:1.0-39.x86_64           |
        | unchanged | kernel-modules-0:1.0-39.x86_64        |
        | unchanged | partner-kmod-1.0-39-0:1.0-1.x86_64    |
        | absent    | kernel-core-0:1.0-40.x86_64           |
        | absent    | kernel-modules-0:1.0-40.x86_64        |
      And every installed kernel core has matching kernel modules

  Scenario: Installing a core with weak dependencies disabled adds only its approved partner module
     When I execute dnf with args "install kernel-1.0-39 partner-kernel-policy"
     Then the exit code is 0
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-policy-updates"
     When I execute dnf with args "upgrade partner-kernel-policy"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                              |
        | upgrade | partner-kernel-policy-0:1.0-2.x86_64  |
        | absent  | kernel-core-0:1.0-40.x86_64           |
        | absent  | kernel-core-0:1.0-41.x86_64           |
        | absent  | partner-kmod-1.0-40-0:1.0-1.x86_64    |
     When I execute dnf with args "install kernel-core-1.0-41"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action    | Package                              |
        | install   | kernel-core-0:1.0-41.x86_64           |
        | absent    | kernel-modules-0:1.0-41.x86_64        |
        | install   | partner-kmod-1.0-40-0:1.0-1.x86_64    |
        | unchanged | partner-kmod-1.0-39-0:1.0-1.x86_64    |
        | absent    | kernel-core-0:1.0-40.x86_64           |

  Scenario: A stale policy rejects a newer kernel before changing the installed set
     When I execute dnf with args "install kernel-1.0-39 partner-kernel-policy"
     Then the exit code is 0
      And I use repository "rhel-9-updates"
     When I execute dnf with args "install kernel-1.0-41"
     Then the exit code is 1
      And RPMDB Transaction is empty
      And RPMDB Transaction contains
        | Action    | Package                              |
        | unchanged | partner-kernel-policy-0:1.0-1.x86_64  |
        | unchanged | partner-kmod-1.0-39-0:1.0-1.x86_64    |
        | absent    | kernel-core-0:1.0-41.x86_64           |

  Scenario: An advanced policy cannot admit .41 when its approved partner module is unavailable
     When I execute dnf with args "install kernel-1.0-39 partner-kernel-policy"
     Then the exit code is 0
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-policy-updates"
     When I execute dnf with args "upgrade partner-kernel-policy"
     Then the exit code is 0
     When I execute dnf with args "--exclude=partner-kmod-1.0-40 install kernel-1.0-41"
     Then the exit code is 1
      And RPMDB Transaction is empty
      And RPMDB Transaction contains
        | Action    | Package                              |
        | unchanged | partner-kernel-policy-0:1.0-2.x86_64  |
        | unchanged | partner-kmod-1.0-39-0:1.0-1.x86_64    |
        | absent    | kernel-core-0:1.0-41.x86_64           |

  Scenario: An unsupported next-family kernel makes a best-candidate upgrade fail safely
    Given I use repository "rhel-9-updates"
      And I use repository "partner-kernel-policy-updates"
     When I execute dnf with args "install kernel-1.0-41 partner-kernel-policy"
     Then the exit code is 0
      And I use repository "rhel-9-next-major"
     When I execute dnf with args "upgrade"
     Then the exit code is 1
      And RPMDB Transaction is empty
      And RPMDB Transaction contains
        | Action    | Package                              |
        | unchanged | kernel-core-0:1.0-41.x86_64           |
        | unchanged | partner-kmod-1.0-40-0:1.0-1.x86_64    |
        | unchanged | partner-kernel-policy-0:1.0-2.x86_64  |
        | absent    | kernel-0:1.1-1.x86_64                 |
        | absent    | kernel-core-0:1.1-1.x86_64            |
        | absent    | kernel-modules-0:1.1-1.x86_64         |

  Scenario: Disabling best-candidate enforcement selects the latest approved kernel
     When I execute dnf with args "install kernel-1.0-39 partner-kernel-policy"
     Then the exit code is 0
      And I use repository "rhel-9-updates"
      And I use repository "rhel-9-next-major"
      And I use repository "partner-kernel-policy-updates"
      And I configure dnf with
        | key  | value |
        | best | False |
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action    | Package                              |
        | upgrade   | partner-kernel-policy-0:1.0-2.x86_64  |
        | install   | kernel-0:1.0-41.x86_64                |
        | install   | kernel-core-0:1.0-41.x86_64           |
        | install   | kernel-modules-0:1.0-41.x86_64        |
        | install   | partner-kmod-1.0-40-0:1.0-1.x86_64    |
        | unchanged | kernel-core-0:1.0-39.x86_64           |
        | unchanged | partner-kmod-1.0-39-0:1.0-1.x86_64    |
        | absent    | kernel-core-0:1.0-40.x86_64           |
        | absent    | kernel-0:1.1-1.x86_64                 |
        | absent    | kernel-core-0:1.1-1.x86_64            |
        | absent    | kernel-modules-0:1.1-1.x86_64         |
      And every installed kernel core has matching kernel modules

  Scenario: Removing the build kernel preserves its module while .41 still uses it
    Given I use repository "rhel-9-updates"
      And I use repository "partner-kernel-policy-updates"
     When I execute dnf with args "install kernel-1.0-40 kernel-1.0-41 partner-kernel-policy"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                              |
        | install | partner-kernel-policy-0:1.0-2.x86_64  |
        | install | partner-kmod-1.0-40-0:1.0-1.x86_64    |
     When I execute dnf with args "remove kernel-1.0-40 kernel-core-1.0-40 kernel-modules-1.0-40"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action    | Package                              |
        | absent    | kernel-0:1.0-40.x86_64                |
        | absent    | kernel-core-0:1.0-40.x86_64           |
        | absent    | kernel-modules-0:1.0-40.x86_64        |
        | unchanged | kernel-0:1.0-41.x86_64                |
        | unchanged | kernel-core-0:1.0-41.x86_64           |
        | unchanged | kernel-modules-0:1.0-41.x86_64        |
        | unchanged | partner-kmod-1.0-40-0:1.0-1.x86_64    |
        | unchanged | partner-kernel-policy-0:1.0-2.x86_64  |
      And every installed kernel core has matching kernel modules

  Scenario: A policy update selects the native .41 module while retaining older recovery pairs
     When I execute dnf with args "install kernel-1.0-39 partner-kernel-policy"
     Then the exit code is 0
      And I use repository "rhel-9-updates"
      And I use repository "partner-kernel-policy-updates"
     When I execute dnf with args "install kernel-1.0-40 kernel-1.0-41"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                              |
        | upgrade | partner-kernel-policy-0:1.0-2.x86_64  |
        | install | partner-kmod-1.0-40-0:1.0-1.x86_64    |
      And I use repository "partner-kernel-policy-native"
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action    | Package                              |
        | upgrade   | partner-kernel-policy-0:1.0-3.x86_64  |
        | absent    | partner-kernel-policy-0:1.0-2.x86_64  |
        | install   | partner-kmod-1.0-41-0:1.0-1.x86_64    |
        | unchanged | kernel-0:1.0-39.x86_64                |
        | unchanged | kernel-core-0:1.0-39.x86_64           |
        | unchanged | kernel-modules-0:1.0-39.x86_64        |
        | unchanged | partner-kmod-1.0-39-0:1.0-1.x86_64    |
        | unchanged | kernel-0:1.0-40.x86_64                |
        | unchanged | kernel-core-0:1.0-40.x86_64           |
        | unchanged | kernel-modules-0:1.0-40.x86_64        |
        | unchanged | partner-kmod-1.0-40-0:1.0-1.x86_64    |
        | unchanged | kernel-0:1.0-41.x86_64                |
        | unchanged | kernel-core-0:1.0-41.x86_64           |
        | unchanged | kernel-modules-0:1.0-41.x86_64        |
      And every installed kernel core has matching kernel modules
