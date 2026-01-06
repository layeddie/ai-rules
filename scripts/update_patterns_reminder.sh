#!/bin/bash
# Pattern Update Reminders for ai-rules

PATTERN_DIR="$HOME/projects/2026/ai-rules/patterns"
REMAINDER="$PATTERN_DIR/.update_reminder.md"

# Get last modified dates from git
GENSERVER=$(git -C "$PATTERN_DIR" log -1 --format=%ci -- genserver.md 2>/dev/null || echo "old")
LIVEVIEW=$(git -C "$PATTERN_DIR" log -1 --format=%ci -- liveview.md 2>/dev/null || echo "old")
ASH_RESOURCES=$(git -C "$PATTERN_DIR" log -1 --format=%ci -- ash_resources.md 2>/dev/null || echo "old")
OTP_SUPERVISOR=$(git -C "$PATTERN_DIR" log -1 --format=%ci -- otp_supervisor.md 2>/dev/null || echo "old")

# Calculate review dates (90 days ago)
REVIEW_DATE=$(date -v-90d +%Y-%m-%d)

# Check if any file needs review
if [[ "$GENSERVER" < "$REVIEW_DATE" ]] || [[ "$LIVEVIEW" < "$REVIEW_DATE" ]] || [[ "$ASH_RESOURCES" < "$REVIEW_DATE" ]] || [[ "$OTP_SUPERVISOR" < "$REVIEW_DATE" ]]; then
  echo "⚠️  Pattern Review Reminder"
  echo ""
  echo "The following pattern files haven't been updated in 90+ days:"
  [[ "$GENSERVER" < "$REVIEW_DATE" ]] && echo "  - genserver.md (last: $GENSERVER)"
  [[ "$LIVEVIEW" < "$REVIEW_DATE" ]] && echo "  - liveview.md (last: $LIVEVIEW)"
  [[ "$ASH_RESOURCES" < "$REVIEW_DATE" ]] && echo "  - ash_resources.md (last: $ASH_RESOURCES)"
  [[ "$OTP_SUPERVISOR" < "$REVIEW_DATE" ]] && echo "  - otp_supervisor.md (last: $OTP_SUPERVISOR)"
  echo ""
  echo "To review:"
  echo "  1. Check web for new patterns (elixir-lang.org/blog, elixirforum.com)"
  echo "  2. Use codesearch for latest community patterns"
  echo "  3. Add new patterns to relevant files"
  echo "  4. Update .update_reminder.md when done"
  echo ""
  echo "Example: codesearch 'Phoenix LiveView patterns 2025'"
else
  echo "✅ Patterns up to date (all reviewed within 90 days)"
fi

# Update sources
echo "Checked on: $(date '+%Y-%m-%d %H:%M:%S')"
