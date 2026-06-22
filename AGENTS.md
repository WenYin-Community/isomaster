# AGENTS.md

## 项目概述

ISO Master 是基于 GTK2 的图形化 CD 镜像编辑器（Linux/BSD），支持 ISO/NRG/MDF 文件。核心 ISO 操作由 `bk/` 库实现，与 GUI 完全解耦。

## 构建命令

```bash
# 基本构建（依赖：gcc, make, gtk2-dev, pkg-config, gettext）
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

## 架构要点

### 双层架构
- **GUI 层**（顶层 `.c` 文件）：GTK2 应用程序，每个文件对应一个功能模块
- **核心库**（`bk/` 目录）：纯 C 的 ISO 操作库，不依赖 GTK，可独立使用

### 关键文件
- `isomaster.c` → 入口点
- `window.c` → 主窗口、菜单栏、工具栏
- `fsbrowser.c` → 本地文件系统浏览器（左面板）
- `isobrowser.c` → ISO 镜像浏览器（右面板，最大最复杂的文件）
- `settings.c` → 配置读写（使用 iniparser）
- `bk/bk.h` → 核心类型定义（`VolInfo` 等）

### 依赖关系
```
isomaster.c → window.c, fsbrowser.c, isobrowser.c, settings.c, boot.c, editfile.c
fsbrowser.c, isobrowser.c → browser.c（共享逻辑）
isobrowser.c, boot.c, editfile.c → bk/（ISO 操作）
settings.c → iniparser-4.1/（或系统 iniparser）
```

## 编码风格

- C99（`-std=gnu99`），GTK2 API
- 每个 `.c` 文件有对应的 `.h` 头文件
- `_FILE_OFFSET_BITS=64` 支持大文件
- 国际化字符串用 `_()` 宏（定义在 `isomaster.h`）
- bk 库保持纯 C，不依赖 GTK

## 重要约束

1. **GTK2 限制**：当前使用 GTK2，不支持 Wayland。有详细的 GTK4 迁移计划（`docs/gtk4-wayland-migration-plan.md`）
2. **无测试套件**：项目没有自动化测试，验证依赖手工操作
3. **同步对话框**：大量使用 `gtk_dialog_run()`（GTK4 中已移除）
4. **全局变量**：GUI 层大量使用全局 `GtkWidget*` 变量

## 开发提示

- 修改 GUI 代码时注意 GTK2 API 限制
- 修改 bk/ 库时保持纯 C，不引入 GTK 依赖
- 国际化字符串必须用 `_()` 包裹
- 构建时注意 `USE_SYSTEM_INIPARSER` 和 `WITHOUT_NLS` 选项
- 查看 `bk/example.c` 了解 bk 库的独立使用方式

## Git 分支

- `main` → 当前稳定版本（GTK2）
- `gtk4` → GTK4 迁移开发分支（如需迁移请先阅读 `docs/gtk4-wayland-migration-plan.md`）

## 相关文档

- `CLAUDE.md` → 详细项目文档
- `README.md` → 用户指南和依赖说明
- `docs/gtk4-wayland-migration-plan.md` → GTK4 迁移计划（如需迁移请先阅读）