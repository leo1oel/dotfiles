# Dotfiles

个人 dotfiles 配置，基于 chezmoi 管理，支持 macOS 和 Ubuntu。

## 快速安装

### Ubuntu

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply leo1oel
```

**可选：配置 tokens 自动登录**

```bash
pass init "$(git config user.email)"
pass insert api-keys/huggingface
pass insert api-keys/wandb
chezmoi apply
gh auth login
```

### macOS

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply leo1oel
```

## 修改配置

### 方式一：使用 chezmoi edit（推荐）

```bash
chezmoi edit ~/.config/fish/config.fish
chezmoi edit ~/.gitconfig
chezmoi apply
```

### 方式二：直接编辑源文件

```bash
cd ~/.local/share/chezmoi
# 编辑文件
chezmoi apply
```

## 添加/删除包

### macOS

编辑 `~/.local/share/chezmoi/dot_config/Brewfile`，然后：

```bash
chezmoi apply
```

### Ubuntu

编辑 `~/.local/share/chezmoi/dot_config/packages.ubuntu`，然后：

```bash
chezmoi apply
```

## 推送到 GitHub

```bash
cd ~/.local/share/chezmoi
git add .
git commit -m "描述你的修改"
git push
```

## 在其他机器同步

```bash
cd ~/.local/share/chezmoi
git pull
chezmoi apply
```

## 常用命令

```bash
chezmoi diff          # 预览更改
chezmoi apply         # 应用配置
chezmoi update        # 拉取并应用最新配置
chezmoi edit <file>   # 编辑文件
```

## 主要工具

### 开发环境
- Python: `pyenv` + `uv`
- Node.js: `fnm`
- Go: `go`

### 终端工具
- Shell: Fish + Starship
- Terminal: Ghostty / Kitty / Zellij
- Editor: Neovim / Helix

### ML/AI 工具
- `gh` - GitHub CLI
- `huggingface-cli` - Hugging Face CLI
- `wandb` - Weights & Biases
- `ollama` - 本地 LLM

### 现代 CLI 工具
- `bat` - 替代 cat
- `eza` - 替代 ls
- `ripgrep` - 替代 grep
- `fd` - 替代 find
- `zoxide` - 智能 cd
- `lazygit` - Git TUI
