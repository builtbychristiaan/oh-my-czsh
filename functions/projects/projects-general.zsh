# Define projects configuration
typeset -A PROJECTS

# Format for projects.config.zsh:
# PROJECTS[alias]="path|node:version(optional)|run_command1;run_command2;..."
typeset -g _CZSH_PROJECTS_CONFIG="$(dirname "$0")/projects.config.zsh"
source "$_CZSH_PROJECTS_CONFIG"

# Persist a project so nav/run (and a new shell) can find it.
# Usage: register_project <alias> <path> [run_command]
function register_project() {
  local project_alias="$1"
  local project_path="$2"
  local project_commands="${3:-npm run dev}"
  local config_file="${_CZSH_PROJECTS_CONFIG}"
  local entry

  if [[ -z "$project_alias" || -z "$project_path" ]]; then
    echo "${RED}Error:${NC} register_project requires an alias and a path."
    return 1
  fi
  if [[ "$project_alias" == *[!A-Za-z0-9_-]* ]]; then
    echo "${RED}Error:${NC} Project alias must be alphanumeric, underscore, or hyphen."
    return 1
  fi
  if [[ -z "$config_file" || ! -f "$config_file" ]]; then
    echo "${RED}Error:${NC} projects.config.zsh not found: ${config_file:-<unset>}"
    return 1
  fi
  if [[ -n "${PROJECTS[$project_alias]}" ]]; then
    echo "${YELLOW}Warning:${NC} Project alias '${project_alias}' is already registered; skipping config update."
    return 0
  fi
  if grep -Eq "^PROJECTS\[${project_alias}\]=" "$config_file"; then
    echo "${YELLOW}Warning:${NC} Project alias '${project_alias}' is already in ${config_file}; skipping."
    return 0
  fi

  entry="PROJECTS[${project_alias}]=\"${project_path}|${project_commands}\""
  if [[ -s "$config_file" && "$(tail -c 1 "$config_file")" != $'\n' ]]; then
    printf '\n' >> "$config_file"
  fi
  printf '%s\n' "$entry" >> "$config_file"
  PROJECTS[$project_alias]="${project_path}|${project_commands}"
  echo "${GREEN}✓ Registered ${project_alias} in ${config_file}${NC}"
}

function get_project_path() {
  local project_name="$1"
  echo "${PROJECTS[$project_name]%%|*}"
}

function get_project_node_version() {
  local project_name="$1"
  local without_path="${PROJECTS[$project_name]#*|}"
  if [[ $without_path == node:* ]]; then
    echo "${without_path%%|*}" | sed 's/node://'
    return 0
  fi
  return 1
}

function get_project_commands() {
  local project_name="$1"
  local without_path="${PROJECTS[$project_name]#*|}"
  if [[ $without_path == node:* ]]; then
    echo "${without_path#*|}"
  else
    echo "$without_path"
  fi
}
