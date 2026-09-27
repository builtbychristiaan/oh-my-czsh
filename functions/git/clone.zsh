# Clone a repo into ~/docs/projects/personal, register it, and cd into it.
#
# Usage:
#   clone <git-url>
#
# Example:
#   clone https://github.com/user/repo.git

function clone() {
  local url="${1:-}"
  local dest="/Users/christiaan/docs/projects/personal"
  local repo_name
  local repo_dir
  local project_alias

  if ! command -v git >/dev/null 2>&1; then
    echo "${RED}Error:${NC} 'git' is required but not installed."
    return 1
  fi

  if [[ -z "$url" ]]; then
    echo "${RED}Error:${NC} Usage: clone <git-url>"
    return 1
  fi

  if [[ ! -d "$dest" ]]; then
    echo "${RED}Error:${NC} Personal projects folder not found: $dest"
    return 1
  fi

  repo_name="${${url%%\?*}##*/}"
  repo_name="${repo_name%.git}"
  repo_name="${repo_name%/}"

  if [[ -z "$repo_name" || "$repo_name" == *"/"* ]]; then
    echo "${RED}Error:${NC} Could not determine a directory name from: $url"
    return 1
  fi

  repo_dir="${dest}/${repo_name}"

  if [[ -e "$repo_dir" ]]; then
    echo "${RED}Error:${NC} Target already exists: $repo_dir"
    return 1
  fi

  echo "${BLUE}→ Cloning into ${repo_dir}${NC}"
  if ! git -C "$dest" clone "$url"; then
    echo "${RED}Error:${NC} Failed to clone."
    return 1
  fi

  cd "$repo_dir" || return 1

  project_alias="${repo_name:l}"
  project_alias="${project_alias//[^A-Za-z0-9_-]/-}"
  while [[ "$project_alias" == *--* ]]; do
    project_alias="${project_alias//--/-}"
  done
  project_alias="${project_alias#-}"
  project_alias="${project_alias%-}"

  echo "${BLUE}→ Registering project for nav/run${NC}"
  if ! register_project "$project_alias" "$repo_dir" "echo 'no run command set up yet'"; then
    echo "${YELLOW}Warning:${NC} Repo was cloned but was not added to projects.config.zsh."
  fi

  echo "${GREEN}✓ Cloned to ${repo_dir}${NC}"
}
