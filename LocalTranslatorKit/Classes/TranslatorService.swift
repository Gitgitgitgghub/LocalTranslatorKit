import Foundation
import MLKitTranslate
import MLKitLanguageID

/// 包含翻譯結果的資料結構
public struct TranslationResult {
    public let originalText: String
    public let detectedLanguage: String
    public let translatedText: String
}

/// 翻譯服務協定，提供將輸入文字翻譯成目標語言的方法
public protocol TranslatorServiceProtocol {
    /// 將輸入文字翻譯成指定語言
    /// - Parameters:
    ///   - inputText: 要翻譯的原始文字
    ///   - target: 目標語言
    /// - Returns: 翻譯結果，包括原文、偵測語言與翻譯後文字
    func translate(inputText: String, to target: TranslateLanguage) async throws -> TranslationResult
}

public extension TranslatorServiceProtocol {
    /// 提供 Result 形式的翻譯方法，方便呼叫端直接處理錯誤類型
    /// - Parameters:
    ///   - inputText: 要翻譯的文字
    ///   - target: 目標語言
    /// - Returns: 成功為翻譯結果，失敗為 TranslatorError
    func translateResult(inputText: String, to target: TranslateLanguage) async -> Result<TranslationResult, TranslatorError> {
        do {
            let result = try await translate(inputText: inputText, to: target)
            return .success(result)
        } catch let error as TranslatorError {
            return .failure(error)
        } catch {
            return .failure(.translationFailed(error))
        }
    }
    
    /// 提供非 async 的 callback 版本，內部仍使用 async 方法
        /// - Parameters:
        ///   - inputText: 要翻譯的文字
        ///   - target: 目標語言
        ///   - completion: 結果為成功或失敗，封裝為 Result
    func translateResult(inputText: String, to target: TranslateLanguage, completion: @escaping (Result<TranslationResult, TranslatorError>) -> Void) {
            Task {
                let result = await translateResult(inputText: inputText, to: target)
                completion(result)
            }
        }
}

/// 懶得再封裝一次直接typealias 指定
public typealias TranslateLanguage = MLKitTranslate.TranslateLanguage

extension TranslateLanguage {
    /// displayName 例如en會取得English
    public var displayName: String {
        return Locale.current.localizedString(forLanguageCode: self.rawValue) ?? ""
    }
}

/// 支持的語言
public enum LanguageSupportScope {
    case all
    case only(Set<TranslateLanguage>)
}

/// 實作 TranslatorServiceProtocol，提供實際翻譯邏輯
public class TranslatorService: TranslatorServiceProtocol {
    
    private init() {
        
    }
    
    public static let shared = TranslatorService()
    
    /// 支持的輸入語言
    public var inputLanguageSupport: LanguageSupportScope = .all
    
    /// 設定支持的輸入語言，.all就是輸入的所有語言都會響應下載模型and翻譯，也可以自行設定
    /// 舉例來說如果設定.only([.vietnamese, .japanese])，代表輸入的語言是越南文或者日文才會進行翻譯，其他一律不予理會
    /// - Parameter scope: LanguageSupportScope
    public func setInputLanguageSupportScope(scope: LanguageSupportScope) {
        inputLanguageSupport = scope
    }
    
    /// 取得翻譯支援的所有語言(MLKit Translator 支持的所有語言)
    /// - Returns: [TranslateLanguage]
    public func getTranslatorSupportLanguages() -> [TranslateLanguage] {
        let locale = Locale.current
        return TranslateLanguage.allLanguages().sorted {
          return locale.localizedString(forLanguageCode: $0.rawValue)!
            < locale.localizedString(forLanguageCode: $1.rawValue)!
        }
    }
    
    public func translate(inputText: String, to target: TranslateLanguage) async throws -> TranslationResult {
        let langCode = try await detectLanguage(for: inputText)
        guard langCode != "und" else {
            throw TranslatorError.undetectedLanguage
        }
        let sourceLang = TranslateLanguage(rawValue: langCode)
        if sourceLang == target {
            return TranslationResult(originalText: inputText, detectedLanguage: langCode, translatedText: inputText)
        }
        if !isSupportedLanguage(sourceLang) {
            throw TranslatorError.unsupportedLanguages(langurage: sourceLang)
        }
        let result = try await translate(text: inputText, from: sourceLang, to: target)
        return TranslationResult(originalText: inputText, detectedLanguage: langCode, translatedText: result)
    }

    /// 使用 ML Kit 偵測輸入文字的語言
    /// - Parameter text: 要偵測的文字
    /// - Returns: 語言代碼，例如 "en"、"zh"、"vi"
    private func detectLanguage(for text: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let languageId = LanguageIdentification.languageIdentification()
            languageId.identifyLanguage(for: text) { langCode, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: langCode ?? "und")
                }
            }
        }
    }
    
    /// 是否為支持的語言
    /// - Parameter language: 語言
    /// - Returns: 是否支持
    private func isSupportedLanguage(_ language: TranslateLanguage) -> Bool {
        switch inputLanguageSupport {
        case .all:
            return true
        case .only(let set):
            return set.contains(language)
        }
    }

    /// 準備 Translator 實例，若模型未下載則拋錯
    /// - Parameters:
    ///   - source: 原始語言
    ///   - target: 目標語言
    /// - Returns: Translator 實例
    private func prepareTranslator(from source: TranslateLanguage, to target: TranslateLanguage) async throws -> Translator {
        let sourceModel = TranslateRemoteModel.translateRemoteModel(language: source)
        let targetModel = TranslateRemoteModel.translateRemoteModel(language: target)
        var needDownloadLanguage: [TranslateLanguage] = []
        if !ModelManager.modelManager().isModelDownloaded(sourceModel) {
            needDownloadLanguage.append(source)
        }
        if !ModelManager.modelManager().isModelDownloaded(targetModel) {
            needDownloadLanguage.append(target)
        }
        if needDownloadLanguage.count > 0 {
            throw TranslatorError.modelNotDownloaded(languages: needDownloadLanguage)
        }
        let option = TranslatorOptions(sourceLanguage: source, targetLanguage: target)
        return Translator.translator(options: option)
    }

    /// 執行實際翻譯任務，包裝 MLKit 的非同步 callback 為 async throws
    /// - Parameters:
    ///   - text: 要翻譯的文字
    ///   - source: 原始語言
    ///   - target: 目標語言
    /// - Returns: 翻譯後文字
    private func translate(text: String, from source: TranslateLanguage, to target: TranslateLanguage) async throws -> String {
        var translator = try await prepareTranslator(from: source, to: target)
        return try await withCheckedThrowingContinuation { continuation in
            translator.translate(text) { result, error in
                if let error = error {
                    continuation.resume(throwing: TranslatorError.translationFailed(error))
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: TranslatorError.translationFailed(NSError(domain: "Unknown", code: -1)))
                }
            }
        }
    }
}
