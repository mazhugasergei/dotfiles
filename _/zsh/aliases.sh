alias whereami='curl http://ip-api.com/json'
alias ls='ls -Ap1'
alias mkcd='f() { mkdir -p "$1" && cd "$1"; }; f'
alias open='explorer.exe'
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dcdv='docker compose down --volumes'
alias dcud='docker compose up --detach'
alias dcub='docker compose up --build'
alias dcubd='docker compose up --build --detach'
alias npmise="npm install --save-exact"
alias python=python3

# pin npm dependencies to exact versions
npm-pin-deps() {
  node -e '
    const fs = require("fs");
    const pkg = JSON.parse(fs.readFileSync("package.json"));
    ["dependencies","devDependencies"].forEach(k=>{
      if(!pkg[k]) return;
      Object.keys(pkg[k]).forEach(p=>{
        pkg[k][p]=pkg[k][p].replace(/^[\^~]/,"")
      })
    });
    fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2));
  ' && npm install
}

# create next app
cna() {
  if [ -z "$1" ]; then
    echo "Error: Project name required"
    echo "Usage: cna <project-name>"
    return 1
  fi
  npx create-next-app "$1" --empty --ts --app --import-alias "@/*" --src-dir --tailwind --react-compiler --no-eslint --no-agents-md
}

# windsurf
if [[ -n "$WSL_DISTRO_NAME" ]]; then
  # WSL: define ws() to launch windsurf in VS Code Remote for the current WSL distro
  ws() {
    bash -c '
      distro="Debian"
      if [[ -n "$1" ]]; then
        if [[ ! -d "$1" ]]; then
          echo "Error: Directory \"$1\" does not exist"
          exit 1
        fi
        windsurf --folder-uri "vscode-remote://wsl+$distro$1"
      else
        windsurf
      fi
    ' _ "${1:+$(realpath "$1")}"
  }
else
  # native Linux: make simple alias
  alias ws='windsurf'
fi
