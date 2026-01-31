# ChatGPT Subscription Setup Guide

## Overview

This feature branch adds support for using your **ChatGPT subscription** (Plus/Pro) instead of paying for OpenAI API usage. This can save you **$400+/month**!

## Cost Comparison

| Method | Cost | Best For |
|--------|------|----------|
| **ChatGPT OAuth (New!)** | $0 extra (uses your $20-200/month subscription) | Everyone with ChatGPT Plus/Pro |
| OpenAI API Key | ~$20/day = $600/month | Those without ChatGPT subscription |

**Savings: $400+/month by using ChatGPT subscription!**

---

## Quick Start

### For New Users

Run the installer - it will ask you which authentication method to use:

```bash
./install.sh
```

When prompted, choose **Option 1: ChatGPT Subscription (OAuth)**

### For Existing Users

Switch from API billing to ChatGPT subscription:

```bash
# Run the new OAuth setup script
./scripts/setup-codex-oauth.sh
```

This will:
1. Install Codex CLI
2. Remove your API key from shell config (if present)
3. Authenticate with your ChatGPT account via browser
4. Configure agents to use your subscription

---

## What Changed

### New Files

1. **`scripts/setup-codex-oauth.sh`** (New!)
   - Sets up Codex CLI with ChatGPT OAuth authentication
   - Removes API keys to prevent charges
   - Guides you through browser authentication

### Modified Files

1. **`README.md`**
   - Added prominent ChatGPT subscription option
   - Shows cost comparison
   - Recommends OAuth over API keys

2. **`install.sh`**
   - Added Step 4: AI Authentication Setup
   - Offers choice between OAuth and API key
   - Recommends OAuth option

3. **`scripts/setup-openai-key.sh`**
   - Added warning about API costs ($20+/day)
   - Recommends OAuth alternative
   - Requires confirmation before proceeding

---

## How It Works

### Before (API Billing):
```
Agent → OPENAI_API_KEY → OpenAI API → Pay per token
                                    ↓
                              $20/day charge
```

### After (ChatGPT OAuth):
```
Agent → Codex CLI → ChatGPT OAuth → Your subscription
                                  ↓
                            $0 extra cost
```

---

## Setup Instructions

### 1. Run OAuth Setup

```bash
cd ~/Projects/agent-flywheel-cross-platform
./scripts/setup-codex-oauth.sh
```

### 2. Follow the Prompts

The script will:
- Check for existing API keys and offer to remove them
- Install Codex CLI (if not present)
- Open your browser for ChatGPT authentication
- Configure your environment

### 3. Test It Works

```bash
# Test Codex CLI
codex "Hello, are you working?"

# Start Agent Flywheel
./start
```

### 4. Verify No API Charges

- Check API usage: https://platform.openai.com/usage
  - Should show $0 usage
- Check ChatGPT: https://chatgpt.com/settings
  - Activity will show here instead

---

## Prerequisites

- **ChatGPT Plus or Pro subscription** ($20-200/month)
- **Multi-factor authentication enabled** (required by Codex)
- Node.js and npm (for Codex CLI installation)

---

## Troubleshooting

### "codex: command not found"

```bash
# Add npm global bin to PATH
export PATH="$HOME/.npm-global/bin:$PATH"

# Or install globally
npm install -g @openai/codex-cli
```

### Still seeing API charges?

```bash
# Check if API key is still set
env | grep OPENAI_API_KEY

# If found, remove it from your shell config
nano ~/.zshrc  # or ~/.bashrc

# Remove the line with OPENAI_API_KEY
# Then reload
source ~/.zshrc
```

### "Authentication failed"

```bash
# Make sure you have:
# 1. Active ChatGPT Plus/Pro subscription
# 2. Multi-factor authentication enabled

# Try logging in again
codex logout
codex login
```

### Codex works but agents don't use it

The agents should automatically use Codex CLI if it's installed. Check:

```bash
# Verify Codex is in PATH
which codex

# Check authentication
cat ~/.codex/auth.json
# Should exist and contain OAuth token (not API key)
```

---

## Testing This Feature Branch

### Test OAuth Setup

```bash
# Switch to feature branch
git checkout feature/chatgpt-subscription-support

# Run OAuth setup
./scripts/setup-codex-oauth.sh

# Verify authentication
codex "Test message"
```

### Test Agent Flywheel

```bash
# Start multi-agent session
./start

# Agents should use ChatGPT OAuth
# Check for no API charges at platform.openai.com/usage
```

---

## Migration Guide

### From API Key to ChatGPT OAuth

1. **Backup your current setup** (optional)
   ```bash
   cp ~/.zshrc ~/.zshrc.backup
   ```

2. **Run OAuth setup**
   ```bash
   ./scripts/setup-codex-oauth.sh
   ```

   It will automatically:
   - Detect existing API key
   - Offer to remove it
   - Set up OAuth instead

3. **Verify the switch**
   ```bash
   # API key should be gone
   echo $OPENAI_API_KEY  # Should be empty

   # OAuth should be configured
   cat ~/.codex/auth.json  # Should exist
   ```

4. **Monitor usage**
   - API usage should drop to $0: https://platform.openai.com/usage
   - ChatGPT activity shows instead: https://chatgpt.com/settings

---

## FAQ

**Q: Can I use both OAuth and API key?**
A: Not recommended. If both are configured, tools may use the API key and charge you.

**Q: What if I don't have ChatGPT Plus/Pro?**
A: You can still use API keys with the existing `setup-openai-key.sh` script. Consider upgrading to ChatGPT Pro ($200/month) to save money vs API usage ($600/month).

**Q: Does this work with ChatGPT Free?**
A: No, Codex CLI requires ChatGPT Plus or Pro subscription.

**Q: What happens if my subscription expires?**
A: Codex CLI will stop working. You'll need to renew your subscription or switch to API key billing.

**Q: Can I switch back to API keys later?**
A: Yes, just run `./scripts/setup-openai-key.sh`

---

## Support

- Installation issues: Run `./scripts/doctor.sh`
- OAuth issues: Check you have active ChatGPT Plus/Pro
- Cost questions: Compare at https://openai.com/pricing
- Feature issues: Open an issue on GitHub

---

## Next Steps After Merge

Once this feature is merged to main:

1. Update documentation site (if any)
2. Announce cost savings to users
3. Consider making OAuth the default choice
4. Add telemetry to track OAuth vs API key usage
5. Create video tutorial for setup

---

## Summary

✅ **New script**: `setup-codex-oauth.sh` for ChatGPT authentication
✅ **Updated installer**: Offers OAuth option during setup
✅ **Cost warnings**: API key setup warns about charges
✅ **Documentation**: README updated with cost comparison
✅ **Savings**: $400+/month by using ChatGPT subscription

**Recommended action**: Run `./scripts/setup-codex-oauth.sh` to start saving!
