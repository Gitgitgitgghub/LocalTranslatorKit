import Foundation
import SwiftUI
import LocalTranslatorKit
import MLKitTranslate

@MainActor
class TranslationViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var translatedText: String = ""
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    private let service: TranslatorServiceProtocol = TranslatorService()

    func translate(to target: TranslateLanguage = .english) {
        guard !inputText.isEmpty else {
            errorMessage = "請輸入要翻譯的文字"
            return
        }
        isLoading = true
        errorMessage = nil
        translatedText = ""

        Task {
            let result = await service.translateResult(inputText: inputText, to: target)
            isLoading = false

            switch result {
            case .success(let output):
                print("translate: \(output)")
                translatedText = output.translatedText

            case .failure(let error):
                switch error {
                case .modelNotDownloaded(let languages):
                    await handleMissingModelsAndRetry(languages: languages, target: target)
                default:
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleMissingModelsAndRetry(languages: [TranslateLanguage], target: TranslateLanguage) async {
        for lang in languages {
            print("translate 下載缺少模組: \(lang.rawValue)")
            await download(language: lang)
        }
        translate(to: target)
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
