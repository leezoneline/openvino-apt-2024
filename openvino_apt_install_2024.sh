#!/usr/bin/env bash
# OpenVINO 2024 APT 安装脚本（Ubuntu）
# 用法：
#   bash openvino_apt_install_2024.sh            # 安装完整工具集 openvino
#   bash openvino_apt_install_2024.sh runtime    # 仅安装（同 openvino 元包）

set -euo pipefail

# 检测系统信息
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
fi
CODENAME=${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo "")}
VERSION_ID_MAJOR=${VERSION_ID%%.*}

if [[ -z "${VERSION_ID_MAJOR:-}" && -n "${CODENAME:-}" ]]; then
  case "$CODENAME" in
    noble) VERSION_ID_MAJOR=24 ;;
    jammy) VERSION_ID_MAJOR=22 ;;
    focal) VERSION_ID_MAJOR=20 ;;
    bionic) VERSION_ID_MAJOR=18 ;;
  esac
fi

if [[ -z "${VERSION_ID_MAJOR:-}" ]]; then
  echo "无法检测系统版本，请设置环境变量 VERSION_ID 或升级到受支持的 Ubuntu 版本 (20.04/22.04/24.04)。" >&2
  exit 1
fi

# 将系统版本映射为 OpenVINO 仓库中的发行名称（ubuntu24/22/20/18）
case "$VERSION_ID_MAJOR" in
  24) OV_REPO_DIST=ubuntu24 ;;
  22) OV_REPO_DIST=ubuntu22 ;;
  20) OV_REPO_DIST=ubuntu20 ;;
  18) OV_REPO_DIST=ubuntu18 ;;
  *) echo "不支持的 Ubuntu 版本: $VERSION_ID_MAJOR" >&2; exit 1 ;;
esac

echo "[INFO] Detected: Ubuntu $VERSION_ID (codename: ${CODENAME:-unknown}) => repo dist: $OV_REPO_DIST"

# 清理旧源（如有）
echo "[INFO] Cleaning old OpenVINO APT sources (if any) ..."
sudo rm -f /etc/apt/sources.list.d/intel-openvino*.list || true

## 导入 Intel GPG key（现代 keyring 方式，避免 apt-key 警告）
echo "[INFO] Importing Intel APT GPG key into keyring ..."
sudo install -d -m 0755 /usr/share/keyrings
TMP_KEY=$(mktemp)
trap 'rm -f "$TMP_KEY"' EXIT
curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
  | gpg --dearmor > "$TMP_KEY"
sudo install -m 0644 "$TMP_KEY" /usr/share/keyrings/intel-openvino-archive-keyring.gpg
if [[ -f /etc/apt/trusted.gpg ]]; then
  echo "[INFO] Note: If you previously used apt-key, you may see a legacy trusted.gpg warning once. It's safe to ignore after migrating."
fi

# 添加 2024 仓库（路径形如：.../openvino/2024 ubuntu22 main）
echo "[INFO] Adding OpenVINO 2024 APT repo (signed-by keyring) ..."
echo "deb [signed-by=/usr/share/keyrings/intel-openvino-archive-keyring.gpg] https://apt.repos.intel.com/openvino/2024 ${OV_REPO_DIST} main" \
  | sudo tee /etc/apt/sources.list.d/intel-openvino-2024.list >/dev/null

# 更新索引
echo "[INFO] Updating APT index ..."
sudo apt update

# 展示可用包
echo "[INFO] Available OpenVINO packages (top 200):"
apt-cache search ^openvino | sed -n '1,200p' || true

# 选择安装包
FLAVOR="${1:-full}"
if [[ "$FLAVOR" == "runtime" ]]; then
  echo "[INFO] 'runtime' 选项将安装 openvino 元包（APT 仓库无 openvino-runtime 单独包）。"
  PKG="openvino"
else
  PKG="openvino"
fi

echo "[INFO] Installing package: $PKG ..."
sudo apt install -y "$PKG"

# 配置环境变量（可选）
if [[ -f /opt/intel/openvino/setupvars.sh ]]; then
  if [[ "${OV_SETUP_PERSIST:-0}" == "1" ]]; then
    # 按需持久化写入（默认不写入，避免影响纯 C++/系统级使用）
    if ! grep -qs "source /opt/intel/openvino/setupvars.sh" "${HOME}/.zshrc"; then
      echo 'source /opt/intel/openvino/setupvars.sh' >> "${HOME}/.zshrc"
      echo "[INFO] Added setupvars.sh to ~/.zshrc (because OV_SETUP_PERSIST=1)"
    fi
  else
    echo "[INFO] Tip: 仅在需要时临时加载 OpenVINO 环境:"
    echo "       source /opt/intel/openvino/setupvars.sh"
    echo "       (如仅使用 C++/CLI，通常无需加载 Python 环境)"
  fi
fi

# 验证工具是否可用
if command -v benchmark_app >/dev/null 2>&1; then
  echo "[OK] benchmark_app available: $(command -v benchmark_app)"
else
  echo "[WARN] benchmark_app not found in PATH (可能只安装了运行时包)。"
fi

# 验证 Python 绑定（如系统 Python 有装）
python3 - <<'PY' || true
try:
    import openvino as ov
    print("[OK] OpenVINO Python version:", ov.runtime.get_version())
except Exception as e:
    print("[INFO] OpenVINO Python not available in system Python:", e)
    print("      如需 Python 绑定，可在虚拟环境内 pip install 'openvino>=2024.3,<2025'")
PY

echo "[DONE] OpenVINO 2024 APT 安装流程完成。建议执行 'exec zsh -l' 以重新加载环境。"
