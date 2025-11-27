# Docker Deployment Guide for Obsidian MCP Server

This guide explains how to build and run the Obsidian MCP server using Docker, providing a clean isolation from your local Python environment.

## Prerequisites

- Docker Desktop installed and running
- Your Obsidian vault path (e.g., `C:\Users\jfbeaulieu\Documents\Obsidian Vault`)
- Optional: Obsidian REST API key if using API features

## Quick Start

### 1. Build the Docker Image

**Windows:**

```cmd
build.bat
```

**Linux/Mac:**

```bash
chmod +x build.sh
./build.sh
```

Or manually:

```bash
docker build -t obsidian-mcp:latest .
```

### 2. Configure Your MCP Client

Add the following configuration to your MCP settings file:

**For Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "obsidian-docker": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--network=host",
        "-v",
        "C:/Users/jfbeaulieu/Documents/Obsidian Vault:/vault",
        "-e",
        "OBSIDIAN_REST_API_KEY=your_api_key_here",
        "-e",
        "OBSIDIAN_API_URL=http://host.docker.internal:27123",
        "obsidian-mcp:latest"
      ]
    }
  }
}
```

**For Roo Code** (`.roo/mcp.json`):

```json
{
  "mcpServers": {
    "obsidian-docker": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--network=host",
        "-v",
        "C:/Users/jfbeaulieu/OneDrive - Nmédia/Obsidian/Nmedia:/vault",
        "-e",
        "OBSIDIAN_REST_API_KEY=your_api_key_here",
        "-e",
        "OBSIDIAN_API_URL=http://host.docker.internal:27123",
        "obsidian-mcp:latest"
      ]
    }
  }
}
```

### 3. Restart Your MCP Client

Restart Claude Desktop or Roo Code to load the new configuration.

## Configuration Details

### Environment Variables

Pass configuration via Docker environment variables:

- `OBSIDIAN_REST_API_KEY`: Your Obsidian REST API key (required for API features)
- `OBSIDIAN_API_URL`: Complete API URL including protocol and port (e.g., `http://host.docker.internal:27123`)

### Volume Mounting

The container expects your Obsidian vault to be mounted at `/vault`:

```bash
-v "C:/Path/To/Your/Vault:/vault"
```

**Important:** Use absolute paths for the host side of the volume mount.

### Network Access

- `--network=host`: Allows the container to access Obsidian's local API
- For Windows/Mac, you might need to use `host.docker.internal` instead of `localhost` in API calls

## Testing

### Using MCP Inspector

Test your Docker setup with the official MCP Inspector:

```bash
# Install MCP Inspector globally
npm install -g @modelcontextprotocol/inspector

# Run inspector with your Docker command
mcp-inspector --command "docker run -i --rm --network=host -v 'C:/Users/jfbeaulieu/Documents/Obsidian Vault:/vault' obsidian-mcp:latest"
```

This will open a web interface where you can:

- See all available tools
- Test individual tool calls
- Verify the server is responding correctly

### Manual Testing

Test the container directly:

```bash
# Basic startup test
docker run -i --rm obsidian-mcp:latest --help

# With vault mounted
docker run -i --rm -v "C:/Path/To/Vault:/vault" obsidian-mcp:latest
```

### MCP Tool Testing

After configuring your MCP client, test the Docker deployment:

```bash
# Test get_active_file_tool
# Should return JSON with active file details

# Test list_notes_tool
# Should return list of notes in specified directory
```

**Expected Results:**

- `get_active_file_tool`: Returns complete JSON with file metadata, frontmatter, and content
- `list_notes_tool`: Returns array of notes with paths and names
- All tools should work identically to local `uv` execution

## Troubleshooting

### Common Issues

**"Permission denied" on Windows:**

- Ensure Docker Desktop has file sharing permissions for your vault directory
- Try running Docker Desktop as administrator

**"Network unreachable":**

- Remove `--network=host` and use `host.docker.internal` in API calls
- Check that Obsidian is running and the REST API is enabled

**Container exits immediately:**

- The `-i` flag is missing from the Docker run command
- Check the container logs: `docker logs <container_id>`

**Tools not appearing in client:**

- Verify the JSON syntax in your MCP configuration
- Restart the MCP client completely
- Check the client logs for Docker command errors

**API returns null or empty data:**

- Ensure `OBSIDIAN_REST_API_KEY` is correctly set (not `OBSIDIAN_API_KEY`)
- Use `OBSIDIAN_API_URL=http://host.docker.internal:27123` instead of separate host/port variables
- Verify the Obsidian REST API plugin is enabled and configured

**JSON parsing errors:**

- The Obsidian API returns Markdown by default; ensure tools use proper `Accept` headers for JSON responses
- Check that the API key has the correct permissions

### Debug Mode

Run with verbose logging:

```bash
docker run -i --rm -e PYTHONPATH=/app -v "C:/Path/To/Vault:/vault" obsidian-mcp:latest
```

### Logs

View container logs:

```bash
# Find container ID
docker ps -a

# View logs
docker logs <container_id>
```

## Advanced Configuration

### Custom Image Tag

```bash
# Build with custom tag
docker build -t my-obsidian-mcp:v1.0 .

# Use in configuration
"args": ["run", "-i", "--rm", "my-obsidian-mcp:v1.0"]
```

### Multiple Vaults

Mount multiple vaults:

```json
{
  "args": [
    "run",
    "-i",
    "--rm",
    "-v",
    "C:/Vault1:/vault1",
    "-v",
    "C:/Vault2:/vault2",
    "-e",
    "PRIMARY_VAULT=/vault1",
    "obsidian-mcp:latest"
  ]
}
```

### Development Mode

For development with live code reloading:

```dockerfile
# Add to Dockerfile for dev mode
COPY . /app
RUN pip install -e .
```

## Security Considerations

- The container runs as a non-root user (`obsidian`)
- File permissions are preserved through volume mounts
- No sensitive data is stored in the image
- API keys are passed via environment variables (not baked into the image)

## Performance

- Image size: ~200-300MB (Python slim + dependencies)
- Startup time: ~2-5 seconds
- Memory usage: ~50-100MB at idle
- No significant performance difference from native execution

## Updating

When the Obsidian MCP code is updated:

1. Pull the latest changes
2. Rebuild the image: `docker build -t obsidian-mcp:latest .`
3. Restart your MCP client

The container will automatically use the updated image on next tool call.
