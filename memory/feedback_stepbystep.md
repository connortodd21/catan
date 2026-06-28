---
name: feedback-stepbystep
description: User prefers changes to be made one at a time, not batched together in a single edit.
metadata:
  type: feedback
---

Always make one change at a time when implementing tasks. Do not batch multiple edits into a single tool call unless they are truly trivially inseparable (e.g. a single line rename). Present each change, wait for approval, then proceed to the next.

**Why:** User explicitly asked for this multiple times. They want to review and approve each individual change before moving on.

**How to apply:** When a task involves multiple methods, variables, or files — propose and make one change at a time, then pause and wait.
