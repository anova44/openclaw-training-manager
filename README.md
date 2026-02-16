# 🧠 Training Manager

**Set up, train, and maintain your OpenClaw agent's workspace — through conversation, not configuration files.**

An OpenClaw skill that guides new users through interactive onboarding and helps power users keep their workspace healthy over time.

---

## What It Does

### For New Users: Interactive Setup

When you first install OpenClaw, you're staring at an empty workspace with no idea what files to create or what to put in them. Training Manager fixes that with an **8-question conversational setup** that builds a fully personalized workspace:

```
Agent: What's your name?
You:   Alex

Agent: How should I talk to you? Like a coworker, a friend, or more formally?
You:   Like a friend

→ SOUL.md gets: "Casual and conversational / Use humor when it fits / Skip formalities"
```

Every answer gets **translated into proper agent instructions** — no placeholders, no raw quotes dumped into config files. You get a working agent in ~2 minutes.

### For Everyone: Ongoing Training & Maintenance

As you use your agent, corrections and preferences get **categorized and logged automatically**:

- Behavioral rules → `AGENTS.md`
- Personality traits → `SOUL.md`  
- Preferences → `USER.md`
- Facts → `MEMORY.md` or daily logs

**Workspace health tools** help you avoid common maintenance debt:

- **Validate** — catch broken frontmatter, missing files, char limit violations
- **Analyze** — proactive recommendations (consolidate Training Updates, split large files, review memory sprawl)
- **Status** — dashboard of file sizes, skill count, modification dates
- **Export** — timestamped backup tarballs
- **Consolidate** — merge accumulated training corrections into main document structure

---

## Commands

| Command | What It Does | When To Use |
|---------|-------------|-------------|
| **setup** | Interactive onboarding flow — builds workspace from conversation | First run, or fresh start |
| **scaffold** | Drop raw template files (power user fallback) | When you want to customize from scratch |
| **log** | Log a training correction to the right file | When you say "remember this" or correct the agent |
| **consolidate** | Extract Training Update sections into staging for review | When updates pile up (5+ sections) |
| **validate** | Check workspace for errors and warnings | Before deploying, or periodic health checks |
| **analyze** | Proactive maintenance recommendations | Weekly/bi-weekly, or after validate/status |
| **status** | Dashboard of workspace state | Quick snapshot of what's going on |
| **export** | Backup workspace to tarball | Before big changes |
| **generate-skill** | Create a new skill from description | When you want a simple skill template |

---

## Install

### From ClaWHub (recommended)
```bash
npm i -g clawhub  # if not already installed
clawhub install training-manager
```

### Manual Install
Copy the `training-manager/` folder into your workspace `skills/` directory:
```bash
cp -r training-manager ~/.openclaw/workspace/skills/
```

---

## Usage

Invoke `/training-manager` — the skill will:
- **Auto-detect** if your workspace is empty and start interactive setup
- Otherwise, ask what you need and run the appropriate command

### Custom Workspace Path
Scripts default to `~/.openclaw/workspace/`. If your workspace is elsewhere:
```bash
export OPENCLAW_WORKSPACE=~/my-workspace
```

---

## Interactive Setup Output

After the 8-question conversation, you'll have:

| File | Contents |
|------|----------|
| `IDENTITY.md` | Agent's name and role |
| `USER.md` | Your name, timezone, communication preferences |
| `SOUL.md` | Communication style, tone, boundaries — **translated** from your answers |
| `AGENTS.md` | Priorities and behavioral rules based on your use cases |
| `TOOLS.md` | Tool conventions relevant to your integrations |
| `MEMORY.md` | Long-term memory (starts with your first logged context) |
| `memory/` | Daily log directory |

**Example translations:**
- You say: "like a friend" → SOUL.md gets structured personality rules
- You say: "coding and DevOps" → AGENTS.md gets prioritized task categories
- You say: "push back when I'm wrong" → SOUL.md gets boundary guidance

No placeholders. No `(set your name here)`. Real, working config from day one.

---

## Workspace Health: Analyze Command

**New in v1.1:** Proactive maintenance analysis that tells you what to do next.

```bash
bash scripts/analyze.sh          # standard checks
bash scripts/analyze.sh --deep   # includes cross-file duplicate detection
```

