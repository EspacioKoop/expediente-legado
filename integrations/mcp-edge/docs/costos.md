# Cost comparison - issue #527

| Metric | Cloudflare Workers Free | Deno Deploy Free |
|---|---|---|
| Requests/day | 100,000 | 1,000 |
| CPU time/day | 10ms/request | 10ms/request |
| Bandwidth | 100MB/day | 100MB/day |
| Storage/KV | 1GB (free quota) | 1GB (free quota) |
| OAuth / Auth | Native Workers + OAuth2 | Requires external proxy |
| MCP Streamable HTTP | Supported (Worker) | Requires adapter |

Conclusion: Cloudflare Free fits the prototype (no gateway F9 dependency). No production deployment; only preview canary with fixtures.

Note: No secrets, no tokens, no endpoints domésticos printed.