# Changelog

All notable changes to agent-flywheel-cross-platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-30

### Added
- **Cross-platform support** for macOS, Linux, and WSL
- **One-command installer** (`./install.sh`) with dependency auto-detection
- **Health check script** (`./scripts/doctor.sh`) for system verification
- **Quick launcher** (`./start`) for easy session management
- **Shared TodoList integration** via `CLAUDE_CODE_TASK_LIST_ID`
- **Multi-LLM support** - Run Claude Code and Codex agents together
- **MCP Agent Mail integration** for agent-to-agent communication
- **File reservation system** with TTL-based advisory locks
- **Pre-edit hooks** for automatic conflict detection
- **Governance framework** (Phase 1: Advisory mode)
  - Scope limits (max 10 files, 500 lines per session)
  - Time limits (30-minute max unattended runtime)
  - Self-review workflow with time-boxing
- **Expiry notification monitoring** for file reservations
- **Bypass mechanism** with justification logging
- **Cross-platform session management** via tmux
- **Comprehensive documentation**
  - README.md with quick start
  - WSL-specific setup guide
  - Agent mail documentation
  - Troubleshooting guides

### Changed
- **Dynamic path detection** - No hardcoded user paths
- **Platform-aware Python bin paths** - Detects macOS vs Linux automatically
- **Shell detection** - Works with both bash and zsh
- **Portable shell constructs** - Cross-platform sed/awk alternatives

### Fixed
- Cross-platform sed compatibility issues
- Python path detection on different platforms
- Tmux configuration portability
- Session naming and sanitization
- Agent name registration across platforms

### Security
- No exposed credentials in source code
- Proper .gitignore for sensitive files
- Token files referenced via environment variables
- Secure key setup script

## [0.1.0] - 2026-01-28

### Added
- Initial fork from agent-flywheel
- Basic cross-platform compatibility
- WSL support

---

## Attribution

**Based on**: [agent-flywheel](https://agent-flywheel.com) by Jeffrey Emanuel
**Core components**: MCP Agent Mail, file reservations, multi-agent patterns
**License**: MIT (see LICENSE file)

---

## Upgrade Notes

### From 0.x to 1.0.0
- Run `./install.sh` to set up new dependencies
- Review new governance rules in integration project
- Update shell configuration for Python bin paths
- Start MCP Agent Mail server if not running

---

## Roadmap

### Version 1.1.0 (Planned)
- [ ] Context management and clearing automation
- [ ] Beads task management full integration
- [ ] Enhanced telemetry and metrics
- [ ] Web dashboard for multi-agent monitoring

### Version 2.0.0 (Future)
- [ ] CASS (session search) integration
- [ ] NTM (agent swarm orchestration)
- [ ] Multi-repo coordination
- [ ] Enhanced governance with enforcement mode

---

## Contributing

See CONTRIBUTING.md for guidelines on how to contribute to this project.

## Support

- **Issues**: Report bugs via GitHub issues
- **Documentation**: See README.md and docs/ directory
- **Community**: Link to discussions/forums when available
