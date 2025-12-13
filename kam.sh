#!/bin/bash
#
# Kam Interactive Usage Guide / Kam 使用向导
#
# This script is a small interactive helper that checks for the
# presence of 'kam' and, if missing, tries to guide users to
# install 'cargo' and 'kam'. It can also help install GH and 'cz'
# (Commitizen), and optionally cross-compile tools (cross / cargo-ndk).
#
# 此脚本为交互式向导，检测是否存在 `kam`，若不存在会引导安装 `cargo` 并通过 cargo 安装 `kam`。
# 也会帮助安装 `gh`（GitHub CLI）与 `cz`（Commitizen），并可选安装交叉编译工具（cross 或 cargo-ndk）。
#
# NOTE: This script attempts best-effort installs (will run apt/brew/npm/pip/cargo where possible).
#       Please run it interactively and review actions before consenting to install.
#
# 注意：脚本会尽最大努力尝试安装（会使用 apt / brew / npm / pip / cargo）。请在交互环境运行并在允许前确认命令。
#

set -eu

# Print both English and Chinese messages
echo_both() {
    printf "\n[EN] %s\n" "$1"
    printf "[CN] %s\n\n" "$2"
}

# Prompt yes/no with default Y or N
confirm() {
    local msg_en="$1"
    local msg_cn="$2"
    local default="$3" # Y or N
    local ans
    while :; do
        read -r -p "[EN] $msg_en [$default] / [CN] $msg_cn [$default] : " ans
        ans="${ans:-$default}"
        case "$ans" in
            [yY][eE][sS]|[yY]) return 0 ;;
            [nN][oO]|[nN]) return 1 ;;
            *) echo "Please answer y or n / 请输入 y 或 n" ;;
        esac
    done
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_pkg_mgr() {
    if command_exists apt-get; then
        echo "apt-get"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists apk; then
        echo "apk"
    elif command_exists brew; then
        echo "brew"
    elif command_exists choco; then
        echo "choco"
    else
        echo "unknown"
    fi
}

# Install rustup (cargo / rustc)
install_rustup() {
    echo_both "Installing rustup (Rust & Cargo)..." "正在安装 rustup（Rust 与 Cargo）..."
    if command_exists curl; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    elif command_exists wget; then
        wget -qO- https://sh.rustup.rs | sh -s -- -y
    else
        echo_both "Error: no curl or wget found for rustup install" "错误：未检测到 curl 或 wget，无法安装 rustup"
        return 1
    fi
    # Load cargo environment
    # shellcheck disable=SC1090
    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.cargo/env"
    fi
    echo_both "Rust / Cargo installed (or rustup installer was started)." "Rust / Cargo 已安装（或 rustup 安装器已启动）。"
}

# Install kam via cargo
install_kam() {
    echo_both "Installing kam (via cargo install)..." "安装 kam（通过 cargo install）..."
    if ! command_exists cargo; then
        echo_both "cargo not found; cannot install kam." "未检测到 cargo；无法安装 kam。"
        return 1
    fi
    if confirm "Install kam from crates.io using 'cargo install kam'?" "是否通过 'cargo install kam' 从 crates.io 安装 kam？" "Y"; then
        if cargo install kam; then
            echo_both "kam installation succeeded." "kam 安装成功。"
        else
            echo_both "`cargo install kam` failed. You can run 'cargo install --path . --locked' from the repo root to use a local build." "执行 'cargo install kam' 失败。你可以在仓库根目录使用 'cargo install --path . --locked' 来安装本地版本。"
            return 1
        fi
    else
        echo_both "Skipping kam installation." "跳过 kam 安装。"
    fi
}

