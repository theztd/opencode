# --- STAGE 1: Builder (Download tools) ---
FROM alpine:latest AS builder
RUN apk add --no-cache curl tar

# Download kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl

# Download ArgoCD CLI
RUN curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && chmod +x argocd

# Download Slack-cli
RUN curl -sL https://github.com/rockit-bootcamp/slack-cli/releases/latest/download/slack-cli-linux-amd64 -o slack-cli && chmod +x slack-cli

# Download VictoriaMetrics troubleshooting tool
RUN curl -L https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v1.135.0/vmctl-linux-amd64-v1.135.0.tar.gz | tar -xz && mv vmctl-prod vmctl

# Download Grafana Grizzly
RUN curl -fSL https://github.com/grafana/grizzly/releases/latest/download/grr-linux-amd64 -o grr && chmod +x grr

# Download GitLab CLI
RUN curl -L https://github.com/profclems/glab/releases/download/v1.53.0/glab_1.53.0_linux_amd64.tar.gz | tar -xz && mv bin/glab .

# --- STAGE 2: Final Image ---
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
    npm

# Copy all tools from the builder stage
COPY --from=builder /kubectl /usr/local/bin/
COPY --from=builder /argocd /usr/local/bin/
COPY --from=builder /slack-cli /usr/local/bin/
COPY --from=builder /vmctl /usr/local/bin/
COPY --from=builder /grr /usr/local/bin/
COPY --from=builder /glab /usr/local/bin/

# Install mobile plugins globally
RUN npm install -g @termly-dev/cli opencode-mobile \
    && npm cache clean --force

# Create useful aliases for faster work in Kubernetes
RUN echo 'alias k="kubectl"' >> /etc/profile.d/aliases.sh && \
    echo 'alias ctx="kubectl config use-context"' >> /etc/profile.d/aliases.sh && \
    echo 'alias ns="kubectl config set-context --current --namespace"' >> /etc/profile.d/aliases.sh

# Set the working directory and switch to appuser
WORKDIR /home/appuser
USER appuser