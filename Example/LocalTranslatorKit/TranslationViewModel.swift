import Foundation
import SwiftUI
import LocalTranslatorKit
import MLKitTranslate

@MainActor
class TranslationViewModel: ObservableObject {
    @Published var inputText: String = "サポートされていない言語"
    @Published var translatedText: String = ""
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var selectedLanguage: TranslateLanguage = .english
    let availableLanguages: [TranslateLanguage] = [
            .english, .chinese, .thai, .vietnamese, .indonesian
        ]

    private let service: TranslatorService = TranslatorService.shared

    func translate() {
        service.setInputLanguageSupportScope(scope: .only([.chinese, .english, .japanese]))
        guard !inputText.isEmpty else {
            errorMessage = "請輸入要翻譯的文字"
            return
        }
        isLoading = true
        errorMessage = nil
        translatedText = ""

        Task {
            let result = await service.translateResult(inputText: inputText, to: selectedLanguage)
            isLoading = false

            switch result {
            case .success(let output):
                print("translate success: \(output)")
                translatedText = output.translatedText
            case .failure(let error):
                print("translate failure: \(error.localizedDescription)")
                switch error {
                case .modelNotDownloaded(let languages):
                    await handleMissingModelsAndRetry(languages: languages)
                default:
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleMissingModelsAndRetry(languages: [TranslateLanguage]) async {
        for lang in languages {
            print("translate 下載缺少模組: \(lang.rawValue)")
            await download(language: lang)
        }
        translate()
    }

    private func download(language: TranslateLanguage) async {
        await withCheckedContinuation { continuation in
            Task {
                await ModelDownloadManager.shared.startDownload(language: language) { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        Task { @MainActor in
                            self.errorMessage = "模型下載失敗（\(language.rawValue)）：\(error.localizedDescription)"
                            self.isLoading = false
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }
} 
