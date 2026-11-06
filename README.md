# compozy-headless

Runs [CompozyOS](https://github.com/compozy/compozy) (v0.5.3) as a server container.

Why the nginx hop: the daemon refuses `/api` unless it is bound to a loopback host, and it
rejects browser requests whose `Host`/`Origin` is not that same loopback origin. nginx listens on
`0.0.0.0:8080`, rewrites `Host` to `127.0.0.1:2123` and strips the origin headers, so the built-in
web UI works through a reverse proxy. Authentication belongs on the proxy (Traefik basicauth).

- state: `/data` (volume) — `$HOME/.compozy`
- workspaces: `/workspaces` (volume)
- env: `COMPOZY_PROVIDER` (default `opencode`), `OPENCODE_API_KEY` (optional, writes opencode auth)

```
docker build -t compozy-headless:0.5.3 .
docker run -d -p 8080:8080 -v compozy_data:/data -v compozy_ws:/workspaces compozy-headless:0.5.3
```
