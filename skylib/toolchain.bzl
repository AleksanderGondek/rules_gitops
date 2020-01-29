# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""
This module defines docker toolchain rules. Forked: https://github.com/bazelbuild/rules_docker/blob/master/toolchains/docker/toolchain.bzl
"""

def _toolchain_configure_impl(repository_ctx):
    tool_path = ""
    if repository_ctx.attr.docker_path:
        tool_path = repository_ctx.attr.docker_path
    elif repository_ctx.which("docker"):
        tool_path = repository_ctx.which("docker")
    xz_path = repository_ctx.which("xz") or ""

    # If client_config is not set we need to pass an empty string to the
    # template.
    client_config = repository_ctx.attr.client_config or (repository_ctx.os.environ["HOME"] + "/.docker")
    repository_ctx.template(
        "BUILD",
        Label("@io_bazel_rules_docker//toolchains/docker:BUILD.tpl"),
        {
            "%{DOCKER_CONFIG}": "%s" % client_config,
            "%{DOCKER_TOOL}": "%s" % tool_path,
            "%{XZ_TOOL_PATH}": "%s" % xz_path,
        },
        False,
    )

    # Generate a custom variant authenticated version of the repository rule
    # container_push if a custom docker client config directory was specified.
    if client_config != "":
        repository_ctx.template(
            "pull.bzl",
            Label("@io_bazel_rules_docker//toolchains/docker:pull.bzl.tpl"),
            {
                "%{docker_client_config}": "%s" % client_config,
            },
            False,
        )

docker_toolchain_configure = repository_rule(
    attrs = {
        "client_config": attr.string(
            mandatory = False,
            doc = "A custom directory for the docker client " +
                  "config.json. If DOCKER_CONFIG is not specified, the value" +
                  " of the DOCKER_CONFIG environment variable will be used." +
                  " DOCKER_CONFIG is not defined, the default set for the " +
                  " docker tool (typically, the home directory) will be" +
                  " used.",
        ),
        "docker_path": attr.string(
            mandatory = False,
            doc = "The full path to the docker binary. If not specified, it will" +
                  "be searched for in the path. If not available, running commands" +
                  "that require docker (e.g., incremental load) will fail.",
        ),
    },
    implementation = _toolchain_configure_impl,
)
