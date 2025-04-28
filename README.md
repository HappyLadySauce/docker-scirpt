# Docker 镜像批量管理脚本

本项目包含两个用于批量管理 Docker 镜像与容器归档的自动化脚本，分别适用于 Linux/macOS（`docker.sh`）和 Windows（`docker.ps1`）。它们支持镜像的导入、导出、拉取、推送、删除、重命名等常见批量操作，极大提升运维和迁移效率。

---

## 脚本简介

- **docker.sh**：Bash 脚本，适用于 Linux/macOS 环境。
- **docker.ps1**：PowerShell 脚本，适用于 Windows 环境。

两者功能基本一致，参数和用法保持统一。

---

## 主要功能

- **批量导出镜像**（`--save`）：将本地镜像导出为 `.tar.gz` 文件，便于备份或迁移。
- **批量导入镜像**（`--load`）：从归档文件批量导入镜像到本地 Docker。
- **批量拉取镜像**（`--pull`）：从远程仓库批量拉取镜像。
- **批量推送镜像**（`--push`）：将本地镜像批量推送到指定仓库。
- **批量删除镜像**（`--delete`）：批量删除本地镜像。
- **批量导出容器文件系统**（`--export`）：将运行中的容器文件系统导出为归档。
- **批量导入容器归档为镜像**（`--import`）：将归档文件导入为新的镜像。
- **批量重命名镜像**（`--strip-registry`）：去除镜像仓库前缀，或重命名为新前缀。
- **支持镜像列表文件**：可通过文本文件批量指定镜像或容器。

---

## 使用方法

### 1. 基本用法

#### Linux/macOS（Bash）
```bash
./docker.sh [操作选项] [参数]
```

#### Windows（PowerShell）
```powershell
.\docker.ps1 [操作选项] [参数]
```

### 2. 常用参数说明

| 参数 | 说明 |
|------|------|
| `-i, --image-list <文件>` | 指定镜像/容器列表文件（每行一个，支持注释） |
| `-n, --image-name <名称>` | 指定单个镜像名称（优先级高于列表） |
| `-d, --images-dir <目录>` | 指定导入/导出镜像的目录 |
| `--load` | 批量导入镜像归档 |
| `--save` | 批量导出镜像归档 |
| `--import` | 批量导入容器归档为镜像 |
| `--export` | 批量导出容器文件系统 |
| `--delete` | 批量删除镜像 |
| `--pull` | 批量拉取镜像 |
| `--push` | 批量推送镜像 |
| `-r, --registry <地址>` | 指定目标仓库地址（推送时必需） |
| `-s, --source-registry <地址>` | 指定源仓库地址（拉取/导出时可用） |
| `-p, --project <名称>` | 指定项目名称（推送时可用） |
| `--target-registry <前缀>` | 指定目标仓库前缀（重命名/推送时可用） |
| `--strip-registry <前缀>` | 去除镜像仓库前缀或重命名镜像 |
| `--explain` | 显示 Docker 命令说明 |
| `-h, --help` | 显示帮助信息 |

---

### 3. 典型操作示例

- **导出镜像到本地目录**
  ```bash
  ./docker.sh --save -n nginx:latest -d ./images
  # 或
  .\docker.ps1 --save -n nginx:latest -d ./images
  ```

- **从本地归档导入镜像**
  ```bash
  ./docker.sh --load -n nginx:latest -d ./images
  # 或
  .\docker.ps1 --load -n nginx:latest -d ./images
  ```

- **批量拉取镜像**
  ```bash
  ./docker.sh --pull -i rancher-images.txt -s registry.cn-hangzhou.aliyuncs.com
  # 或
  .\docker.ps1 --pull -i rancher-images.txt -s registry.cn-hangzhou.aliyuncs.com
  ```

- **批量推送镜像到私有仓库**
  ```bash
  ./docker.sh --push -i rancher-images.txt -r registry.example.com --target-registry library
  # 或
  .\docker.ps1 --push -i rancher-images.txt -r registry.example.com --target-registry library
  ```

- **批量删除镜像**
  ```bash
  ./docker.sh --delete -i rancher-images.txt
  # 或
  .\docker.ps1 --delete -i rancher-images.txt
  ```

- **批量重命名镜像（去除仓库前缀）**
  ```bash
  ./docker.sh --strip-registry registry.cn-hangzhou.aliyuncs.com -i rancher-images.txt
  # 或
  .\docker.ps1 --strip-registry registry.cn-hangzhou.aliyuncs.com -i rancher-images.txt
  ```

---

## 镜像/容器列表文件格式

- 每行一个镜像名或容器ID（可带标签），如：
  ```
  nginx:latest
  registry.cn-hangzhou.aliyuncs.com/rancher/calico-cni:v3.27.4-rancher1
  # 这是注释
  ```
- 支持空行和注释（以 `#` 开头）。

---

## 注意事项

- 操作前请确保 Docker 服务已启动且可用。
- 批量操作前建议先备份重要镜像。
- 推送/拉取私有仓库时，需提前 `docker login`。
- Windows 用户请使用 PowerShell 7+ 运行 `docker.ps1`。

---

## 贡献与反馈

如有建议、问题或需求，欢迎通过 [GitHub Issues](https://github.com/HappyLadySauce) 反馈。

如需详细命令说明，可执行：
```bash
./docker.sh --explain
# 或
.\docker.ps1 --explain
```

---

本脚本适合 DevOps、运维、离线迁移、批量镜像管理等场景，极大提升 Docker 镜像批量处理效率。

如果需要进一步定制或有特殊场景需求，欢迎联系作者！