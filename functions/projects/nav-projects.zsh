function nav() {
  local project_alias="$1"
  local project_path

  if [[ -z "$project_alias" ]]; then
    echo "${RED}Error:${NC} No project alias provided"
    return 1
  fi

  if [[ -z "${PROJECTS[$project_alias]}" ]]; then
    echo "${RED}Error:${NC} Invalid project alias '${YELLOW}${project_alias}${NC}'"
    return 1
  fi

  project_path=$(get_project_path "$project_alias")
  project_path="${project_path/#\~/$HOME}"

  cd "$project_path"
}
compdef _projects_autocompletion nav
