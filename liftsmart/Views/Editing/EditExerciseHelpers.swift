//  Created by Jesse Jones on 11/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

protocol ExerciseContext {
    var showHelp: Bool {get set}
    var helpText: String {get set}
}

func exerciseNameView(_ context: ExerciseContext, _ text: Binding<String>, _ onEdit: @escaping (String) -> Void) -> some View {
    func nameHelp(_ inContext: ExerciseContext) {
        var context = inContext
        context.helpText = "Your name for the exercise, e.g. 'Light OHP'."
        context.showHelp = true
    }

    return HStack {
        Text("Name:").font(.headline)
        TextField("", text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.default)
            .disableAutocorrection(true)
            .autocapitalization(.words)
            .onChange(of: text.wrappedValue, perform: onEdit)
        Button("?", action: {nameHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

func exerciseFormalNameView(_ context: ExerciseContext, _ text: Binding<String>, _ modal: Binding<Bool>, _ onEdit: @escaping (String) -> Void) -> some View {
    func matchFormalName(_ inText: String) -> [String] {
        var names: [String] = []
        
        // TODO: better to do a proper fuzzy search
        let needle = inText.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()

        // First match any custom names defined by the user.
        for candidate in userNotes.keys {
            if defaultNotes[candidate] == nil {
                let haystack = candidate.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()
                if haystack.contains(needle) {
                    names.append(candidate)
                }
            }
        }
        
        // Then match the standard names.
        for candidate in defaultNotes.keys {
            let haystack = candidate.filter({!$0.isWhitespace}).filter({!$0.isPunctuation}).lowercased()
            if haystack.contains(needle) {
                names.append(candidate)
            }
            
            // Not much point in showing the user a huge list of names.
            if names.count >= 100 {
                break
            }
        }

        return names
    }
    
    func onEdited(_ inText: String) {
        text.wrappedValue = inText
        onEdit(inText)
    }

    func formalNameHelp(_ inContext: ExerciseContext) {
        var context = inContext
        context.helpText = "The actual name for the exercise, e.g. 'Overhead Press'. This is used to lookup notes for the exercise."
        context.showHelp = true
    }

    return HStack {
        Text("Formal Name:").font(.headline)
        Button(text.wrappedValue, action: {modal.wrappedValue = true})
            .font(.callout)
            .sheet(isPresented: modal) {PickerView(title: "Formal Name", prompt: "Name: ", initial: text.wrappedValue, populate: matchFormalName, confirm: onEdited)}
        Spacer()
        Button("?", action: {formalNameHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

func exerciseWeightView(_ context: ExerciseContext, _ text: Binding<String>, _ onEdit: @escaping (String) -> Void) -> some View {
    func weightHelp(_ inContext: ExerciseContext) {
        var context = inContext
        context.helpText = "An arbitrary weight. For stuff like barbells the app will use the closest supported weight below this weight."
        context.showHelp = true
    }

    // Probably want to handle weight differently for different apparatus. For example, for barbell
    // could use a picker like formal name uses: user can type in a weight and then is able to see
    // all the nearby weights and select one if he wants.
    return HStack {
        Text("Weight:").font(.headline)
        TextField("", text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.decimalPad)
            .disableAutocorrection(true)
            .onChange(of: text.wrappedValue, perform: onEdit)
        Button("?", action: {weightHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

func exerciseRestView(_ context: ExerciseContext, _ text: Binding<String>, _ onEdit: @escaping (String) -> Void) -> some View {
    func resttHelp(_ inContext: ExerciseContext) {
        var context = inContext
        context.helpText = "The amount of time to rest after each set. Time units may be omitted so '1.5m 60s 30 0' is a minute and a half, 60 seconds, 30 seconds, and no rest time."
        context.showHelp = true
    }

    return HStack {
        Text("Rest:").font(.headline)
        TextField("", text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.default)
            .disableAutocorrection(true)
            .onChange(of: text.wrappedValue, perform: onEdit)
        Button("?", action: {resttHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

