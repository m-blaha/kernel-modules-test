# Selected DNF5 repository steps. The fixture repositories are local only.
import behave
import os

from common.lib.file import create_file_with_contents
from common.lib.cmd import run_in_context


def repo_config(repo):
    return {"name": repo + " test repository", "enabled": "1"}


def write_repo_config(context, repo, config):
    text = "[{}]\n".format(repo)
    for key, value in config.items():
        text += "{}={}\n".format(key, value)
    create_file_with_contents(
        os.path.join(context.dnf.installroot, "etc/yum.repos.d", repo + ".repo"), text)


class RepoInfo(object):
    def __init__(self, context, repo):
        self.path = os.path.join(context.scenario.repos_location, repo)
        self.config = repo_config(repo)
        self.config["baseurl"] = "file://" + self.path


def get_repo_info(context, repo):
    return context.dnf.repos.setdefault(repo, RepoInfo(context, repo))


def generate_repodata(context, repo):
    repo_info = get_repo_info(context, repo)
    if repo in context.repos:
        return
    if not os.path.isdir(repo_info.path):
        raise AssertionError("Fixture repository does not exist: {}".format(repo_info.path))
    run_in_context(context, "createrepo_c --no-database --simple-md-filenames '{}'".format(repo_info.path))
    context.repos[repo] = True


@behave.step("I use repository \"{repo}\"")
def use_repository(context, repo):
    generate_repodata(context, repo)
    write_repo_config(context, repo, get_repo_info(context, repo).config)
