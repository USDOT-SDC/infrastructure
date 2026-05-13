# Prompts

This directory contains prompts for larger and more complex work. This helps save on context window use.

## How to Use a Prompt

Reference a prompt file when starting a task in AI:

```
@Infrastructure/prompts/pr-create.md dev to main
```

AI will load the prompt as instructions and execute the steps within it.

## Prompts

### `pr-create.md` — Create a Pull Request

Creates a draft PR on github.com from a source branch to a target branch.

**Usage:**

```
@Infrastructure/prompts/pr-create.md {source} to {target}
```

Examples:

```
@Infrastructure/prompts/pr-create.md dev to main
```

If branches are omitted, the prompt will ask.

**What it does:**

1. Resolves assignee automatically from your git email and `team.json`
2. Asks who should review (reviewer-eligible members only)
3. Pulls the diff and commit history
4. Looks up Jira/JSM ticket context from branch names and commits
5. Writes a PR summary using `pull_request_template.md`
6. Creates the draft PR on github.com and adds reviewer and assignee

**Prerequisites:**

- `C:\ai-tools\external-resources.json` must contain valid tokens for `github.com` and `atlassian.secure-data-commons`
- Atlassian token can be regenerated at <https://id.atlassian.com/manage-profile/security/api-tokens>

## `team.json`

Maps team member first names to their email addresses and GitHub handles. Used by `pr-create.md` to resolve the assignee and reviewer without hardcoding.

```json
{
  "Name": {
    "email": "name@dot.gov",
    "github-handle": "handle",
    "reviewer": true
  }
}
```

Set `"reviewer": true` for members who can be selected as PR reviewers. Update this file when team membership changes.
