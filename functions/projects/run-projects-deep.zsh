function execute_project() {
  local project_alias="$1"
  local branch="$2"
  local project_path=$(get_project_path "$project_alias")
  local project_commands=$(get_project_commands "$project_alias")

  # Expand the path
  project_path="${project_path/#\~/$HOME}"

  local node_version
  if node_version=$(get_project_node_version "$project_alias"); then
    echo "${MAGENTA}Executing: ${MAGENTA_BOLD}nvm use $node_version${NC}"
    nvm use "$node_version"
  fi

  cd "$project_path" &&
    if [ -n "$branch" ]; then
      echo "${MAGENTA}Executing: ${MAGENTA_BOLD}co $branch${NC}" &&
        co "$branch"
    fi &&
    if [ "$project_alias" = "coeditor" ]; then
      echo "${MAGENTA}Executing: ${MAGENTA_BOLD}pnpm install${NC}" &&
        pnpm install
    else
      echo "${MAGENTA}Executing: ${MAGENTA_BOLD}yarn${NC}" &&
        yarn
    fi &&
    echo "${MAGENTA}Executing: ${MAGENTA_BOLD}$project_commands${NC}" &&
    eval "$project_commands"
}

function run-deep() {
  local branch=""
  local projects=()
  local i=1
  local pids=()
  local log_dir="/tmp/dev-projects"
  local use_subshells=false

  # Function to cleanup processes and files on exit
  function cleanup() {
    # Only show stopping message and cleanup pids if we're running multiple projects in subshells
    if [ ${#projects[@]} -gt 1 ] && $use_subshells; then
      echo "\n${BLUE_BOLD}Stopping all projects...${NC}"
      for pid in "${pids[@]}"; do
        kill $pid 2>/dev/null
      done
    fi

    # Clean up log files
    if [ -d "$log_dir" ]; then
      rm -rf "$log_dir"
    fi

    return
  }

  # Set up trap for Ctrl+C
  trap cleanup INT

  # Clean up log files
  if [ -d "$log_dir" ]; then
    rm -rf "$log_dir"
  fi

  # Parse all arguments
  while [ $i -le $# ]; do
    # Use eval to get the argument at position $i
    eval "current=\${$i}"

    if [ "$current" = "-b" ]; then
      # Check if next argument exists
      eval "next=\${$((i + 1)):-}"
      if [ -z "$next" ]; then
        echo "${RED}Error:${NC} No branch name provided after -b flag"
        return 1
      fi
      branch="$next"
      i=$((i + 2))
    elif [ "$current" = "-s" ] || [ "$current" = "--subshell" ]; then
      use_subshells=true
      i=$((i + 1))
    else
      projects+=("$current")
      i=$((i + 1))
    fi
  done

  # Check if any project aliases were provided
  if [ ${#projects[@]} -eq 0 ]; then
    echo "${RED}Error:${NC} No project aliases provided"
    return 1
  fi

  # Validate each project alias
  for project_alias in "${projects[@]}"; do
    if [ -z "${PROJECTS[$project_alias]}" ]; then
      echo "${RED}Error:${NC} Invalid project alias '${YELLOW}${project_alias}${NC}'"
      return 1
    fi
  done

  if [ -n "$branch" ]; then
    echo "${BLUE_BOLD}Running ${#projects[@]} project(s) on branch:${GREEN} $branch${NC}"
  else
    echo "${BLUE_BOLD}Running ${#projects[@]} project(s)${NC}"
  fi

  # Create a directory for logs
  mkdir -p "$log_dir"

  # If only one project, run directly in main shell
  if [ ${#projects[@]} -eq 1 ]; then
    execute_project "${projects[1]}" "$branch"
    return
  fi

  # Multiple projects - start each project based on mode
  if $use_subshells; then
    # Start projects in subshells
    for project_alias in "${projects[@]}"; do
      (execute_project "$project_alias" "$branch") >"$log_dir/$project_alias.log" 2>&1 &
      pids+=($!)
      echo "${GREEN}Started ${GREEN_BOLD}$project_alias${GREEN} in subshell (PID: $!)${NC}"
    done

    echo "\n${BLUE_BOLD}All projects started! Tailing logs...${NC}\n"

    # Use tail to follow all log files
    tail -f "$log_dir"/*.log | awk '
      /==> .*\.log <==/ {
        match($0, /[^\/]+\.log/)
        project=substr($0, RSTART, RLENGTH-4)
        printf "\n%s%s%s\n", "'"${BLUE_BOLD}"'", project, "'"${NC}"'"
        next
      }
      { print }
    '
  else
    # Start projects in new terminal windows
    for project_alias in "${projects[@]}"; do
      local project_path=$(get_project_path "$project_alias")
      project_path="${project_path/#\~/$HOME}"

      # Create a temporary script for this project
      local temp_script="$log_dir/$project_alias.command"
      echo "#!/bin/zsh" >"$temp_script"
      echo "cd \"$project_path\"" >>"$temp_script"
      echo "source ~/.zshrc" >>"$temp_script"
      echo "execute_project \"$project_alias\" \"$branch\"" >>"$temp_script"
      chmod +x "$temp_script"

      # Use preferred terminal or fall back to default Terminal.app
      open -a "${ZSH_PREFERENCES[preferred_terminal]:-Terminal}" "$temp_script"
      echo "${GREEN}Started ${GREEN_BOLD}$project_alias${GREEN} in new window${NC}"
    done
  fi
}
compdef _projects_autocompletion run-deep
