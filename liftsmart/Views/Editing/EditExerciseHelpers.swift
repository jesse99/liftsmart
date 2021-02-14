//  Created by Jesse Jones on 11/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

protocol EditContext {
    var workout: Workout {get}
    var exercise: Exercise {get}
    var formalName: String {get set}
    var formalNameModal: Bool {get set}
    var errText: String {get set}
    var errColor: Color {get set}
    var showHelp: Bool {get set}
    var helpText: String {get set}
}

// TODO: Not using this because it does not work the first time a help button is clicked (there's no help text).
// It does work once you click a different help button.
struct ShowHelp: ViewModifier {
    let showing: Binding<Bool>
    let context: EditContext
    
    func body(content: Content) -> some View {
        return content
            .alert(isPresented: showing) {
                return Alert(
                    title: Text("Help"),
                    message: Text(context.helpText),
                    dismissButton: .default(Text("OK")))
            }
    }
}

func createNameView(text: Binding<String>, _ context: EditContext) -> some View {
    func editedName(_ text: String, _ inContext: EditContext) {
        func isDuplicateName(_ name: String) -> Bool {
            for candidate in context.workout.exercises {
                if candidate !== context.exercise && candidate.name == name {
                    return true
                }
            }
            return false
        }
        
        var context = inContext     // EditContext could be a struct so need to jump through a hoop to allow mutating it
        let name = text.trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            context.errText = "Name cannot be empty"
            context.errColor = .red
        } else if isDuplicateName(name) {
            context.errText = "Name matches another exercise in the workout"
            context.errColor = .orange
        } else {
            context.errText = ""
            context.exercise.name = name
        }
    }

    // TODO: Ideally this would be some sort of markdown popup anchored at the corresponding view.
    func nameHelp(_ inContext: EditContext) {
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
            //.autocapitalization(.words)       // crashing for some reason
            .onChange(of: text.wrappedValue, perform: {editedName($0, context)})
        Button("?", action: {nameHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

func editedFormalName(_ text: String, _ inContext: EditContext) {
    var context = inContext
    context.formalName = text
    context.exercise.formalName = text
}

func formalNameHelp(_ inContext: EditContext) {
    var context = inContext
    context.helpText = "The actual name for the exercise, e.g. 'Overhead Press'. This is used to lookup notes for the exercise."
    context.showHelp = true
}

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

func createFormalNameView(text: Binding<String>, modal: Binding<Bool>, _ context: EditContext) -> some View {
    return HStack {
        Text("Formal Name:").font(.headline)
        Button(text.wrappedValue, action: {var c = context; c.formalNameModal = true})
            .font(.callout)
            .sheet(isPresented: modal) {PickerView(title: "Formal Name", prompt: "Name: ", initial: text.wrappedValue, populate: matchFormalName, confirm: {editedFormalName($0, context)})}
        Spacer()
        Button("?", action: {formalNameHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

// TODO:
// Probably want to handle weight differently for different apparatus. For example, for barbell
// could use a picker like formal name uses: user can type in a weight and then is able to see
// all the nearby weights and select one if he wants.
func createWeightView(text: Binding<String>, _ context: EditContext) -> some View {
    func editedWeight(_ text: String, _ inContext: EditContext) {
        var context = inContext     // Nameable could be a struct so need to jump through a hoop to allow mutating it
        if let weight = Double(text) {
            if weight < 0.0 {
                context.errText = "Weight cannot be negative (found \(weight))"
                context.errColor = .red
            } else {
                context.errText = ""
                context.exercise.expected.weight = weight
            }
        } else {
            context.errText = "Expected a floating point number for weight (found '\(text)')"
            context.errColor = .red
        }
    }

    func weightHelp(_ inContext: EditContext) {
        var context = inContext
        context.helpText = "An arbitrary weight. For stuff like barbells the app will use the closest supported weight below this weight."
        context.showHelp = true
    }

    return HStack {
        Text("Weight:").font(.headline)
        TextField("", text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.decimalPad)
            .disableAutocorrection(true)
            .onChange(of: text.wrappedValue, perform: {editedWeight($0, context)})
        Button("?", action: {weightHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

typealias ExtraValidator = ([Int]) -> String?   // additional validation

// This is for a list of rest times.
func createRestView(text: Binding<String>, _ context: EditContext, extra: ExtraValidator? = nil) -> some View {
    func editedRest(_ text: String, _ inContext: EditContext) {
        // Note that we don't use comma separated lists because that's more visual noise and
        // because some locales use commas for the decimal points.
        var context = inContext

        let result = parseTimes(text, label: "rest", zeroOK: true)
        switch result {
        case .right(let times):
            if times.isEmpty {
                context.errText = "Rest needs at least one set"
                context.errColor = .red
                return
            }
            if let e = extra, let err = e(times) {
                context.errText = err
                context.errColor = .red
                return
            }
        case .left(let err):
            context.errText = err
            context.errColor = .red
            return
        }

        context.errText = ""
    }

    func restHelp(_ inContext: EditContext) {
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
            .onChange(of: text.wrappedValue, perform: {editedRest($0, context)})
        Button("?", action: {restHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}

