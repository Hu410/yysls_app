# 构建指南

## 问题
`flutter build ios` 时 CocoaPods 无法从 `dl.google.com` 下载 Google ML Kit SDK。
原因：Clash Verge 的 TUN/fake-ip 模式导致 SSL 握手失败。

## 解决方法（任选其一）

### 方法一：临时关闭 Clash TUN 模式（推荐）
1. 打开 **Clash Verge** 应用
2. 关闭 **TUN 模式**（系统代理保持开启即可）
3. 在终端运行：
```bash
cd /Users/linchengbo/123/yysls_app
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
flutter build ios --no-codesign
```
4. 构建成功后可以恢复 TUN 模式

### 方法二：使用 ClashX 代替
1. 退出 Clash Verge
2. 打开 ClashX（它默认是系统代理模式，不启用 TUN）
3. 在终端设置代理后构建：
```bash
cd /Users/linchengbo/123/yysls_app
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
flutter build ios --no-codesign
```

### 方法三：手动下载 SDK 文件
在浏览器中逐个打开以下链接下载：
- https://dl.google.com/dl/cpdc/019adaeea9e4ebc0/GoogleMLKit-9.0.0.tar.gz
- https://dl.google.com/dl/cpdc/00f258dabdb58dfa/MLKitCommon-14.0.0.tar.gz
- https://dl.google.com/dl/cpdc/d19e9c059f422b0c/MLKitTextRecognition-7.0.0.tar.gz
- https://dl.google.com/dl/cpdc/ffd1e8a2dd89e128/MLKitTextRecognitionCommon-6.0.0.tar.gz
- https://dl.google.com/dl/cpdc/4e1652530984149e/MLKitVision-10.0.0.tar.gz
- https://dl.google.com/dl/cpdc/c33566c366901937/MLImage-1.0.0-beta6.tar.gz

下载后在终端运行：
```bash
cd /Users/linchengbo/123/yysls_app/ios
pod install --verbose
```
如果 pod install 提示需要其他 Google 包，再根据错误信息中的 URL 下载。
