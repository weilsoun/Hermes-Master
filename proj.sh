#!/usr/bin/env bash
# proj.sh -- Project management CLI for Factor1Digital Hermes environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="$SCRIPT_DIR/projects"

GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

py_yaml() {
    python3 - "$1" "$2" <<'PYEOF'
import yaml, sys
with open(sys.argv[1]) as f:
    d = yaml.safe_load(f)
result = d
for key in sys.argv[2].split('.'):
    result = result.get(key, '') if isinstance(result, dict) else ''
print(result if result is not None else '')
PYEOF
}

py_repos() {
    python3 - "$1" <<'PYEOF'
import yaml, sys
with open(sys.argv[1]) as f:
    d = yaml.safe_load(f)
for r in d.get('repos', []):
    name = r.get('name', '')
    url  = r.get('url', '')
    path = r.get('path', '/workspace/' + name)
    print(f'{name}|{url}|{path}')
PYEOF
}

py_repo_count() {
    python3 - "$1" <<'PYEOF'
import yaml, sys
with open(sys.argv[1]) as f:
    d = yaml.safe_load(f)
print(len(d.get('repos', [])))
PYEOF
}

py_set_status() {
    python3 - "$1" "$2" <<'PYEOF'
import re, sys
content = open(sys.argv[1]).read()
content = re.sub(r'(?m)^status:.*$', 'status: ' + sys.argv[2], content)
open(sys.argv[1], 'w').write(content)
print('Status set to ' + sys.argv[2])
PYEOF
}

