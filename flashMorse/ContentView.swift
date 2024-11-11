//
//  ContentView.swift
//  flashMorse
//
//  Created by 吉田侑己 on 2024/11/10.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isSendingMorse = false
    @State private var morseText = "HELLO"  // デフォルトのモールス文字
    @State private var repeatCount = 1  // デフォルトの繰り返し回数
    @State private var showingSettings = false  // 設定画面表示フラグ
    @State private var currentMorseCharacter = ""  // 現在送信中のモールス文字
    @State private var showError = false  // エラーメッセージ表示フラグ
    @State private var currentRepeat = 1  // 現在の繰り返し回数
    @State private var shouldStopSending = false  // 送信停止フラグ

    var body: some View {
        ZStack {
            (isSendingMorse ? Color.yellow.opacity(0.3) : Color.black.opacity(0.7))
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // モールス信号文字とそのモールスコードの表示
                Text("モールス信号: \(morseText) ")
                    .font(.title)
                    .foregroundColor(isSendingMorse ? .black : .white)
                    .padding()
                    .bold()
                
                Text("(\(convertToMorseCode(morseText)))")
                    .font(.title)
                    .foregroundColor(isSendingMorse ? .black : .white)
                    .padding()
                    .bold()
                
                if isSendingMorse {
                    // 現在送信中の文字表示
                    Text("現在送信中: \(currentMorseCharacter)")
                        .foregroundColor(.red)
                        .padding()
                    
                    // 繰り返し回数表示
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(.red)
                        Text("\(currentRepeat)/\(repeatCount)")
                            .foregroundColor(.red)
                            .bold()
                    }
                }
                
                Spacer()
                
                // モールス信号送信アイコンボタン
                Button(action: {
                    if morseText.isEmpty {
                        showErrorMessage()  // エラーメッセージを表示
                    } else if isSendingMorse {
                        shouldStopSending = true  // 中断要求
                    } else {
                        shouldStopSending = false  // 中断フラグをリセット
                        isSendingMorse = true
                        currentRepeat = 1  // 繰り返しカウンタをリセット
                        sendMorseSignal(morseText, repeatCount: repeatCount) {
                            isSendingMorse = false
                            currentMorseCharacter = ""  // 送信完了後にクリア
                        }
                    }
                }) {
                    Image(systemName: isSendingMorse ? "flashlight.on.fill" : "flashlight.off.fill")
                        .resizable()
                        .frame(width: 50, height: 100)
                        .foregroundColor(isSendingMorse ? .yellow : .gray)
                        .padding()
                }

                Spacer()
            }
            
            // エラーメッセージ表示
            if showError {
                Text("モールスする文字を入力してください")
                    .foregroundColor(.red)
                    .padding()
                    .cornerRadius(8)
            }
            
            // 設定ボタン（右下）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingSettings.toggle()
                    }) {
                        Image(systemName: "gearshape")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .padding()
                            .foregroundColor(.gray)
                    }
                }
                .disabled(isSendingMorse)  // 送信中は無効化
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(morseText: $morseText, repeatCount: $repeatCount)
        }
    }
    
    private func showErrorMessage() {
        showError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }
    
    private func sendMorseSignal(_ message: String, repeatCount: Int, completion: @escaping () -> Void) {
        let morseCodeDict: [Character: String] = [
            "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".",
            "F": "..-.", "G": "--.", "H": "....", "I": "..", "J": ".---",
            "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---",
            "P": ".--.", "Q": "--.-", "R": ".-.", "S": "...", "T": "-",
            "U": "..-", "V": "...-", "W": ".--", "X": "-..-", "Y": "-.--",
            "Z": "--..", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
            "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----.",
            "0": "-----"
        ]
        
        let morseString = message.uppercased().compactMap { morseCodeDict[$0] }
        
        Task {
            for repeatIndex in 1...repeatCount {
                if shouldStopSending { break }  // 中断フラグチェック
                currentRepeat = repeatIndex  // 現在の繰り返し回数を更新
                
                for (index, character) in message.enumerated() {
                    if shouldStopSending { break }
                    currentMorseCharacter = String(character)
                    
                    for symbol in morseString[index] {
                        if shouldStopSending { break }
                        
                        if symbol == "." {
                            toggleTorch(on: true)
                            try await Task.sleep(nanoseconds: 200_000_000)
                            toggleTorch(on: false)
                        } else if symbol == "-" {
                            toggleTorch(on: true)
                            try await Task.sleep(nanoseconds: 600_000_000)
                            toggleTorch(on: false)
                        }
                        try await Task.sleep(nanoseconds: 200_000_000)
                    }
                    try await Task.sleep(nanoseconds: 600_000_000)
                }
            }
            completion()
        }
    }
    
    private func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }
    
    private func convertToMorseCode(_ message: String) -> String {
        let morseCodeDict: [Character: String] = [
            "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".",
            "F": "..-.", "G": "--.", "H": "....", "I": "..", "J": ".---",
            "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---",
            "P": ".--.", "Q": "--.-", "R": ".-.", "S": "...", "T": "-",
            "U": "..-", "V": "...-", "W": ".--", "X": "-..-", "Y": "-.--",
            "Z": "--..", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
            "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----.",
            "0": "-----"
        ]
        return message.uppercased().compactMap { morseCodeDict[$0] }.joined(separator: " / ")
    }
}

struct SettingsView: View {
    @Binding var morseText: String
    @Binding var repeatCount: Int
    @State private var showAllowedCharactersInfo = false
    private let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    private let presetMessages = ["SOS", "HELP", "HELLO", "LOVE", "YES", "NO", "MORSE", "CODE", "FLASH", "TEST"]
    
    var body: some View {
        Form {
            Section(header: HStack {
                Text("モールスする文字")
                
                Button(action: {
                    showAllowedCharactersInfo.toggle()
                }) {
                    Image(systemName: "questionmark.circle")
                }
                .alert(isPresented: $showAllowedCharactersInfo) {
                    Alert(
                        title: Text("使用可能な文字"),
                        message: Text("A-Z（アルファベット大文字）および0-9（数字）")
                    )
                }
            }) {
                TextField("文字を入力", text: $morseText)
                    .onChange(of: morseText) { newValue in
                        morseText = newValue.uppercased().filter { allowedCharacters.contains($0) }
                    }
            }
            
            Section(header: Text("定型文字")) {
                ForEach(presetMessages, id: \.self) { message in
                    Button(action: {
                        morseText = message
                    }) {
                        Text(message)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section(header: Text("繰り返し回数")) {
                Stepper(value: $repeatCount, in: 1...10) {
                    Text("\(repeatCount) 回")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
