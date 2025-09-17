# MCP Configuration for Augment

## Overview

Model Context Protocol (MCP) servers cannot be configured via files in the repository. They must be configured through the Augment Settings Panel in VS Code.

## How to Configure MCP Servers

### Method 1: Easy MCP (Recommended)
1. Open Augment extension in VS Code
2. Navigate to Easy MCP pane in settings
3. Click "+" button next to desired integration
4. Follow OAuth or API token setup

### Method 2: Import from JSON
1. Open Augment Settings Panel (⋯ menu → Settings)
2. Go to MCP section
3. Click "Import from JSON"
4. Paste the configuration below and click Save

## Recommended MCP Configuration

```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-context7"]
    }
  }
}
```

## Available MCP Servers for iOS Development

### Context7
- **Purpose**: Up-to-date documentation and code examples
- **Setup**: `npx -y @upstash/context7-mcp`
- **Use case**: Get latest iOS/Swift documentation and best practices

### Sequential Thinking
- **Purpose**: Enforces planning-first development approach
- **Setup**: `npx -y @modelcontextprotocol/server-sequential-thinking`
- **Use case**: Ensures UNDERSTAND → DESIGN → PLAN → VERIFY → SUMMARY workflow

## Verification

After configuring MCP servers:
1. Restart VS Code
2. Open Augment Agent
3. Check that MCP servers appear in the context menu (@)
4. Test with a query like "Help me plan a new iOS feature"

## Troubleshooting

- Ensure Node.js is installed for npx commands
- Check Augment extension version (MCP requires recent versions)
- Verify network connectivity for remote MCP servers
- Check Augment logs if servers fail to start
