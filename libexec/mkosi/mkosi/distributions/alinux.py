# SPDX-License-Identifier: LGPL-2.1+

from collections.abc import Iterable
from pathlib import Path

from mkosi.context import Context
from mkosi.distributions import centos, join_mirror
from mkosi.installer.rpm import RpmRepository, find_rpm_gpgkey, setup_rpm
from mkosi.installer.dnf import Dnf
from mkosi.util import listify


class Installer(centos.Installer):
    @classmethod
    def pretty_name(cls) -> str:
        return "Aliyun Linux"

    @classmethod
    def setup(cls, context: Context) -> None:
        Dnf.setup(context, cls.repositories(context))
        setup_rpm(context, dbpath=cls.dbpath(context))

    @staticmethod
    def gpgurls(context: Context) -> tuple[str, ...]:
        if (Path("/") / "etc/yum.repos.d/AlinuxApsara.repo").exists():
            site = "yum.tbsite.net"
        else:
            site = "mirrors.cloud.aliyuncs.com"

        url = f"http://{site}/alinux/{context.config.release}/RPM-GPG-KEY-ALINUX-{context.config.release}"

        return (
            find_rpm_gpgkey(
                context,
                f"RPM-GPG-KEY-AlmaLinux-{context.config.release}",
            ) or url,
        )

    @classmethod
    def repository_variants(cls, context: Context, repo: str) -> list[RpmRepository]:
        if (Path("/") / "etc/yum.repos.d/AlinuxApsara.repo").exists():
            site = "yum.tbsite.net"
        else:
            site = "mirrors.cloud.aliyuncs.com"

        url = f"baseurl=http://{site}/alinux/$releasever/{repo.lower()}/$basearch"
        return [RpmRepository(repo, url, cls.gpgurls(context))]

    @classmethod
    @listify
    def repositories(cls, context: Context) -> Iterable[RpmRepository]:
        yield from cls.repository_variants(context, "os")
        yield from cls.repository_variants(context, "updates")
        yield from cls.repository_variants(context, "module")
        yield from cls.repository_variants(context, "plus")
        yield from cls.repository_variants(context, "powertools")

        yield from cls.sig_repositories(context)

    @classmethod
    def sig_repositories(cls, context: Context) -> list[RpmRepository]:
        return []
