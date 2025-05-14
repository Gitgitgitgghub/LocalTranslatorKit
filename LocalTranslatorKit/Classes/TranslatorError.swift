//
//  TranslatorError.swift
//  translator
//
//  Created by 吳俊諺 on 2025/5/7.
//


import Foundation
import MLKitTranslate

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

