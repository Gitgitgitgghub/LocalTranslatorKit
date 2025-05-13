# 📦 LocalTranslatorKit

LocalTranslatorKit 是一個基於 [Google MLKit](https://developers.google.com/ml-kit) 的 Swift 封裝庫，支援：

- ✅ **文字語言自動辨識**
- ✅ **離線翻譯（自動下載模型）**
- ✅ **Swift Concurrency (async/await)**
- ✅ 完整支援 **SwiftUI / UIKit**

---

## 🔧 安裝方式

### 使用 CocoaPods：

```
pod 'LocalTranslatorKit', :git => 'https://github.com/Gitgitgitgghub/LocalTranslatorKit.git', :tag => '0.1.0'
```

📌 注意：MLKit 8.x 版本最低支援 `iOS 15.5`

---

## ✨ 功能特色

- 🔤 自動語言識別（使用 MLKit Language ID）
- 🌐 自動下載翻譯模型（使用 ModelDownloadManager）
- 🔁 支援非同步 callback 與 async/await 寫法
- 💥 明確錯誤類型：未識別語言、模型未下載、翻譯失敗

---

## 📘 使用範例

### SwiftUI + MVVM 範例：

- 請參考Example

---

## 📄 系統需求

- iOS 15.5+
- Swift 5.9+
- 使用 [GoogleMLKit/Translate](https://developers.google.com/ml-kit/language/translation/ios)
- 僅支援真機運行（模擬器不可使用）

---

## 🔍 授權 License

本專案使用 MIT 授權。
