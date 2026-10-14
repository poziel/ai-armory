# MCP servers

Reserved for custom Model Context Protocol servers. Create one folder per server when an implementation is needed.

Each server should own its source, dependency manifest, checks, and `README.md`. Document its tools, transport, setup, configuration, and permissions.

Keep credentials in environment variables. If configuration examples are needed, commit sanitized samples such as `.env.example`. Document which operations read data and which change external state.
