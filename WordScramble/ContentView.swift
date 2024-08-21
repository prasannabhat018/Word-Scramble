//
//  ContentView.swift
//  WordScramble
//
//  Created by Prasanna Bhat on 09/08/24.
//

import SwiftUI

struct ContentView: View {
    @State private var rootword: String = ""
    @State private var usedWords: [String] = []
    @State private var allWords: [String] = []
    @State private var currentWord: String = ""
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isAlertShown = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                viewBackground
                
                List {
                    rootWordHeading
                    
                    Section {
                        TextField("Enter Scramblers", text: $currentWord)
                            .onSubmit(didSubmit)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                    }
                    
                    Section {
                        usedWordItems
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Word Scramble")
            .onAppear(perform: loadWords)
            .alert(alertTitle, isPresented: $isAlertShown) {
                Button("Ok") { }
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                Button {
                    selectNewWord()
                } label: {
                    Label("Restart", systemImage: "restart")
                }
                .tint(.black)
            }
            
        }
    }
}

// MARK: View Sub Components
extension ContentView {
    @ViewBuilder private var usedWordItems: some View {
        ForEach(0..<usedWords.count, id: \.self) { index in
            HStack {
                Image(systemName: "\(index+1).circle")
                Text("\(usedWords[index])")
            }
        }
    }
    
    @ViewBuilder private var viewBackground: some View {
        RadialGradient(gradient: Gradient(colors: [.yellow, .white]),
                       center: .top,
                       startRadius: 200,
                       endRadius: 2500)
        .ignoresSafeArea()
    }
    
    @ViewBuilder private var rootWordHeading: some View {
        Text("\(rootword.lowercased())")
            .foregroundStyle(.white)
            .font(.title)
            .fontWeight(.bold)
            .listRowBackground(Color.clear)
    }
}

// MARK: Logic Related
extension ContentView {
    
    // add current word to list of words if it's valid
    private func didSubmit() {
        let addedWord = currentWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let isValid = try validate(word: addedWord)
            withAnimation {
                usedWords.insert(addedWord, at: 0)
            }
        } catch {
            showError(for: error)
        }
        currentWord = ""
    }
    
    private func showError(for error: Error) {
        if let error = error as? WordFormationError {
            alertTitle = error.errorTitle
            alertMessage = error.errorMessage(rootWord: rootword)
        } else {
            alertTitle = "Sorry"
            alertMessage = "Something went wrong!"
        }
        isAlertShown = true
    }
    
    private func validate(word: String) throws -> Bool  {
        func isOriginal() -> Bool {
            !usedWords.contains(word)
        }
        
        func isPossible() -> Bool {
            var frequency: [Character: Int] = [:]
            rootword.forEach { char in
                frequency[char] = frequency[char, default: 0] + 1
            }
            
            for char in word {
                frequency[char] = frequency[char, default: 0] - 1
                if let currentFreq = frequency[char],
                    currentFreq < 0 {
                    return false
                }
            }
            return true
        }
        
        func isReal() -> Bool {
            let checker = UITextChecker()
            let range = NSRange(location: 0, length: word.utf16.count)
            let mispelledRange = checker.rangeOfMisspelledWord(in: word,
                                                               range: range,
                                                               startingAt: 0,
                                                               wrap: false,
                                                               language: "en")
            return mispelledRange.location == NSNotFound
        }
        
        // start from here
        guard word.count > 0 else {
            throw WordFormationError.invalid
        }
        
        guard word.count > 2 else {
            throw WordFormationError.short
        }
        
        guard isOriginal() else {
            throw WordFormationError.notOriginal
        }
        
        guard isPossible() else {
            throw WordFormationError.notPossible
        }
        
        guard isReal() else {
            throw WordFormationError.notReal
        }
        
        return true
        
    }
    
    // performed only once at the launch of the program
    private func loadWords() {
        guard let url = Bundle.main.url(forResource: "start", withExtension: "txt"),
              let lines = try? String(contentsOf: url) else {
            fatalError()
        }
        let words = lines.split(separator: "\n")
        allWords = words.map { String($0) }
        selectNewWord()
    }
    
    private func selectNewWord() {
        rootword = allWords.randomElement() ?? ""
        currentWord = ""
        usedWords = []
    }
}

enum WordFormationError: Error {
    case notReal
    case invalid
    case notPossible
    case notOriginal
    case short
    
    func errorMessage(rootWord: String) -> String {
        switch self {
        case .notReal:
            "You can't just make them up, you know!"
        case .invalid:
            "You should Enter something"
        case .notPossible:
            "You can't spell that word from '\(rootWord)'!"
        case .notOriginal:
            "Be more original"
        case .short:
            "Word length should be atlest 3"
        }
    }
    
    var errorTitle: String {
        switch self {
        case .notReal:
            "Word not recognized"
        case .invalid:
            "Word is Invalid"
        case .notPossible:
            "Word not possible"
        case .notOriginal:
            "Word used already"
        case .short:
            "To Short"
        }
    }
}


#Preview {
    ContentView()
}
