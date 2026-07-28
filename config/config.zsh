source ~/.zsh/config/preferences/configure-zsh.zsh
source ~/.zsh/config/plugins/plugins.zsh
for theme_file in ~/.zsh/config/themes/**/*.zsh; do
  source $theme_file
done

source ~/.zsh/config/exports/exports.zsh
source ~/.zsh/config/exports/private-exports.zsh

source $ZSH/oh-my-zsh.sh
source $(brew --prefix nvm)/nvm.sh
