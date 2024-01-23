//
//  ContentView.swift
//  LuckyRoll
//
//  Created by Dominique Strachan on 1/22/24.
//

import SwiftUI

struct ContentView: View {
    let diceTypes = [4, 6, 8, 10, 12, 20, 100]
    
    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled
    
    @AppStorage("selectedDiceType") var selectedDiceType = 6
    @AppStorage("numberToRoll") var numberOfDice = 4
    
    @State private var currentResult = DiceResult(type: 0, number: 0)
    
    let timer = Timer.publish(every: 0.1, tolerance: 0.1, on: .main, in: .common).autoconnect()
    @State private var stoppedDice = 0
    
    @State private var feedback = UIImpactFeedbackGenerator(style: .rigid)
    
    let savePath = FileManager.documentsDirectory.appendingPathComponent("SavedRolls.json")
    @State private var savedResults = [DiceResult]()
    
    let columns: [GridItem] = [
        .init(.adaptive(minimum: 60))
    ]
    
    var body: some View {
        NavigationView {
            Form {

                Section {
                    Picker("Type of Dice", selection: $selectedDiceType) {
                        ForEach(diceTypes, id: \.self) { type in
                            Text("D\(type)")
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Stepper("Number of dice: \(numberOfDice)", value: $numberOfDice, in: 1...20)
                    
                    Button("Roll em!", action: rollDice)
                } footer: {
                    LazyVGrid(columns: columns) {
                        ForEach(0..<currentResult.rolls.count, id: \.self) { rollNumber in
                            Text(String(currentResult.rolls[rollNumber]))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .foregroundStyle(.black)
                                .background(.white)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                                .font(.title)
                                .padding(5)
                        }
                    }
                    .accessibilityElement()
                    .accessibilityLabel("Latest roll: \(currentResult.rolls.description)")
                }
                .disabled(stoppedDice < currentResult.rolls.count)
                
                if !savedResults.isEmpty {
                    Section("Previous Results") {
                        ForEach(savedResults) { result in
                            VStack(alignment: .leading) {
                                Text("\(result.number) x D\(result.type)")
                                    .font(.headline)
                                
                                Text(result.rolls.description)
                            }
                            .accessibilityElement()
                            .accessibilityHint("\(result.number) D\(result.type), \(result.rolls.description)")
                        }
                    }
                }
            }
            .navigationTitle("LuckyRoll")
            .onReceive(timer) { _ in
                // delayed by -20 
                updateDice()
            }
            .onAppear(perform: load)
        }
    }
    
    func rollDice() {
        currentResult = DiceResult(type: selectedDiceType, number: numberOfDice)
        
        // bypass animation if voice over is enabled
        if voiceOverEnabled {
            stoppedDice = numberOfDice
            savedResults.insert(currentResult, at: 0)
            save()
        } else {
            stoppedDice = -20
        }
    }
    
    func updateDice() {
        // exits function from -20 - -1 so that roll is longer from timer
        guard stoppedDice < currentResult.rolls.count else { return }
        
        for i in stoppedDice..<numberOfDice {
            // continue looping until ... not i < 0
            if i < 0 { continue }
            
            // placing dice number in each index
            currentResult.rolls[i] = Int.random(in: 1...selectedDiceType)
            
            // feedback.impactOccurred()
        }
        
        feedback.impactOccurred()
        stoppedDice += 1
        
        if stoppedDice == numberOfDice {
            // place at top of list
            savedResults.insert(currentResult, at: 0)
            save()
        }
    }
    
    func load() {
        if let data = try? Data(contentsOf: savePath) {
            if let results = try? JSONDecoder().decode([DiceResult].self, from: data) {
                savedResults = results
            }
        }
    }
    
    func save () {
        if let data = try? JSONEncoder().encode(savedResults) {
            try? data.write(to: savePath, options: [.atomic, .completeFileProtection])
        }
    }
}

#Preview {
    ContentView()
}
