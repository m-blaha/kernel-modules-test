Feature: Current exact partner kernel requirement preserves bootable kernel sets
  The modeled RHEL repositories contain kernel .40 and .41, but the newest
  partner module is built only for .40. An exact kernel-uname-r requirement
  must never leave kernel-core .40 installed without its matching
  kernel-modules package.

  Scenario: Exact kernel requirement leaves a partial .40 kernel after upgrade (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-strict-kernel-requires"
     When I execute dnf with args "install kernel-1.0-39 partner-kmod-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "upgrade"
     Then the exit code is 0
      # partner-kmod requires only kernel-uname-r = 1.0-40.x86_64.
      # kernel-core-1.0-40 provides that capability, but nothing requires its
      # matching kernel-modules package. This intentionally failing check shows it.
      And RPMDB Transaction contains
        | Action  | Package                                                  |
        | install | kernel-0:1.0-41.x86_64                                  |
        | install | kernel-core-0:1.0-41.x86_64                             |
        | install | kernel-modules-0:1.0-41.x86_64                          |
        | upgrade | partner-kmod-0:1.0-40.x86_64                               |
        | install | kernel-core-0:1.0-40.x86_64                             |
        | install | kernel-modules-0:1.0-40.x86_64                          |

  Scenario: Exact kernel requirement leaves a partial .40 kernel after fresh installation (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-strict-kernel-requires"
     When I execute dnf with args "install kernel partner-kmod"
     Then the exit code is 0
      # Installing kernel selects the complete latest .41 set. The .40 module
      # independently pulls only kernel-core-1.0-40 through kernel-uname-r.
      # This intentionally failing check shows that .40 modules are omitted.
      And RPMDB Transaction contains
        | Action  | Package                                                  |
        | install | kernel-0:1.0-41.x86_64                                  |
        | install | kernel-core-0:1.0-41.x86_64                             |
        | install | kernel-modules-0:1.0-41.x86_64                          |
        | install | partner-kmod-0:1.0-40.x86_64                               |
        | install | kernel-core-0:1.0-40.x86_64                             |
        | install | kernel-modules-0:1.0-40.x86_64                          |

  Scenario: Exact kernel requirement leaves a partial .40 kernel after module installation (gap)
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-strict-kernel-requires"
     When I execute dnf with args "install kernel-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "install partner-kmod"
     Then the exit code is 0
      # The module request pulls kernel-core-1.0-40 to satisfy kernel-uname-r,
      # but does not pull kernel-modules-1.0-40. This intentionally fails.
      And RPMDB Transaction contains
        | Action  | Package                                                  |
        | install | partner-kmod-0:1.0-40.x86_64                               |
        | install | kernel-core-0:1.0-40.x86_64                             |
        | install | kernel-modules-0:1.0-40.x86_64                          |
