FROM ghcr.io/anomalyco/opencode:latest

# Switch to root to install packages
USER root

# Install system tools using apk (Alpine package manager)
# We use bind-tools for the 'dig' command
RUN apk add --no-cache \
    git \
    openssh-client \
    bind-tools \
    curl \
    ca-certificates \
    jq \
    nodejs \
    kubectl \
    glab \
    npm

# Install mobile plugins globally
RUN npm install -g @termly-dev/cli opencode-mobile \
    && npm cache clean --force

# Download some tools
RUN curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && chmod +x argocd && mv argocd /usr/local/bin/argocd
RUN curl -sL https://github.com/rockit-bootcamp/slack-cli/releases/latest/download/slack-cli-linux-amd64 -o slack-cli && chmod +x slack-cli && mv slack-cli /usr/local/bin/slack-cli

# Create useful aliases for faster work in Kubernetes
RUN echo 'alias k="kubectl"' >> /etc/profile.d/aliases.sh && \
    echo 'alias ctx="kubectl config use-context"' >> /etc/profile.d/aliases.sh && \
    echo 'alias ns="kubectl config set-context --current --namespace"' >> /etc/profile.d/aliases.sh

# Set the working directory and switch to appuser
WORKDIR /home/appuser
USER appuser