# Claude Code Project Instructions

## MCP Server Usage

This project has access to specialized MCP servers that should be used proactively when working with NixOS configuration.

### NixOS MCP Server

Use the NixOS MCP tools whenever working with packages, system options, or Home Manager configuration.

**When to use:**
- Searching for packages to install → `mcp__nixos__nixos_search`
- Looking up package details, versions, or descriptions → `mcp__nixos__nixos_info`
- Finding NixOS system options (services, hardware, boot, etc.) → `mcp__nixos__nixos_search` with search_type="options"
- Searching for Home Manager options → `mcp__nixos__home_manager_search`
- Getting details about Home Manager options → `mcp__nixos__home_manager_info`
- Finding programs available in nix-darwin → `mcp__nixos__darwin_search`
- Looking for community flakes → `mcp__nixos__nixos_flakes_search`
- Finding specific package versions for pinning → `mcp__nixos__nixhub_package_versions`

**Examples:**
```
User: "Add Firefox to my system"
→ Use mcp__nixos__nixos_search with query="firefox" to find the correct package name
→ Confirm it's "firefox" package
→ Add to home.packages in shared/home.nix

User: "Enable Tailscale VPN"
→ Use mcp__nixos__nixos_search with query="tailscale" and search_type="options"
→ Find services.tailscale.enable option
→ Add to shared/configuration.nix

User: "Configure Git with Home Manager"
→ Use mcp__nixos__home_manager_search with query="git"
→ Find programs.git options
→ Use mcp__nixos__home_manager_info for specific option details
→ Configure in shared/home.nix

User: "I need Python 3.11 specifically"
→ Use mcp__nixos__nixhub_find_version with package_name="python" and version="3.11"
→ Get the specific nixpkgs commit hash
→ Show user how to pin the package
```

**Best Practices:**
- Always search for packages before adding them to verify correct naming
- Use options search to discover available NixOS configuration options
- Check Home Manager options when configuring user-level programs
- Reference nixhub for version-specific requirements

### Context7 MCP Server

Use Context7 to get up-to-date documentation for libraries and frameworks used in this configuration.

**When to use:**
- User asks about Qtile configuration → Get latest Qtile documentation
- Questions about Neovim plugin configuration → Get plugin documentation
- Help with Home Manager syntax → Get Home Manager docs
- Understanding NixOS module options → Get NixOS manual content
- Library-specific questions (e.g., configuring starship, alacritty) → Get library docs

**Workflow:**
1. Use `mcp__context7__resolve-library-id` to find the correct library ID
2. Use `mcp__context7__get-library-docs` with the library ID and specific topic

**Examples:**
```
User: "How do I configure Qtile to have a system tray?"
→ resolve-library-id for "qtile"
→ get-library-docs with topic="system tray" or "widgets"

User: "Add a new LSP server to my Neovim config"
→ resolve-library-id for "neovim lspconfig"
→ get-library-docs with topic="language servers"

User: "Configure starship prompt with custom icons"
→ resolve-library-id for "starship"
→ get-library-docs with topic="configuration" or "icons"
```

**Best Practices:**
- Use mode='code' (default) for API references and configuration examples
- Use mode='info' for conceptual explanations
- Be specific with the topic parameter for better results
- Always resolve the library ID first unless user provides exact format

## Project-Specific Rules

1. **Package Installation**
   - ALWAYS use NixOS MCP search before adding packages to verify correct names
   - Prefer adding packages to `shared/home.nix` (user-level) over `shared/configuration.nix` (system-level)
   - System-level packages are for: system services, hardware support, essential CLI tools
   - User-level packages are for: applications, development tools, user-specific utilities

2. **Configuration Changes**
   - Use NixOS options search to find correct configuration syntax
   - Check Home Manager search for programs.* options
   - Always reference line numbers when explaining changes (e.g., `shared/configuration.nix:28`)
   - Test changes with `make test` before suggesting `make rebuild`

3. **Documentation**
   - When user asks "how to" questions, use Context7 to get current documentation
   - Prefer official documentation over assumptions
   - For NixOS-specific questions, use NixOS MCP search for options

4. **Version Management**
   - Use nixhub tools when user needs specific versions
   - Explain how to pin packages using fetchFromGitHub or specific nixpkgs commits
   - Show the trade-offs of pinning vs using unstable channel

## Common Workflows

### Adding a New Package
1. Search with `mcp__nixos__nixos_search` to find package name
2. Verify package details with `mcp__nixos__nixos_info`
3. Add to appropriate file (home.nix or configuration.nix)
4. Suggest rebuild command

### Configuring a Service
1. Search options with `mcp__nixos__nixos_search` (search_type="options")
2. Check option details for required parameters
3. Add configuration to `shared/configuration.nix`
4. Explain what the option does

### Setting Up Home Manager Program
1. Search with `mcp__nixos__home_manager_search`
2. Get option details with `mcp__nixos__home_manager_info`
3. If complex, use Context7 for the program's documentation
4. Add configuration to `shared/home.nix`
5. Show example configuration

### Debugging Configuration
1. Check syntax with current NixOS options documentation
2. Use Context7 for program-specific configuration issues
3. Suggest `make test` to validate without switching
4. Reference relevant line numbers in error messages
