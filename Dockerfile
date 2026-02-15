# --- STAGE 1: Builder (Go-based binaries) ---
FROM alpine:latest AS builder
RUN apk add --no-cache curl tar

# Stažení statických binárek (rychlé, bezpečné, minimalistické)
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl
RUN curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && chmod +x argocd
RUN curl -sL https://github.com/rockit-bootcamp/slack-cli/releases/latest/download/slack-cli-linux-amd64 -o slack-cli && chmod +x slack-cli
RUN curl -L https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v1.135.0/vmctl-linux-amd64-v1.135.0.tar.gz | tar -xz && mv vmctl-prod vmctl
RUN curl -fSL https://github.com/grafana/grizzly/releases/latest/download/grr-linux-amd64 -o grr && chmod +x grr

# GitLab CLI (glab)
RUN curl -L https://github.com/profclems/glab/releases/download/v1.53.0/glab_1.53.0_linux_amd64.tar.gz | tar -xz && mv bin/glab .



# --- STAGE 2: Final Image ---
FROM ghcr.io/anomalyco/opencode:latest

USER root

# Install system tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    dnsutils \
    curl \
    ca-certificates \
    jq \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Copy prebuilded binaries
COPY --from=builder /kubectl /usr/local/bin/
COPY --from=builder /argocd /usr/local/bin/
COPY --from=builder /slack-cli /usr/local/bin/
COPY --from=builder /vmctl /usr/local/bin/
COPY --from=builder /grr /usr/local/bin/
COPY --from=builder /glab /usr/local/bin/

# Install plugins
RUN npm install -g @termly-dev/cli opencode-mobile \
    && npm cache clean --force

# Set favourite aliases
RUN echo 'alias k="kubectl"' >> /etc/bash.bashrc && \
    echo 'alias ctx="kubectl config use-context"' >> /etc/bash.bashrc && \
    echo 'alias ns="kubectl config set-context --current --namespace"' >> /etc/bash.bashrc

USER 1000
WORKDIR /home/opencode