cmd_list() {
    echo ""
    printf "${BOLD}%-36s %-12s %-10s %s${RESET}\n" "PROJECT NAME" "TYPE" "STATUS" "REPOS"
    echo "------------------------------------------------------------------------"
    for yaml_file in "$PROJECTS_DIR"/*.yaml; do
        [ -f "$yaml_file" ] || continue
        local name type status count
        name=$(py_yaml "$yaml_file" "name")
        type=$(py_yaml "$yaml_file" "type")
        status=$(py_yaml "$yaml_file" "status")
        count=$(py_repo_count "$yaml_file")
        if [ "$status" = "active" ]; then
            printf "${GREEN}%-36s %-12s %-10s %s${RESET}\n" "$name" "$type" "$status" "$count repos"
        else
            printf "${YELLOW}%-36s %-12s %-10s %s${RESET}\n" "$name" "$type" "$status" "$count repos"
        fi
    done
    echo ""
    echo "  Run '$(basename "$0") status' to see which repos are cloned."
    echo ""
}

cmd_status() {
    echo ""
    echo "${BOLD}Active Project Repo Status${RESET}"
    echo ""
    local found_active=0
    for yaml_file in "$PROJECTS_DIR"/*.yaml; do
        [ -f "$yaml_file" ] || continue
        local status
        status=$(py_yaml "$yaml_file" "status")
        [ "$status" = "active" ] || continue
        found_active=1
        local name
        name=$(py_yaml "$yaml_file" "name")
        echo "  ${CYAN}${BOLD}${name}${RESET}"
        while IFS='|' read -r repo_name repo_url repo_path; do
            [ -n "$repo_name" ] || continue
            if [ -d "$repo_path" ]; then
                printf "    ${GREEN}[+]${RESET}  %-44s %s\n" "$repo_name" "$repo_path"
            else
                printf "    ${RED}[x]${RESET}  %-44s ${RED}NOT CLONED${RESET}\n" "$repo_name"
            fi
        done < <(py_repos "$yaml_file")
        echo ""
    done
    if [ "$found_active" -eq 0 ]; then echo "  No active projects found."; fi
}

cmd_open() {
    local project="${1:-}"
    [ -n "$project" ] || { echo "Usage: $(basename "$0") open <project>"; exit 1; }
    project="${project%.yaml}"
    local yaml_file="$PROJECTS_DIR/${project}.yaml"
    [ -f "$yaml_file" ] || { echo "${RED}ERROR:${RESET} Not found: $yaml_file"; exit 1; }
    local name
    name=$(py_yaml "$yaml_file" "name")
    echo ""
    echo "Opening: ${BOLD}${name}${RESET}"
    py_set_status "$yaml_file" "active"
    _clone_repos "$yaml_file"
}

cmd_archive() {
    local project="${1:-}"
    [ -n "$project" ] || { echo "Usage: $(basename "$0") archive <project>"; exit 1; }
    project="${project%.yaml}"
    local yaml_file="$PROJECTS_DIR/${project}.yaml"
    [ -f "$yaml_file" ] || { echo "${RED}ERROR:${RESET} Not found: $yaml_file"; exit 1; }
    local name
    name=$(py_yaml "$yaml_file" "name")
    echo ""
    echo "${YELLOW}Archiving: ${BOLD}${name}${RESET}"
    echo ""
    local to_remove=()
    while IFS='|' read -r repo_name repo_url repo_path; do
        [ -n "$repo_name" ] || continue
        [ -d "$repo_path" ] && to_remove+=("$repo_path")
    done < <(py_repos "$yaml_file")
    if [ ${#to_remove[@]} -eq 0 ]; then
        echo "  No repos are cloned -- nothing to remove."
    else
        echo "  Directories to remove:"
        for dir in "${to_remove[@]}"; do
            echo "    ${RED}$dir${RESET}"
        done
        echo ""
        read -rp "  Confirm removal? [y/N] " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            for dir in "${to_remove[@]}"; do
                rm -rf "$dir"
                echo "  Removed: $dir"
            done
        else
            echo "  Aborted -- no directories removed."
            exit 0
        fi
    fi
    py_set_status "$yaml_file" "archived"
    echo ""
    echo "${YELLOW}Archived.${RESET} Re-activate with: $(basename "$0") open $project"
    echo ""
}

cmd_clone() {
    local project="${1:-}"
    [ -n "$project" ] || { echo "Usage: $(basename "$0") clone <project>"; exit 1; }
    project="${project%.yaml}"
    local yaml_file="$PROJECTS_DIR/${project}.yaml"
    [ -f "$yaml_file" ] || { echo "${RED}ERROR:${RESET} Not found: $yaml_file"; exit 1; }
    local name
    name=$(py_yaml "$yaml_file" "name")
    echo ""
    echo "Cloning repos for: ${BOLD}${name}${RESET}"
    _clone_repos "$yaml_file"
}

_clone_repos() {
    local yaml_file="$1"
    local cloned=0 skipped=0
    while IFS='|' read -r repo_name repo_url repo_path; do
        [ -n "$repo_name" ] || continue
        if [ -d "$repo_path" ]; then
            echo "  ${YELLOW}-> Already cloned:${RESET} $repo_name"
            ((skipped++)) || true
        else
            echo "  ${GREEN}>> Cloning:${RESET} $repo_url -> $repo_path"
            if gh repo clone "$repo_url" "$repo_path" 2>&1 | sed 's/^/     /'; then
                echo "     ${GREEN}Done.${RESET}"
                ((cloned++)) || true
            else
                echo "     ${RED}FAILED to clone $repo_url${RESET}"
            fi
        fi
    done < <(py_repos "$yaml_file")
    echo ""
    echo "  Summary: ${GREEN}${cloned} cloned${RESET}, ${YELLOW}${skipped} already present${RESET}"
    echo ""
}

cmd_new() {
    echo ""
    echo "${BOLD}Create a New Project${RESET}"
    echo ""
    read -rp "  Project name (human readable): " proj_name
    [ -n "$proj_name" ] || { echo "Name required."; exit 1; }
    read -rp "  File name (no .yaml, e.g., client-acme): " proj_file
    [ -n "$proj_file" ] || { echo "File name required."; exit 1; }
    proj_file="${proj_file%.yaml}"
    local yaml_file="$PROJECTS_DIR/${proj_file}.yaml"
    [ ! -f "$yaml_file" ] || { echo "${RED}ERROR:${RESET} $yaml_file already exists."; exit 1; }
    echo "  Type: (1) internal  (2) client  (3) personal"
    read -rp "  Choose [1-3]: " type_choice
    case "$type_choice" in
        1) proj_type="internal" ;;
        2) proj_type="client" ;;
        3) proj_type="personal" ;;
        *) proj_type="client" ;;
    esac
    local client_line=""
    if [ "$proj_type" = "client" ]; then
        read -rp "  Client name: " client_name
        client_line="client: $client_name"
    fi
    read -rp "  Description: " proj_desc
    read -rp "  Owner [Mike Wilson]: " proj_owner
    proj_owner="${proj_owner:-Mike Wilson}"
    read -rp "  Notes (optional): " proj_notes
    local repos_yaml=""
    echo ""
    echo "  Add repos (blank name to finish):"
    while true; do
        read -rp "    Repo name: " r_name
        [ -n "$r_name" ] || break
        read -rp "    GitHub URL (weilsoun/my-repo): " r_url
        read -rp "    Description: " r_desc
        repos_yaml="${repos_yaml}
  - name: ${r_name}
    url: ${r_url}
    description: ${r_desc}
    path: /workspace/${r_name}"
    done
    {
        echo "name: $proj_name"
        echo "status: active"
        echo "type: $proj_type"
        [ -n "$client_line" ] && echo "$client_line"
        echo "description: $proj_desc"
        echo "owner: $proj_owner"
        echo "repos:${repos_yaml}"
        [ -n "$proj_notes" ] && echo "notes: '$proj_notes'"
    } > "$yaml_file"
    echo ""
    echo "${GREEN}Created:${RESET} $yaml_file"
    if [ -n "$repos_yaml" ]; then
        read -rp "  Clone repos now? [y/N] " do_clone
        [[ "$do_clone" =~ ^[Yy]$ ]] && _clone_repos "$yaml_file"
    fi
    echo "Done. Use '$(basename "$0") status' to check."
    echo ""
}

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
    list)    cmd_list ;;
    status)  cmd_status ;;
    open)    cmd_open "$@" ;;
    archive) cmd_archive "$@" ;;
    clone)   cmd_clone "$@" ;;
    new)     cmd_new ;;
    help|--help|-h)
        echo ""
        echo "  ${BOLD}proj.sh${RESET} -- Factor1Digital project manager"
        echo ""
        echo "  Commands:"
        echo "    list              List all projects"
        echo "    status            Show cloned/missing repos for active projects"
        echo "    open <project>    Activate project and clone its repos"
        echo "    archive <project> Archive project and remove its repos"
        echo "    clone <project>   Clone repos without changing status"
        echo "    new               Create a new project interactively"
        echo ""
        echo "  <project> = YAML filename without .yaml (e.g., internal, client-healthcare)"
        echo ""
        ;;
    *)
        echo "${RED}Unknown command:${RESET} $COMMAND"
        echo "Run '$(basename "$0") help' for usage."
        exit 1
        ;;
esac
