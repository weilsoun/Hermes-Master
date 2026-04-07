# Project Management System

This folder contains YAML project definitions for Factor1Digital's Hermes Docker environment.

## How It Works

Each `.yaml` file in `projects/` defines one project -- its repos, status, team, and metadata.

- **Active projects** have their repos cloned into `/workspace/` so you can work on them.
- **Archived projects** have their repos removed from `/workspace/` to save disk space.
  They can be re-activated at any time using `proj.sh open`.
- The YAML files themselves are always tracked in git, even when repos are archived.

## Project File Format

```yaml
name: My Project
status: active          # active | archived
type: client            # client | internal | personal
client: Client Name     # optional, for client projects
description: What this project is
owner: Mike Wilson
repos:
  - name: my-repo
    url: weilsoun/my-repo
    description: What this repo does
    path: /workspace/my-repo
notes: Any extra notes
```

## Managing Projects with proj.sh

The CLI lives at `/workspace/Hermes-Master/proj.sh`. Run it from anywhere.

```
proj.sh list                    # List all projects with status and repo count
proj.sh status                  # Show which repos are cloned vs missing (active only)
proj.sh open <project-name>     # Activate a project and clone its repos
proj.sh archive <project-name>  # Archive a project and remove its repos
proj.sh clone <project-name>    # Clone repos without changing status
proj.sh new                     # Interactive: create a new project YAML
```

Where `<project-name>` is the filename without `.yaml` (e.g., `internal`, `client-healthcare`).

## Current Projects

| File                     | Description                          | Status   |
|--------------------------|--------------------------------------|----------|
| internal.yaml            | Factor1Digital Internal Tools        | active   |
| personal.yaml            | Personal Projects                    | active   |
| client-healthcare.yaml   | Healthcare Client Projects           | active   |
| client-campaigns.yaml    | Campaign Projects (completed)        | archived |

## Notes

- Repo paths in the YAML are always `/workspace/<repo-name>`
- `gh` (GitHub CLI) is used for cloning -- authentication is handled automatically
- New project YAMLs created by `proj.sh new` follow the same format
