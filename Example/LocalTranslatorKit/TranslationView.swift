import SwiftUI

struct TranslationView: View {
    @StateObject private var viewModel = TranslationViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("請輸入文字", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("翻譯為英文") {
                    viewModel.translate(to: .english)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView("翻譯中...")
                } else if let error = viewModel.errorMessage {
                    Text("❌ \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if !viewModel.translatedText.isEmpty {
                    Text("✅ 翻譯結果：\n\(viewModel.translatedText)")
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("MLKit 翻譯範例")
        }
    }
}
