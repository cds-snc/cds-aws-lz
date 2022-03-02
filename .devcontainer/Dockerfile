# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.217.4/containers/debian/.devcontainer/base.Dockerfile

# [Choice] Debian version (use bullseye on local arm64/Apple Silicon): bullseye, buster
ARG VARIANT="buster"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# ** [Optional] Uncomment this section to install additional packages. **
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
# Install Terragrunt

ARG TERRAGRUNT_VERSION
ARG TERRAGRUNT_SRC=https://github.com/gruntwork-io/terragrunt/releases/download
RUN curl -Lo terragrunt ${TERRAGRUNT_SRC}/v"${TERRAGRUNT_VERSION}"/terragrunt_linux_"$(dpkg --print-architecture)" \
    && chmod +x terragrunt \
    && mv terragrunt /usr/local/bin/

# Install AWS CLI
ARG AWS_CLI_VERSION
ARG AWS_SRC=https://awscli.amazonaws.com
COPY aws_cli.asc ./
RUN curl -Lo awscliv2.zip "${AWS_SRC}/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" \
    && curl -Lo awscliv2.sig "${AWS_SRC}/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip.sig" \
    && gpg --import ./aws_cli.asc \
    && gpg --verify awscliv2.sig awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install -i /usr/local/aws-cli -b /usr/local/bin


COPY apt-packages.txt ./
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && xargs apt-get -y install --no-install-recommends < apt-packages.txt

# Setup aliases and autocomplete
RUN echo "\n\
complete -C /usr/bin/aws_completer aws\n\
complete -C /usr/local/bin/terraform terraform\n\
complete -C /usr/local/bin/terraform terragrunt\n\
alias tf='terraform'\n\
alias tg='terragrunt'\n\
alias ll='la -la' \n\
alias laws='aws --endpoint-url=http://localstack:4566 --region=ca-central-1' \n\
export PATH=$PATH:/usr/local/go/bin/" >> /home/vscode/.zshrc