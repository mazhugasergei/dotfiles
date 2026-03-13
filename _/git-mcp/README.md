# Git MCP Server

A Model Context Protocol (MCP) server that provides Git functionality through MCP tools.

## Installation

```bash
uv sync
```

## Configuration

Add this to your MCP configuration:

```json
"git-mcp-server": {
  "command": "uv",
  "args": ["--directory", "/home/user/dotfiles/_/git-mcp", "run", "main.py"]
}
```
