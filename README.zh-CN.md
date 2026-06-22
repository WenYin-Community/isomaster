[English](README.md) | 中文

# ISO Master

一款简单易用的开源图形化 CD 镜像编辑器，适用于 Linux 和 BSD。

## 功能

- 打开并浏览 ISO 9660 镜像（同时支持 NRG 和部分 MDF 文件）
- 向镜像中添加文件和目录
- 从镜像中提取文件和目录
- 从镜像中删除文件和目录
- 创建可引导 ISO 镜像
- 使用外部编辑器就地编辑镜像内的文件
- 保存为 ISO 格式
- 完整的国际化支持（gettext）
- 现代化 GTK4 + Adwaita 用户界面

## 截图

<p align="center">
  <img src="icons/isomaster.png" alt="ISO Master" width="640">
</p>

## 依赖

| 发行版 | 需要安装的包 |
|--------|-------------|
| Debian / Ubuntu | `build-essential valac libgtk-4-dev libadwaita-1-dev pkg-config gettext` |
| Fedora | `gcc make vala gtk4-devel libadwaita-devel pkgconfig gettext-devel` |
| Arch | `base-devel vala gtk4 libadwaita pkgconf gettext` |
| Slackware | 无需额外安装 |

## 编译

```bash
make -f Makefile.vala
```

### 编译选项

| 选项 | 说明 |
|------|------|
| `PREFIX=/path` | 安装前缀（默认 `/usr/local`） |

## 安装

```bash
sudo make -f Makefile.vala install
```

卸载：

```bash
sudo make -f Makefile.vala uninstall
```

也可以在编译目录直接运行 `./isomaster`（未安装时图标不可用）。

## 项目结构

```
isomaster/
├── isomaster.vala      # 主应用程序（Vala/GTK4/Adwaita）
├── isomaster.c         # Vala 生成的 C 代码
├── bk.vapi             # bk 库的 Vala 绑定
├── iniparser.vapi      # iniparser 库的 Vala 绑定
├── Makefile.vala       # Vala 版本构建系统
├── bk/                 # bkisofs 库（ISO 读写核心，纯 C）
│   ├── bkRead.c        #   ISO 9660/Joliet 目录结构读取
│   ├── bkWrite.c       #   ISO 镜像写入
│   ├── bkAdd.c         #   文件/目录添加
│   ├── bkDelete.c      #   文件/目录删除
│   ├── bkExtract.c     #   文件提取到本地
│   ├── bkPath.c        #   ISO 内部路径操作
│   ├── bkMangle.c      #   ISO 9660 文件名规范转换
│   ├── bkCache.c       #   块缓存
│   ├── example.c       #   独立使用示例
│   └── ...
├── iniparser-4.1/      # 内置 INI 文件解析库
├── po/                 # gettext 翻译文件（8 种语言）
└── icons/              # 应用图标
```

**架构说明：** `bk/` 目录下的库（`bk.a`）是一个独立的纯 C ISO 操作库，不依赖 GTK，可脱离 GUI 独立使用——详见 `bk/example.c`。

## 支持的语言

- 简体中文
- 繁體中文
- 日本語
- 한국어
- Français
- Deutsch
- Español
- Русский

## 参与贡献

欢迎提交 Bug 报告和补丁，请提供：

- 问题的复现步骤
- 终端输出（如有）
- 触发问题的镜像文件（如可公开获取）

## 许可证

GNU 通用公共许可证 v2。详见 [LICENCE.TXT](LICENCE.TXT)。

## 链接

- 主页：http://littlesvr.ca/isomaster/
- 联系方式：http://littlesvr.ca/contact.php