# Install GitHub CLI (gh)
install_gh() {
    if command_exists gh; then
        echo_both "gh (GitHub CLI) is already installed." "gh（GitHub CLI）已存在。"
        return 0
    fi
    local pm
    pm="$(detect_pkg_mgr)"
    echo_both "Attempting to install gh using detected package manager: $pm" "尝试使用检测到的包管理器安装 gh：$pm"
    case "$pm" in
        apt-get)
            echo_both "Installing gh on Debian/Ubuntu" "在 Debian/Ubuntu 上安装 gh"
            if confirm "Run: 'sudo apt update && sudo apt install -y gh' ?" "运行：'sudo apt update && sudo apt install -y gh' ?" "Y"; then
                sudo apt update && sudo apt install -y gh
            fi
            ;;
        brew)
            echo_both "Installing gh using Homebrew" "使用 Homebrew 安装 gh"
            if confirm "Run: 'brew install gh' ?" "运行：'brew install gh' ?" "Y"; then
                brew install gh
            fi
            ;;
        yum|dnf)
            echo_both "Try using the official GitHub CLI install script or install via package manager" "尝试使用官方安装脚本或通过包管理器安装"
            if confirm "Run the official install script? (curl -fsSL https://cli.github.com/install.sh | sudo bash)" "运行官方安装脚本? (curl -fsSL https://cli.github.com/install.sh | sudo bash)" "Y"; then
                curl -fsSL https://cli.github.com/install.sh | sudo bash
            fi
            ;;
        apk)
            echo_both "Try using apk to install 'gh' if available" "尝试使用 apk 安装 'gh'（若可用）"
            if confirm "Run: 'sudo apk add gh' ?" "运行：'sudo apk add gh' ?" "Y"; then
                sudo apk add gh
            fi
            ;;
        *)
            echo_both "No supported package manager detected; attempt to use the install script." "未检测到受支持的包管理器；尝试使用官方安装脚本。"
            if confirm "Run the official install script? (curl -fsSL https://cli.github.com/install.sh | sudo bash)" "运行官方安装脚本? (curl -fsSL https://cli.github.com/install.sh | sudo bash)" "Y"; then
                curl -fsSL https://cli.github.com/install.sh | sudo bash
            fi
            ;;
    esac
}

# Install commitizen (cz) - via pip or npm/yarn
install_cz() {
    if command_exists cz; then
        echo_both "cz (commitizen) is already installed." "cz（commitizen）已存在。"
        return 0
    fi
    if command_exists pip; then
        echo_both "Installing commitizen using pip" "使用 pip 安装 commitizen"
        if confirm "Run: 'pip install --user commitizen' ?" "运行：'pip install --user commitizen' ?" "Y"; then
            pip install --user commitizen
        fi
    elif command_exists npm; then
        echo_both "Installing commitizen using npm" "使用 npm 安装 commitizen"
        if confirm "Run: 'npm install -g commitizen' ?" "运行：'npm install -g commitizen' ?" "Y"; then
            npm install -g commitizen
        fi
    elif command_exists yarn; then
        echo_both "Installing commitizen using yarn" "使用 yarn 安装 commitizen"
        if confirm "Run: 'yarn global add commitizen' ?" "运行：'yarn global add commitizen' ?" "Y"; then
            yarn global add commitizen
        fi
    else
        echo_both "No pip/npm/yarn found to install commitizen. Please install one of them, then run 'pip install --user commitizen' or 'npm i -g commitizen'." "未检测到 pip/npm/yarn，无法安装 commitizen。请先安装其中之一，然后运行 'pip install --user commitizen' 或 'npm i -g commitizen'。"
    fi
}

# Optional: cross compilation helper
install_cross_tools() {
    echo_both "Cross-compilation tools (cross and cargo-ndk) let you build for other targets." "交叉编译工具（cross 与 cargo-ndk）可用于构建其他目标。"
    if confirm "Install cross, cargo-ndk, both, or none? (y=cross|n=none|b=both)" "要安装 cross、cargo-ndk、两者还是都不安装? (y=cross|n=none|b=both)" "N"; then
        read -r -p "[EN] Choose: cross (c), cargo-ndk (n), both (b): / [CN] 选择: cross (c), cargo-ndk (n), 都安装 (b): " cho
        cho="${cho:-c}"
        case "$cho" in
            c|C)
                if command_exists cross; then
                    echo_both "cross already installed" "cross 已安装"
                else
                    echo_both "Installing cross via cargo" "通过 cargo 安装 cross"
                    cargo install cross || echo_both "Failed to install cross" "安装 cross 失败"
                fi
                ;;
            n|N)
                if command_exists cargo-ndk; then
                    echo_both "cargo-ndk already installed" "cargo-ndk 已安装"
                else
                    echo_both "Installing cargo-ndk via cargo" "通过 cargo 安装 cargo-ndk"
                    cargo install cargo-ndk || echo_both "Failed to install cargo-ndk" "安装 cargo-ndk 失败"
                fi
                ;;
            b|B)
                if ! command_exists cross; then
                    cargo install cross || echo_both "Failed to install cross" "安装 cross 失败"
                fi
                if ! command_exists cargo-ndk; then
                    cargo install cargo-ndk || echo_both "Failed to install cargo-ndk" "安装 cargo-ndk 失败"
                fi
                ;;
            *)
                echo_both "Invalid choice, skipping cross tool install." "选择无效，跳过交叉编译工具安装。"
                ;;
        esac
    fi
}

