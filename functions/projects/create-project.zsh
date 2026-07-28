# Bootstrap a new project from the Angular + Express starter.
# Clones the starter, re-inits git as a fresh repo (no link to the original),
# installs dependencies, then runs the interactive setup wizard.
#
# Usage:
#   create-project [project-name] [target-parent-dir]
#
# Examples:
#   create-project my-app
#   create-project my-app ~/projects

function init-project() {
  local starter_repo="${STARTER_REPO:-https://github.com/builtbychristiaan/angular-express-starter.git}"
  local starter_branch="${STARTER_BRANCH:-main}"
  local project_name="${1:-}"
  local target_parent="${2:-$(pwd)}"
  local project_dir

  if ! command -v git >/dev/null 2>&1; then
    echo "${RED}Error:${NC} 'git' is required but not installed."
    return 1
  fi
  if ! command -v npm >/dev/null 2>&1; then
    echo "${RED}Error:${NC} 'npm' is required but not installed."
    return 1
  fi
  if ! command -v node >/dev/null 2>&1; then
    echo "${RED}Error:${NC} 'node' is required but not installed."
    return 1
  fi

  if [[ -z "$project_name" ]]; then
    echo -n "Project directory name: "
    read -r project_name
  fi

  if [[ -z "$project_name" ]]; then
    echo "${RED}Error:${NC} Project name is required."
    return 1
  fi
  if [[ "$project_name" == *"/"* ]]; then
    echo "${RED}Error:${NC} Project name must be a single directory name (no slashes)."
    return 1
  fi

  target_parent="${target_parent:A}"
  project_dir="${target_parent}/${project_name}"

  if [[ -e "$project_dir" ]]; then
    echo "${RED}Error:${NC} Target already exists: $project_dir"
    return 1
  fi

  echo "${BLUE}→ Cloning starter into ${project_dir}${NC}"
  if ! git clone --depth 1 --branch "$starter_branch" "$starter_repo" "$project_dir"; then
    echo "${RED}Error:${NC} Failed to clone starter repo."
    return 1
  fi

  echo "${BLUE}→ Detaching from starter history (fresh git repo)${NC}"
  rm -rf "${project_dir}/.git"
  git -C "$project_dir" init -b main
  git -C "$project_dir" add -A
  git -C "$project_dir" \
    -c user.email="${GIT_AUTHOR_EMAIL:-dev@localhost}" \
    -c user.name="${GIT_AUTHOR_NAME:-Developer}" \
    commit -m "Initial commit from angular-express-starter"

  echo "${BLUE}→ Installing npm dependencies${NC}"
  if ! (cd "$project_dir" && npm install); then
    echo "${RED}Error:${NC} npm install failed."
    return 1
  fi

  echo "${BLUE}→ Running setup wizard (npm run setup)${NC}"
  if ! (cd "$project_dir" && npm run setup); then
    echo "${RED}Error:${NC} setup wizard failed."
    return 1
  fi

  echo ""
  echo "${GREEN}✓ Project ready at ${project_dir}${NC}"
  echo ""
  echo "Next steps:"
  echo "  cd ${project_dir}"
  echo "  docker compose up -d db"
  echo "  npm run db:migrate -w server"
  echo "  npm run db:seed -w server -- --confirm"
  echo "  npm run dev"
  echo ""
}