**What it checks:**
1. **Training Update accumulation** — 5+ sections = suggest consolidate, 10+ = urgent
2. **File size creep** — warns at 75% of 20K char limit, urgent at 90%
3. **Memory sprawl** — 30+ daily logs without recent MEMORY.md updates
4. **Stale files** — workspace files unmodified for 90+ days
5. **Placeholder text** — detects scaffold templates still in files
6. **Skill health** — skills missing metadata or approaching char limits
7. **Duplicate rules** (--deep) — exact matches across AGENTS.md and SOUL.md

**Output format:**
```
=== Recommendations ===
  [HIGH] AGENTS.md: 17,200 chars (86% of 20K limit) — near limit, split or trim
  [HIGH] AGENTS.md: 12 Training Update sections — run consolidate
  [MED]  USER.md: 2 placeholder(s) still present — customize it
  [LOW]  42 daily logs, MEMORY.md last modified 21 days ago — review and merge

=== Summary ===
  High priority: 2
  Medium priority: 1  
  Low priority: 1

  Suggested: run '/training-manager consolidate' to clean up Training Update buildup.
```

**When to run:** Weekly during low-traffic times, after validate/status, or when you notice sluggish performance.

---

## Security

### Content Security (v1.1+)

Scripts that write to workspace files (`log-training.sh`, `generate-skill.sh`) include **prompt injection filtering**:

- Blocks shell metacharacters (backticks, `$()`)
- Validates category/filename allowlists
- Prevents path traversal
- Screens for instruction override attempts

The skill also includes behavioral guidance to **translate, not transcribe** — the agent rephrases your corrections into clean directives rather than copying raw input verbatim into system prompt files.

### Hardening Features

- Input validation on all user-provided fields
- Character allowlists for bins/env requirements
- `printf` used throughout (no echo flag injection)
- Read-only validation and analysis (exit 0 always)
- Workspace path validation

---

## Examples

### First-Time Setup
```
You: /training-manager

Agent: Looks like you haven't set up yet. Let's do that now — I'll ask
       a few questions and build your workspace from your answers.

       What's your name?

You: Jordan

Agent: What timezone are you in?

You: EST

Agent: What should I call myself?

You: Bolt

[... 5 more questions ...]

Agent: Here's what I set up:

       IDENTITY.md -- I'm "Bolt", your AI assistant
       USER.md     -- You're Jordan, EST timezone  
       SOUL.md     -- Direct, friendly, will push back when needed
       AGENTS.md   -- Priorities: coding > DevOps > writing
       TOOLS.md    -- GitHub, Docker, Slack integration noted
       MEMORY.md   -- Empty, ready to learn

       Want me to adjust anything?
```

### Logging a Correction
```
You: Next time, don't explain so much unless I ask. Just give me the answer.

Agent: [runs log-training.sh "soul" "Lead with answer, explain only when prompted"]

       Logged to SOUL.md under Communication style.
```

### Weekly Maintenance
```
You: /training-manager analyze

Agent: [runs analyze.sh]

       === Recommendations ===
         [HIGH] AGENTS.md: 18,400 chars (92% of limit) — near truncation
         [MED]  SOUL.md: 7 Training Update sections — consider consolidating
         [LOW]  TOOLS.md: not modified in 120 days — still accurate?

       Suggested: run consolidate on AGENTS.md and SOUL.md, then trim or
       split AGENTS.md to get under the 20K limit.
```

---

## Requirements

- **Bash** (scripts require bash shell)
- **OpenClaw** (any recent version)
- **OS:** Linux or macOS (scripts use `stat`, `grep`, `find`, `awk`)

---

## Contributing

Found a bug? Have a suggestion? Open an issue or PR at:  
**https://github.com/anova44/openclaw-training-manager**

---

## License

MIT — use it, fork it, improve it.

---

## Version History

**v1.1.0** (2026-02-15)
- Added `analyze` command for proactive workspace maintenance
- Content security: prompt injection filtering in log-training and generate-skill
- Behavioral guidance: translate user input, don't transcribe verbatim
- Improved placeholder detection (regex-based, not hardcoded strings)
- Cross-file duplicate detection (opt-in with `--deep` flag)
- Shell injection hardening (input validation, character allowlists, printf-only output)

**v1.0.0** (2026-02-15)
- Interactive setup flow (8-question onboarding)
- Core commands: scaffold, log, consolidate, validate, status, export, generate-skill
- Auto-detection for fresh workspaces
- Translation tables for common user responses → agent instructions
- Cross-platform compatibility (Linux + macOS)
