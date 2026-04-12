# Abigail Flower

阿比盖尔之花是一个原生 macOS 桌面倒计时卡片 app。

## 它做什么
- 常驻桌面显示多个独立日期页的倒计时
- 每个倒计时都可以设置名字和目标日期
- 双击标题或日期牌即可轻量编辑当前倒计时页
- 每天稳定随机一句副标题
- 点摘录卡右侧的花朵，今天可以再抽一句
- 自动把默认配置和内容库复制到用户目录

## 目录
- `App/`：SwiftUI + AppKit 源码和资源
- `preview/`：不依赖 macOS 的网页模拟预览
- `scripts/build_app.sh`：在本地 Mac 上构建 `.app`
- `scripts/package_release.sh`：生成可分发 zip 包
- `.github/workflows/build-macos.yml`：在 GitHub Actions 的 macOS runner 上构建发布包
- `docs/distribution-and-updates.md`：私有仓库分发与更新建议

## 本地构建
```bash
bash scripts/build_app.sh
```

## 本地打包
```bash
bash scripts/package_release.sh
```

## 使用构建好的安装包
如果你已经拿到构建好的安装包，就不需要本地装 Swift 或从源码编译。

### 从 GitHub Actions 下载
1. 打开仓库的 `Actions`
2. 进入一次成功的 `build-macos-app`
3. 下载 artifact：`abigail-flower-mac-package`
4. 解压后会得到 `abigail-flower-mac-package.zip`

### 安装
1. 解压 `abigail-flower-mac-package.zip`
2. 进入解压后的目录
3. 双击 `INSTALL.command`
4. 如果 macOS 提示安全限制，右键 `INSTALL.command` 选择“打开”
5. 安装完成后，app 会出现在桌面上

### 安装后会发生什么
- app 会被复制到 `~/Applications/阿比盖尔之花.app`
- 自动启动配置会写到 `~/Library/LaunchAgents/com.abigailflower.card.plist`
- 默认配置和文案库会放到 `~/Library/Application Support/AbigailFlowerCard`

### 卸载
1. 打开安装包目录里的 `UNINSTALL.command`
2. 双击运行

它会删除：
- `~/Applications/阿比盖尔之花.app`
- `~/Library/LaunchAgents/com.abigailflower.card.plist`
- `~/Library/Application Support/AbigailFlowerCard`
