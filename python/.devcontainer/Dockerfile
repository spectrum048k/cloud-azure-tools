# See https://aka.ms/devcontainer for more information.
# This file tells VS Code how to build/run your dev container.

FROM mcr.microsoft.com/devcontainers/python:3.11

# [Optional] Install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Install Python packages from requirements.txt if present
COPY azuread/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt || true

# [Optional] Set up a non-root user for VS Code
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update && apt-get install -y sudo \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /workspace

# [Optional] Expose any ports your app needs
# EXPOSE 8000

# [Optional] Set environment variables
# ENV PYTHONUNBUFFERED=1

# [Optional] Run any additional setup commands
# RUN <setup-command>
