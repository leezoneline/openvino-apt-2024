# OpenVINO 2024 APT Installer (Ubuntu)

一键脚本，帮你在 Ubuntu 20.04/22.04/24.04 上通过 APT 仓库安装 OpenVINO 2024。

## 使用

```bash
# 克隆本仓库
# git clone https://github.com/<yourname>/openvino-apt-2024.git
# cd openvino-apt-2024

# 安装完整工具集
bash openvino_apt_install_2024.sh

# 或“仅运行时”别名（APT 仓库无 openvino-runtime 独立包，会安装 openvino 元包）
bash openvino_apt_install_2024.sh runtime

# 安装完成后让环境变量生效
exec zsh -l

# 验证
benchmark_app -h | head
python3 -c 'import openvino as ov; print(ov.runtime.get_version())'
```

## 特性
- 自动识别 Ubuntu 版本并映射到正确的仓库代号（ubuntu20/22/24）
- 使用现代 keyring（signed-by）方式配置 Intel GPG 密钥与 APT 源
- 幂等：重复执行不会出错
- 自动写入 `~/.zshrc` 以加载 `/opt/intel/openvino/setupvars.sh`

## 支持矩阵
- Ubuntu 20.04 (Focal) / 22.04 (Jammy) / 24.04 (Noble)
- OpenVINO 2024.x（当前仓库默认安装最新，如 2024.6）

## 故障排查
- 若之前使用 apt-key 配置过旧源，首次 `apt update` 可能提示 legacy trusted.gpg，可忽略或手动清理。
- 国内网络建议提前配置 Ubuntu 镜像站以提速，Intel 仓库仍需访问 `https://apt.repos.intel.com/`。

## 许可证
- MIT
