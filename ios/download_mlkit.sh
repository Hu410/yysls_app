#!/bin/bash
# Google ML Kit iOS SDK 手动下载脚本
# 如果 dl.google.com 在终端中无法访问，请在浏览器中打开以下链接手动下载
# 然后将下载的文件放到 LocalPods 目录中

CACHE_DIR="$HOME/Library/Caches/CocoaPods/Pods/External"
mkdir -p "$CACHE_DIR"

URLS=(
  "https://dl.google.com/dl/cpdc/019adaeea9e4ebc0/GoogleMLKit-9.0.0.tar.gz"
  "https://dl.google.com/dl/cpdc/00f258dabdb58dfa/MLKitCommon-14.0.0.tar.gz"
  "https://dl.google.com/dl/cpdc/d19e9c059f422b0c/MLKitTextRecognition-7.0.0.tar.gz"
  "https://dl.google.com/dl/cpdc/ffd1e8a2dd89e128/MLKitTextRecognitionCommon-6.0.0.tar.gz"
  "https://dl.google.com/dl/cpdc/4e1652530984149e/MLKitVision-10.0.0.tar.gz"
  "https://dl.google.com/dl/cpdc/c33566c366901937/MLImage-1.0.0-beta6.tar.gz"
)

echo "===== Google ML Kit iOS SDK 下载 ====="
echo ""
echo "需要下载以下 6 个文件："
echo ""

for url in "${URLS[@]}"; do
  filename=$(basename "$url")
  echo "  $filename"
  echo "  URL: $url"
  echo ""
done

echo ""
echo "方法一：如果终端能用代理，设置代理后运行："
echo "  export https_proxy=http://127.0.0.1:7890"
echo "  export http_proxy=http://127.0.0.1:7890"
echo "  bash ios/download_mlkit.sh --download"
echo ""
echo "方法二：在浏览器中下载所有文件，然后放到："
echo "  ~/Library/Caches/CocoaPods/Pods/External/"
echo ""

if [ "$1" = "--download" ]; then
  echo "开始下载..."
  for url in "${URLS[@]}"; do
    filename=$(basename "$url")
    echo "下载: $filename"
    curl -L -o "$CACHE_DIR/$filename" "$url"
    if [ $? -eq 0 ]; then
      echo "  ✅ 成功"
    else
      echo "  ❌ 失败 - 请手动在浏览器下载: $url"
    fi
  done
  echo ""
  echo "下载完成后运行: cd ios && pod install"
fi
