# Abigail Flower

阿比盖尔之花是一个原生 macOS 桌面倒计时卡片 app。

## 它做什么
- 常驻桌面显示距离 8 月 31 日还有多少天
- 每天稳定随机一句副标题
- 点花朵按钮，今天可以再抽一句
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
