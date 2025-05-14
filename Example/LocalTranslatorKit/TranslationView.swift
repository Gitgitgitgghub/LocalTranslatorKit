import SwiftUI
import LocalTranslatorKit

struct TranslationView: View {
    @StateObject private var viewModel = TranslationViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    TextField("請輸入文字", text: $viewModel.inputText)
                        .textFieldStyle(.roundedBorder)
                        .padding()

                    VStack(alignment: .leading) {
                        Text("選擇目標語言：")
                            .font(.headline)
                            .padding(.horizontal)

                        Picker("翻譯語言", selection: $viewModel.selectedLanguage) {
                            ForEach(viewModel.availableLanguages, id: \.self) { lang in
                                Text(displayName(for: lang)).tag(lang)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                    }

                    Button(action: {
                        viewModel.translate()
                    }) {
                        Text("翻譯")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView("翻譯中...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        Text("❌ \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else if !viewModel.translatedText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("✅ 翻譯結果：")
                                .font(.headline)
                            Text(viewModel.translatedText)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("MLKit 翻譯範例")
        }
    }

    private func displayName(for language: TranslateLanguage) -> String {
        return language.displayName
    }
}

