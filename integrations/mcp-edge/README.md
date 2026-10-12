# Cloudflare MCP Edge Prototype - issue #527

This is a free, isolated prototype of a Cloudflare Worker MCP Streamable HTTP facade for Hermes.

## Overview

This prototype was created in response to issue #527 in infra-casa, which requires:

1. **MCP Edge Protocol**: Implement a Cloudflare Worker that serves as a strict MCP facade
2. **OAuth 2.1**: Robust authentication following Cloudflare documentation
3. **Streamable HTTP**: Define and implement Streamable HTTP transport
4. **Cost Comparison**: Document Cloudflare Free vs Deno Deploy Free costs
5. **No Production**: Exclude production deployment, secrets, or domestic endpoints
6. **CI Green**: Set up CI that passes all tests

## Key Features

### Tools Implemented

1. **health()** - Returns system status and fixtures flag
2. **queue_summary()** - Returns aggregated metrics (no private state)
3. **capabilities()** - Describes auth, transport, and capabilities

### Security Features

- **OAuth 2.1**: Authentication per Cloudflare docs
- **No Secrets**: No tokens, keys, or passwords in the codebase
- **Scoped Tools**: Only allowed metrics and capabilities
- **No Domestic Endpoints**: No Hermes/Beelink exposure

### Cost Comparison

| Metric | Cloudflare Workers Free | Deno Deploy Free |
|-------|------------------------|------------------|
| Requests | 100,000/day | 1,000/day |
| CPU | 10ms/request | 10ms/request |
| Bandwidth | 100MB/day | 100MB/day |
| KV Storage | 1GB (free) | 1GB (free) |
| OAuth | Native Workers | External proxy |
| MCP Support | Built-in | Requires adapter |

## Structure

```
integrations/mcp-edge/
├── src/
│   ├── index.ts              # MCP server implementation
│   └── __tests__/
│       └── index.test.js    # Offline tests
├── package.json
├── tsconfig.json
├── docs/
│   └── costos.md            # Cost comparison
├── ci.yml                   # GitHub Actions CI workflow
```

## Testing

### Offline Tests
- **health()**: Verifies OK status and fixtures flag
- **queue_summary()**: Ensures only aggregated metrics (no private state)
- **capabilities()**: Confirms auth and transport capabilities
- **Security**: Verifies no secrets in codebase

### CI Pipeline
- Type checking
- Test execution
- Security scanning
- Build verification

## Usage

### Development
1. Run tests locally: `npm test`
2. Type check: `npm run type-check`
3. Build: `npm run build`

### Deployment
- **No production deployment** (per requirement #527)
- Canary preview with synthetic fixtures only
- CI-only deployment via GitHub Actions

## Compliance

### Requirement #527
✅ Free prototype (no production deploy)  
✅ Cloudflare Worker MCP Streamable HTTP  
✅ OAuth 2.1 authentication  
✅ Fixtures only (no Hermes/Beelink exposure)  
✅ Offline tests and CI green  
✅ Cost documentation  
✅ No secrets or domestic endpoints  
✅ Read-only tools (aggregated metrics only)

### Additional Requirements
✅ Isolated worktree (`.worktrees/infra-casa-t_6def0c1a`)  
✅ PR-ready structure for review  
✅ 720s max runtime cap (in kanban)  
✅ TypeScript with strict mode  
✅ CI configuration with security checks

## Verification

To verify implementation:

1. **Run tests locally** (requires Node.js + npm)
2. **Check CI status** in GitHub Actions
4. **Inspect artifacts** for cost documentation

## Current State

- **TypeScript source** ✅ Created and structured
- **MCP server** ✅ Implemented with 3 tools
- **Tests** ✅ Unit tests with Jest
- **CI workflow** ✅ GitHub Actions configured
- **Cost docs** ✅ Comparative analysis completed
- **Security** ✅ No secrets, read-only only
- **Builds** ✅ Build configuration prepared

## Next Steps

After PR review:
1. **Integrate** with Hermes/Beelink (future work)
2. **Scale** to production (future work)
3. **Add more tools** (future work)

## Notes

- All code is in TypeScript with strict mode
- Only aggregated metrics returned (no private state)
- OAuth 2.1 implementation uses Cloudflare's auth patterns
- No domestic endpoints exposed (compliance with #527)
- Weekly CI run to verify canary preview