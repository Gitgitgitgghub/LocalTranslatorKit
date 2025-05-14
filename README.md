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
pod 'LocalTranslatorKit', :git => 'https://github.com/Gitgitgitgghub/LocalTranslatorKit.git', :tag => '1.0.1'
```

📌 注意：MLKit 8.x 版本最低支援 `iOS 15.5`

---

## ✨ 功能特色

- 🔤 自動語言識別（使用 MLKit Language ID）
- 🌐 自動下載翻譯模型（使用 ModelDownloadManager）
- 🔁 支援非同步 callback 與 async/await 寫法
- 💥 明確錯誤類型：未識別語言、模型未下載、翻譯失敗

---

## 📘 主要方法

### ModelDownloadManager(主要用來下載模型或管理模型)：

```
    /// 查詢目前已下載的語言模型
    public func listDownloadedModels() -> [String] 

    /// 查詢某語言是否正在下載中
    public func isDownloading(language: TranslateLanguage) -> Bool 
    
    /// 刪除模型
    public func deleteModel(language: TranslateLanguage, completion: @escaping (Error?) -> Void) 
    
    /// 啟動下載模型（若尚未下載）
    public func startDownload(
        language: TranslateLanguage,
        completion: @escaping (Result<Void, Error>) -> Void
    )
```

### TranslatorService(翻譯語言主要類別)：

```
    /// 設定支持的輸入語言，.all就是輸入的所有語言都會響應下載模型and翻譯，也可以自行設定
    /// 舉例來說如果設定.only([.vietnamese, .japanese])，代表輸入的語言是"越南文"或者"日文"才會進行翻譯，其他一律不予理會
    /// - Parameter scope: LanguageSupportScope
    public func setInputLanguageSupportScope(scope: LanguageSupportScope)
    
    /// 取得翻譯支援的所有語言(MLKit Translator 支持的所有語言)
    /// - Returns: [TranslateLanguage]
    public func getTranslatorSupportLanguages() -> [TranslateLanguage]
    
    /// 將輸入文字翻譯成指定語言
    /// - Parameters:
    ///   - inputText: 要翻譯的原始文字
    ///   - target: 目標語言
    /// - Returns: 翻譯結果，包括原文、偵測語言與翻譯後文字
    func translate(inputText: String, to target: TranslateLanguage) async throws -> TranslationResult
    
    /// 提供 Result 形式的翻譯方法，方便呼叫端直接處理錯誤類型
    /// - Parameters:
    ///   - inputText: 要翻譯的文字
    ///   - target: 目標語言
    /// - Returns: 成功為翻譯結果，失敗為 TranslatorError
    func translateResult(inputText: String, to target: TranslateLanguage) async -> Result<TranslationResult, TranslatorError>
    
    /// 提供非 async 的 callback 版本，內部仍使用 async 方法
    /// - Parameters:
    ///   - inputText: 要翻譯的文字
    ///   - target: 目標語言
    ///   - completion: 結果為成功或失敗，封裝為 Result
    func translateResult(inputText: String, to target: TranslateLanguage, completion: @escaping (Result<TranslationResult, TranslatorError>) -> Void)
```

### TranslatorError(錯誤類型)：
```
public enum TranslatorError: Error, LocalizedError {
    case undetectedLanguage
    case modelNotDownloaded(languages: [TranslateLanguage])
    case translationFailed(Error)
    case unsupportedLanguages(langurage: TranslateLanguage)

    public var errorDescription: String? {
        switch self {
        case .undetectedLanguage:
            return "無法識別語言"
        case .modelNotDownloaded(let languages):
            let names = languages.map { $0.rawValue }.joined(separator: ", ")
            return "缺少語言模型：\(names)"
        case .translationFailed(let error):
            return "翻譯失敗：\(error.localizedDescription)"
        case .unsupportedLanguages(langurage: let langurage):
            return "\(langurage) 為非支持的語言"
        }
    }
}
```

### 具體使用方式可以參考Example

---

## 📄 系統需求

- iOS 15.5+
- Swift 5.9+
- 使用 [GoogleMLKit/Translate](https://developers.google.com/ml-kit/language/translation/ios)
- 僅支援真機運行（模擬器不可使用）

---

## 🔍 授權 License

本專案使用 MIT 授權。
