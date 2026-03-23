# MobileClaw

iOS & macOS Multi-Agent AI Platform with MCP tool integration.

## Features

- **Multi-Model LLM Support**: Claude (Anthropic), GPT (OpenAI), DeepSeek, Qwen, Moonshot, and custom OpenAI-compatible endpoints
- **Multi-Agent Orchestration**: Create and configure multiple AI agents that collaborate on complex tasks
- **MCP Tool Integration**: Model Context Protocol support for extensible tool calling
- **Plugin System**: Extensible architecture for custom functionality
- **iCloud Sync**: Seamless sync of conversations, agents, and settings across devices
- **Streaming Chat**: Real-time streaming responses with Markdown rendering

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 16.0+
- Swift 5.9+

## Architecture

Modular Swift Package architecture:

| Package | Purpose |
|---------|---------|
| **MCCore** | Core models, protocols, and error types |
| **MCNetworking** | LLM API clients (Anthropic, OpenAI-compatible) with SSE streaming |
| **MCPersistence** | SwiftData models with CloudKit sync |
| **MCPClient** | MCP protocol client for tool integration |
| **MCAgents** | Multi-agent orchestration engine |

## Build

```bash
# Install xcodegen if needed
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Build
xcodebuild build -scheme MobileClaw-macOS -destination 'platform=macOS'
xcodebuild build -scheme MobileClaw-iOS -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Supported Providers

| Provider | API Type | Models |
|----------|----------|--------|
| Anthropic | Native | Claude Opus 4, Sonnet 4, Haiku 4.5 |
| OpenAI | Native | GPT-4o, GPT-4o Mini |
| DeepSeek | OpenAI-compatible | DeepSeek V3, DeepSeek R1 |
| Qwen | OpenAI-compatible | Qwen Max, Qwen Turbo |
| Moonshot | OpenAI-compatible | Moonshot V1 128K |
| Custom | OpenAI-compatible | User-defined |

## License

MIT
