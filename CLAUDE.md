# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

ISO Master 是一个基于 GTK2 的图形化 CD 镜像编辑器，用于 Linux/BSD。支持打开 ISO/NRG/MDF 文件，可提取、添加文件，创建可引导 ISO。基于 bkisofs 库实现 ISO 读写。

许可证：GPLv2

## 构建命令

```bash
# 编译（依赖：gcc, make, gtk2-dev, pkg-config, gettext）
make

# 使用系统 iniparser（而非内置的 iniparser-4.1）
make USE_SYSTEM_INIPARSER=1

# 禁用国际化
make WITHOUT_NLS=1

# 安装/卸载（需要 root）
sudo make install
sudo make uninstall

# 清理
make clean
```

## 架构

### 顶层文件（GUI 层）

GTK2 应用程序，每个 `.c` 文件对应一个功能模块：

| 文件 | 职责 |
|------|------|
| `isomaster.c` | 入口，程序初始化 |
| `window.c` | 主窗口、菜单栏、工具栏构建 |
| `browser.c` | 文件浏览器公共逻辑（排序、图标加载） |
| `fsbrowser.c` | 左侧本地文件系统浏览器 |
| `isobrowser.c` | 右侧 ISO 镜像内容浏览器 |
| `isobrowser.c` | ISO 内文件的添加/删除/提取操作 |
| `settings.c` | 配置读写（使用 iniparser） |
| `boot.c` | 引导镜像设置对话框 |
| `editfile.c` | 从 ISO 中提取文件供外部编辑器修改 |
| `about.c` | 关于对话框 |
| `error.c` | 错误信息翻译层（将 bk 错误码转为可读字符串） |

### `bk/` — bkisofs 库（ISO 操作核心）

静态库 `bk.a`，与 GUI 完全解耦，可独立使用（见 `bk/example.c`）。

| 模块 | 职责 |
|------|------|
| `bkRead.c` / `bkRead7x.c` | ISO 9660/Joliet 目录结构读取 |
| `bkWrite.c` / `bkWrite7x.c` | ISO 镜像写入 |
| `bkAdd.c` | 向 ISO 添加文件/目录 |
| `bkDelete.c` | 从 ISO 删除文件/目录 |
| `bkExtract.c` | 从 ISO 提取文件到本地 |
| `bkPath.c` | ISO 内部路径操作 |
| `bkMangle.c` | ISO 9660 文件名规范转换 |
| `bkSort.c` | ISO 目录排序 |
| `bkCache.c` | 块缓存 |
| `bkLink.c` | ISO 文件链接处理 |
| `bkTime.c` | ISO 时间戳 |
| `bkError.c` | 错误码定义与字符串映射 |
| `bkGet.c` / `bkSet.c` | ISO 属性读写 |
| `bkMisc.c` | 杂项工具函数 |
| `bkIoWrappers.c` | I/O 抽象层 |

### `iniparser-4.1/` — INI 文件解析库

内置第三方库，用于 `settings.c` 读写配置文件。可用 `USE_SYSTEM_INIPARSER=1` 替换为系统版本。

### `po/` — 国际化

gettext 翻译文件。GUI 代码中使用 `_()` 宏包裹可翻译字符串（定义在 `isomaster.h`）。

## 关键类型

- `VolInfo` — ISO 卷信息核心结构（定义在 `bk/bk.h`）
- ISO 路径用 `Path` 结构表示（`bkPath.c` 操作）
- 错误码统一在 `bk/bkError.h` 定义，`error.c` 提供用户友好翻译

## 编码风格

- C99（`-std=gnu99`），GTK2 API
- 每个 `.c` 文件有对应的 `.h` 头文件
- bk 库不依赖 GTK，保持纯 C
- `_FILE_OFFSET_BITS=64` 支持大文件
- 国际化字符串用 `_()` 宏，非翻译字符串用 `N_()`
