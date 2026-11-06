# CompozyOS (compozy/compozy) headless server image.
# The daemon is local-first: it only serves its HTTP API when bound to a loopback
# host and only accepts browser requests whose Host/origin is that loopback host.
# nginx therefore listens on 0.0.0.0:8080, rewrites Host to 127.0.0.1:2123 and
# strips the browser origin headers before forwarding (put real auth in front).
FROM node:22-bookworm-slim

ARG COMPOZY_VERSION=0.5.3

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/data \
    COMPOZY_HTTP_PORT=2123 \
    COMPOZY_PUBLIC_PORT=8080

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git tar xz-utils nginx-light procps tini \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/compozy.tgz \
        "https://github.com/compozy/compozy/releases/download/v${COMPOZY_VERSION}/compozy_linux_x86_64.tar.gz" \
    && tar -xzf /tmp/compozy.tgz -C /usr/local/bin compozy \
    && chmod +x /usr/local/bin/compozy \
    && rm -f /tmp/compozy.tgz \
    && compozy version

# ACP agent CLIs available on PATH out of the box.
RUN npm install -g --no-audit --no-fund opencode-ai @openai/codex \
    && npm cache clean --force

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && nginx -t -c /etc/nginx/nginx.conf \
    && mkdir -p /data /workspaces /tmp/nginx-body /tmp/nginx-proxy \
    && chown -R node:node /data /workspaces /tmp/nginx-body /tmp/nginx-proxy

USER node
WORKDIR /workspaces
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/ > /dev/null || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
