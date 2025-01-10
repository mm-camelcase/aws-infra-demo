# Extend the official docker-terragrunt image
FROM devopsinfra/docker-terragrunt:tf-1.10.3-tg-0.71.1

# Set working directory
WORKDIR /app

# Download and install tfplandoc using curl
RUN curl -L -o tfplandoc_0.4.1_linux_amd64.zip https://github.com/Azure/tfplandoc/releases/download/v0.4.1/tfplandoc_0.4.1_linux_amd64.zip \
    && unzip tfplandoc_0.4.1_linux_amd64.zip \
    && mv tfplandoc_v0.4.1 /usr/local/bin/tfplandoc \
    && chmod +x /usr/local/bin/tfplandoc \
    && rm tfplandoc_0.4.1_linux_amd64.zip
