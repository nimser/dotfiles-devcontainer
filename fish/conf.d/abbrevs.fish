# Override reboot
abbr --add reboot sudo shutdown -r now
abbr --add powerdown sudo shutdown now
# Development
abbr --add dob docker build
abbr --add dor docker run -dp 8080:80
abbr --add dop docker ps
abbr --add dok docker kill
abbr --add pn pnpm
abbr --add pni pnpm install
abbr --add pna pnpm add
abbr --add pnad "pnpm add --save-dev"
abbr --add pns pnpm run setup
abbr --add pnm pnpm run migrate
abbr --add pnd pnpm run dev
abbr --add pnl pnpm run lint
abbr --add pnf pnpm run fix
abbr --add pnt pnpm run test
abbr --add sanity pnpm sanity
abbr --add pcr --set-cursor "pnpm create vite % --template react"
abbr --add pcv --set-cursor "pnpm create vite %"
abbr --add vim nvim -p
abbr --add v nvim -p
# Distrobox
abbr --add dbxex --set-cursor "distrobox-export --bin /usr/sbin/% --export-path ~/.local/distrobox/bin"
# Git
abbr --add gsm git switch main
abbr --add gsd git switch dev
abbr --add gst git status
abbr --add ga --set-cursor "git add %;git status"
abbr --add gaa git "add -A;git status"
abbr --add gcl git clone
abbr --add gci --set-cursor "git commit -m '%'"
abbr --add gaci --set-cursor "git add -A;git commit -m '%'"
abbr --add gcia --set-cursor "git commit --amend -m '%'"
abbr --add gacia --set-cursor "git add -A;git commit --amend -m '%'"
abbr --add gciane git commit --amend --no-edit
abbr --add gaciane "git add -A;git commit --amend --no-edit"
abbr --add gpo git push origin
abbr --add gfo git fetch origin
abbr --add glg git lg
abbr --add gstash git stash
# pathspec used here. Usage info: https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-aiddefpathspecapathspec
abbr --add gdi --set-cursor "git diff -- % ':(exclude)pnpm-lock.yaml' ':(exclude)package-lock.json'"
abbr --add gco git checkout
abbr --add gsw git switch
abbr --add gsc --set-cursor "git switch -c '%'"
abbr --add gbr git branch
# github cli
abbr --add ghrc gh repo create
# RipGrep
abbr --add rg --set-cursor "rg --hidden --follow % --glob '!*{node_modules,dist,build}/**'"
abbr --add rgf --set-cursor "rg --hidden --follow --files-with-matches % --glob '!*{node_modules,dist,build}/**'"
abbr --add k kubectl
abbr --add kgp kubectl get pods
abbr --add kgs kubectl get services
abbr --add kga --set-cursor "kubectl get all --namespace=%"
abbr --add ksc --set-cursor "kubectl config set-context --current --namespace=%"
# Local shortcuts
abbr --add eabbr nvim -p ~/.config/fish/conf.d/abbrevs.fish

