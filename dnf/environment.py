# ci-dnf-stack DNF4/DNF5-compatible Behave harness, reduced to this suite.
from __future__ import absolute_import

import os
import shutil
import sys
import tempfile

from behave import model

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

import consts
from steps.lib.config import write_config
from common.lib.cmd import print_last_command
from common.lib.file import ensure_directory_exists


DEFAULT_DNF_COMMAND = "dnf"
DEFAULT_RELEASEVER = "9"


class DNFContext(object):
    def __init__(self, userdata):
        self._scenario_data = {}
        self.repos = {}
        self.ports = {}
        self.config = {
            "[main]": {
                "gpgcheck": "0",
                "installonly_limit": "3",
                "installonlypkgs": "kernel,kernel-core,kernel-modules",
                "clean_requirements_on_remove": "True",
                "best": "True",
            }
        }
        self.tempdir = tempfile.mkdtemp(prefix="partner_dnf_tempdir_")
        self.installroot = tempfile.mkdtemp(prefix="partner_dnf_installroot_")
        ensure_directory_exists(os.path.join(self.installroot, "etc/yum.repos.d"))
        self.dnf_command = userdata.get("dnf_command", DEFAULT_DNF_COMMAND)
        self.releasever = userdata.get("releasever", DEFAULT_RELEASEVER)
        self.fixturesdir = consts.FIXTURES_DIR
        self.disable_plugins = True
        self.disable_repos_option = "--disablerepo='*'"
        self.assumeyes_option = "-y"
        self.scenario_failed = False

    def __del__(self):
        for path in (self.tempdir, self.installroot):
            if os.path.realpath(path) not in ("/", "/tmp"):
                shutil.rmtree(path, ignore_errors=True)

    def __getitem__(self, name):
        return self._scenario_data[name]

    def __setitem__(self, name, value):
        self._scenario_data[name] = value

    def __contains__(self, name):
        return name in self._scenario_data

    def _get(self, name):
        return self[name] if name in self else getattr(self, name, None)

    def _set(self, name, value):
        setattr(self, name, value)

    def get_cmd(self, context):
        if context.dnf5_mode:
            return self.get_dnf5_cmd()
        return self.get_dnf4_cmd()

    def get_dnf4_cmd(self):
        result = [self.dnf_command, self.assumeyes_option]
        result.append("--installroot={}".format(self.installroot))
        result.append("--releasever={}".format(self._get("releasever")))
        if self._get("disable_plugins"):
            result.append("--disableplugin='*'")
        for key, value in (self._get("setopts") or {}).items():
            result.append("--setopt={0}={1}".format(key, value))
        return result

    def get_dnf5_cmd(self):
        result = [self.dnf_command, self.assumeyes_option]
        result.append("--installroot={}".format(self.installroot))
        result.append("--releasever={}".format(self._get("releasever")))
        for key, value in (self._get("setopts") or {}).items():
            result.append("--setopt={0}={1}".format(key, value))
        result.append("--setopt=cachedir=" + self.installroot + "/var/cache/dnf")
        return result


def before_scenario(context, scenario):
    context.dnf = DNFContext(context.config.userdata)
    write_config(context)
    context.scenario.default_tmp_dir = context.dnf.installroot
    context.scenario.repos_location = context.config.userdata.get(
        "repos_location", os.path.join(consts.FIXTURES_DIR, "repos"))


def before_all(context):
    # This is the ci-dnf-stack dual-version convention. RHEL 8/9 dnf is DNF4
    # by default; pass -Ddnf5_mode=true together with -Ddnf_command=dnf5 when
    # executing the same scenarios against DNF5.
    mode_value = context.config.userdata.get("dnf5_mode", "no").lower()
    context.dnf5_mode = mode_value in ("yes", "y", "1", "true")
    context.repos = {}


def after_step(context, step):
    if step.status == model.Status.failed:
        print_last_command(context)


def after_scenario(context, scenario):
    del context.dnf
