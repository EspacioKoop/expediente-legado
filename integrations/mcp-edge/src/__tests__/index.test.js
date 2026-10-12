const { MCPServer } = require('./src/index.js');

describe('MCP Server Prototype - issue #527', () => {
  test('health() returns ok status with fixtures flag', () => {
    const server = new MCPServer();
    const result = server.health();
    expect(result.content[0].text).toContain('"status":"ok"');
    expect(result.content[0].text).toContain('"fixtures":true');
  });

  test('queue_summary() returns aggregated metrics only', () => {
    const server = new MCPServer();
    const result = server.queue_summary();
    const metrics = JSON.parse(result.content[0].text);
    expect(metrics).toHaveProperty('totalIssues');
    expect(metrics).toHaveProperty('openIssues');
    expect(metrics).toHaveProperty('closedIssues');
    expect(metrics).toHaveProperty('resolutionRate');
    // Ensure no shell or proxy details (fixtures only)
    expect(result.content[0].text).not.toMatch(/shell|proxy|bridge/i);
  });

  test('capabilities() describes auth and transport', () => {
    const server = new MCPServer();
    const result = server.capabilities();
    const caps = JSON.parse(result.content[0].text);
    expect(caps.auth).toContain('OAuth 2.1');
    expect(caps.transport).toBe('Streamable HTTP');
    expect(caps.fixturesOnly).toBe(true);
    expect(caps.mutationsBlocked).toBe(true);
  });

  test('no production deployment configuration', () => {
    const fs = require('fs');
    const wranglerPath = 'wrangler.toml';
    // This will be created if needed; for now verify no deploy config exists
    const noDeployFiles = !fs.existsSync(wranglerPath) ||
      (fs.existsSync(wranglerPath) && 
       !fs.readFileSync(wranglerPath, 'utf8').includes('[env.production]'));
    expect(noDeployFiles).toBe(true);
  });
});