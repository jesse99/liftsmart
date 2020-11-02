//  Created by Jesse Jones on 11/2/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

// ---- Name TextField ----------------------------------------------------------------------------------
protocol NameContext {
    var workout: Workout {get}
    var exercise: Exercise {get}
    var name: String {get}
    var errText: String {get set}
    var errColor: Color {get set}
    var showHelp: Bool {get set}
    var helpText: String {get set}
}

func editedName(_ text: String, _ inContext: NameContext) {
    func isDuplicateName(_ name: String) -> Bool {
        for candidate in context.workout.exercises {
            if candidate !== context.exercise && candidate.name == name {
                return true
            }
        }
        return false
    }
    
    var context = inContext     // Nameable could be a struct so need to jump through a hoop to allow mutating it
    let name = text.trimmingCharacters(in: .whitespaces)
    if name.isEmpty {
        context.errText = "Name cannot be empty"
        context.errColor = .red
    } else if isDuplicateName(name) {
        context.errText = "Name matches another exercise in the workout"
        context.errColor = .orange
    } else {
        context.errText = ""
    }
}

// TODO: Ideally this would be some sort of markdown popup anchored at the corresponding view.
func nameHelp(_ inContext: NameContext) {
    var context = inContext
    context.helpText = "Your name for the exercise, e.g. 'Light OHP'."
    context.showHelp = true
}

func createnameView(text: Binding<String>, _ context: NameContext) -> some View {
    HStack {
        Text("Name:").font(.headline)
        TextField("", text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.default)
            .disableAutocorrection(true)
            .onChange(of: text.wrappedValue, perform: {editedName($0, context)})
        Button("?", action: {nameHelp(context)}).font(.callout).padding(.trailing)
    }.padding(.leading)
}
