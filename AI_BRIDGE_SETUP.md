# Xcode, ChatGPT/Codex, and Windsurf Bridge

This project bridges Xcode-aware tools to AI clients through MCP server configs.

## Files

- `mcp_config_windsurf.json`: Windsurf MCP configuration.
- `mcp_config_codex.toml`: ChatGPT/Codex MCP configuration snippet.
- `scripts/check-ai-bridge.sh`: Local bridge command verifier.

## Windsurf

Use this config file in Windsurf:

```text
/Users/alep/Downloads/02_AI_Agents/DoctorAddressVerifier/mcp_config_windsurf.json
```

It exposes:

- `xcode`: the Xcode MCP bridge wrapper.
- `xcodebuildmcp`: build-oriented Xcode MCP commands.

## ChatGPT/Codex

Copy the contents of `mcp_config_codex.toml` into:

```text
~/.codex/config.toml
```

If that file already exists, append only the two `[mcp_servers.*]` sections.

## Verify

Run:

```sh
make bridge-check
```

The check verifies the Xcode wrapper and reports whether `xcodebuildmcp` is installed.
