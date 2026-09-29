Feature: Strict partner kernel requirements also require matching kernel modules
  The modeled RHEL repositories contain kernel .40 and .41, but the newest
  partner module is built only for .40. In addition to its exact
  kernel-uname-r requirement, it requires matching kernel-modules.

  Scenario: Explicit kernel-modules requirement closes the partial .40 upgrade gap
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-strict-kernel-requires-with-modules"
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
        | install | kernel-core-0:1.0-40.x86_64                             |
        | install | kernel-modules-0:1.0-40.x86_64                          |

  Scenario: Explicit kernel-modules requirement closes the partial .40 fresh-install gap
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-strict-kernel-requires-with-modules"
     When I execute dnf with args "install kernel partner-kmod"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                                                  |
        | install | kernel-0:1.0-41.x86_64                                  |
        | install | kernel-core-0:1.0-41.x86_64                             |
        | install | kernel-modules-0:1.0-41.x86_64                          |
        | install | partner-kmod-0:1.0-40.x86_64                               |
        | install | kernel-core-0:1.0-40.x86_64                             |
        | install | kernel-modules-0:1.0-40.x86_64                          |

  Scenario: Explicit kernel-modules requirement closes the partial .40 module-install gap
    Given I use repository "rhel-9-base"
      And I use repository "rhel-9-updates"
      And I use repository "partner-strict-kernel-requires-with-modules"
     When I execute dnf with args "install kernel-1.0-39"
     Then the exit code is 0
     When I execute dnf with args "install partner-kmod"
     Then the exit code is 0
      And RPMDB Transaction contains
        | Action  | Package                                                  |
        | install | partner-kmod-0:1.0-40.x86_64                               |
        | install | kernel-core-0:1.0-40.x86_64                             |
        | install | kernel-modules-0:1.0-40.x86_64                          |