# Main flow
echo_both "Kam Interactive Setup / Kam 使用向导" "Kam 交互式使用向导"
echo_both "This script will check for and optionally install: kam, cargo (rusttoolchain), gh, and cz." "该脚本将检测并可选安装：kam、cargo（Rust 工具链）、gh 与 cz（Commitizen）。"

# 1) Check for kam
if command_exists kam; then
    echo_both "kam is installed: $(kam --version 2>/dev/null | head -n1 || true)" "检测到 kam 已安装: $(kam --version 2>/dev/null | head -n1 || true)"
else
    echo_both "kam is not installed." "未检测到 kam"
    if command_exists cargo; then
        echo_both "Found cargo, proceeding with 'cargo install kam'." "检测到 cargo，准备运行 'cargo install kam' 安装 kam。"
        if confirm "Run 'cargo install kam' now?" "现在运行 'cargo install kam' 吗？" "Y"; then
            install_kam || echo_both "kam installation via cargo failed." "使用 cargo 安装 kam 失败。"
        else
            echo_both "Skipping kam installation." "跳过 kam 安装。"
        fi
    else
        echo_both "cargo is not found; check if we should install rustup (which includes cargo)" "未检测到 cargo；是否安装 rustup（其中包含 cargo）？"
        if confirm "Install rustup (recommended)?" "是否安装 rustup（推荐）？" "Y"; then
            install_rustup || echo_both "Failed to install rustup. Please install cargo/rust manually." "安装 rustup 失败，请手动安装 cargo / rust。"
            if command_exists cargo && confirm "Now run 'cargo install kam' to install kam?" "现在运行 'cargo install kam' 安装 kam 吗？" "Y"; then
                install_kam || echo_both "kam installation via cargo failed." "使用 cargo 安装 kam 失败。"
            fi
        else
            echo_both "Skipping rustup/cargo installation step." "跳过 rustup / cargo 安装。"
        fi
    fi
fi

# 2) GH (GitHub CLI)
if command_exists gh; then
    echo_both "gh is already installed: $(gh --version | head -n1 2>/dev/null || true)" "gh 已安装: $(gh --version | head -n1 2>/dev/null || true)"
else
    if confirm "Install GitHub CLI (gh)?" "安装 GitHub CLI (gh) 吗？" "Y"; then
        install_gh || echo_both "Failed to install gh automatically. Please install it manually." "自动安装 gh 失败，请手动安装。"
    fi
fi

# 3) cz (Commitizen)
if command_exists cz; then
    echo_both "cz is already installed: $(cz --version 2>/dev/null || true)" "cz 已安装: $(cz --version 2>/dev/null || true)"
else
    if confirm "Install commitizen (cz) globally (pip/npm/yarn)?" "是否安装 commitizen (cz)（通过 pip/npm/yarn 等）？" "Y"; then
        install_cz
    fi
fi

# Optional cross compile tooling
if confirm "Would you like to install cross-compilation support (cross / cargo-ndk)?" "是否需要安装交叉编译支持 (cross / cargo-ndk)？" "N"; then
    install_cross_tools
fi

echo_both "All done. You can now run 'kam --help' for usage or run 'kam build' to build your module." "完成。现在可以运行 'kam --help' 查看用法或运行 'kam build' 来构建你的模块。"

# End
exit 0
