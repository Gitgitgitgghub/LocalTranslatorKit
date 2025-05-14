Pod::Spec.new do |s|
  s.name         = 'LocalTranslatorKit'
  s.version      = '1.0.1'
  s.summary      = 'MLKit wrapper for local translation, model downloading, and language detection.'

  s.description  = <<-DESC
LocalTranslatorKit 封裝了 Google MLKit 的翻譯功能，支援語言識別、自動模型下載、快取與錯誤處理。支援 async/await 語法，適合 SwiftUI 和 UIKit 專案。
  DESC

  s.homepage     = 'https://github.com/Gitgitgitgghub/LocalTranslatorKit'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Gitgitgitgghub' => 'hello780831work@gmail.com' }
  s.source       = { :git => 'https://github.com/Gitgitgitgghub/LocalTranslatorKit.git', :tag => s.version.to_s }

  # ✅ 必須為 15.5，否則 GoogleMLKit/Translate 無法編譯
  s.platform     = :ios, '15.5'
  s.swift_version = '5.9'
  s.static_framework = true


  s.source_files  = 'LocalTranslatorKit/Classes/**/*'

  s.dependency 'GoogleMLKit/Translate', '8.0.0'
  s.dependency 'GoogleMLKit/LanguageID', '8.0.0'
end
