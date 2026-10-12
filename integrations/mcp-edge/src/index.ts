export interface MCPToolResult {
  content: { text?: string; mimeType?: string }[];
  isError?: boolean;
}

/**
 * Prototype Cloudflare MCP Edge - issue #527
 * Strictly typed facade, fixtures only, no production deploy, no secrets.
 */
export class MCPServer {
  private fixturesEnabled = true;

  constructor(private authToken?: string) {}

  health(): MCPToolResult {
    return {
      content: [{ text: JSON.stringify({ status: "ok", fixtures: this.fixturesEnabled }) }],
    };
  }

  queue_summary(): MCPToolResult {
    // Only aggregated metrics allowed per #527 scope
    const metrics = {
      totalIssues: 23,
      openIssues: 7,
      closedIssues: 16,
      resolutionRate: 0.695,
    };
    return { content: [{ text: JSON.stringify(metrics) }] };
  }

  capabilities(): MCPToolResult {
    const caps = {
      auth: "OAuth 2.1 (Cloudflare docs)",
      transport: "Streamable HTTP",
      fixturesOnly: true,
      scopes: ["read:metrics", "read:capabilities"],
      mutationsBlocked: true,
    };
    return { content: [{ text: JSON.stringify(caps) }] };
  }
}
