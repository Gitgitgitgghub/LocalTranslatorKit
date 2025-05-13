import Foundation
import MLKitTranslate

/// 管理翻譯模型下載
public actor ModelDownloadManager {
    public static let shared = ModelDownloadManager()
    private let manager = ModelManager.modelManager()
    // 正在下載中的語言集合
    private var downloadingLanguages: Set<TranslateLanguage> = []
    // 為每個語言保留所有的完成回調列表（可能多次請求同一語言）
    private var completionHandlers: [TranslateLanguage: [(_ result: Result<Void, Error>) -> Void]] = [:]
    
    private init() {
        NotificationCenter.default.addObserver(
            forName: .mlkitModelDownloadDidSucceed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let userInfo = notification.userInfo,
                let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? TranslateRemoteModel
            else { return }
            let language = model.language
            Task { await self?.handleDownloadSuccess(language: language) }
        }

        NotificationCenter.default.addObserver(
            forName: .mlkitModelDownloadDidFail,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let userInfo = notification.userInfo,
                let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? TranslateRemoteModel,
                let error = userInfo[ModelDownloadUserInfoKey.error.rawValue] as? Error
            else { return }
            let language = model.language
            Task { await self?.handleDownloadFailure(language: language, error: error) }
        }

    }
    
    /// 查詢目前已下載的語言模型
    public func listDownloadedModels() -> [String] {
        return manager.downloadedTranslateModels.compactMap { $0.name }
    }

    /// 查詢某語言是否正在下載中
    public func isDownloading(language: TranslateLanguage) -> Bool {
        downloadingLanguages.contains(language)
    }
    
    /// 刪除模型
    public func deleteModel(language: TranslateLanguage, completion: @escaping (Error?) -> Void) {
        let germanModel = TranslateRemoteModel.translateRemoteModel(language: .german)
        ModelManager.modelManager().deleteDownloadedModel(germanModel, completion: completion)
    }
    
    /// 啟動下載模型（若尚未下載）
    public func startDownload(
        language: TranslateLanguage,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let model = TranslateRemoteModel.translateRemoteModel(language: language)
        // 已下載就立即回傳
        if manager.isModelDownloaded(model) {
            completion(.success(()))
            return
        }
        // 收集所有對這個語言的 completion
        if completionHandlers[language] != nil {
            completionHandlers[language]?.append(completion)
        } else {
            completionHandlers[language] = [completion]
        }
        // 已在下載中就不重複呼叫 download
        if downloadingLanguages.contains(language) {
            return
        }
        downloadingLanguages.insert(language)
        let conditions = ModelDownloadConditions(
            allowsCellularAccess: true,
            allowsBackgroundDownloading: true
        )
        _ = manager.download(model, conditions: conditions)
    }
    
    private func handleDownloadSuccess(language: TranslateLanguage) {
        downloadingLanguages.remove(language)
        let completions = completionHandlers.removeValue(forKey: language) ?? []
        completions.forEach { $0(.success(())) }
    }

    private func handleDownloadFailure(language: TranslateLanguage, error: Error) {
        downloadingLanguages.remove(language)
        let completions = completionHandlers.removeValue(forKey: language) ?? []
        completions.forEach { $0(.failure(error)) }
    }

}
