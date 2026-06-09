#!/bin/bash

echo "🔧 Claap MCP Installer for Claude Desktop"
echo "=========================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed."
    echo "👉 Please install it from https://nodejs.org (LTS version)"
    echo "   Then run this script again."
    exit 1
fi

echo "✅ Node.js found: $(node --version)"

# Find npx path
NPX_PATH=$(which npx)
if [ -z "$NPX_PATH" ]; then
    echo "❌ npx not found. Please reinstall Node.js from https://nodejs.org"
    exit 1
fi

echo "✅ npx found at: $NPX_PATH"

# Ask for Claap API key
echo ""
echo "👉 Get your API key from: app.claap.io → Settings → API"
read -p "Enter your Claap API key: " CLAAP_API_KEY

if [ -z "$CLAAP_API_KEY" ]; then
    echo "❌ API key cannot be empty"
    exit 1
fi

echo ""
echo "⚙️  Updating Claude Desktop config..."

# Claude config path
CONFIG_DIR="$HOME/Library/Application Support/Claude"
CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

# Create directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Create config if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "{}" > "$CONFIG_FILE"
fi

# Check if jq is available for JSON manipulation
if command -v jq &> /dev/null; then
    # Use jq to safely add mcpServers
    UPDATED=$(jq --arg npx "$NPX_PATH" --arg key "$CLAAP_API_KEY" '
        .mcpServers = (.mcpServers // {}) | 
        .mcpServers.claap = {
            "command": $npx,
            "args": [
                "-y",
                "mcp-remote",
                "https://api.claap.io/mcp",
                "--header",
                ("Authorization: Bearer " + $key)
            ]
        }
    ' "$CONFIG_FILE")
    echo "$UPDATED" > "$CONFIG_FILE"
else
    # Manual approach if jq not available
    # Read existing content
    EXISTING=$(cat "$CONFIG_FILE")
    
    # Check if mcpServers already exists
    if echo "$EXISTING" | grep -q '"mcpServers"'; then
        echo "⚠️  mcpServers already exists in config."
        echo "👉 Please manually add the Claap block to your config:"
        echo ""
        echo '{
  "command": "'"$NPX_PATH"'",
  "args": [
    "-y",
    "mcp-remote",
    "https://api.claap.io/mcp",
    "--header",
    "Authorization: Bearer '"$CLAAP_API_KEY"'"
  ]
}'
        echo ""
        echo "Add the above inside your existing mcpServers block with key \"claap\""
        exit 0
    else
        # Add mcpServers to existing config
        NEW_CONFIG=$(echo "$EXISTING" | sed 's/}$/,\n  "mcpServers": {\n    "claap": {\n      "command": "'"$NPX_PATH"'",\n      "args": ["-y", "mcp-remote", "https:\/\/api.claap.io\/mcp", "--header", "Authorization: Bearer '"$CLAAP_API_KEY"'"]\n    }\n  }\n}/')
        echo "$NEW_CONFIG" > "$CONFIG_FILE"
    fi
fi

echo ""
echo "✅ Config updated successfully!"
echo ""
echo "🎉 Installation complete!"
echo "=========================================="
echo "👉 Now restart Claude Desktop (Cmd + Q, then reopen)"
echo "👉 Look for the 🔨 hammer icon in the chat"
echo "👉 Test it by typing: 'List my recent Claap recordings'"
