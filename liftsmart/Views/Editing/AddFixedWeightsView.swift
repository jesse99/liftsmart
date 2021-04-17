//  Created by Jesse Jones on 4/17/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

/// Used to add one or more weights to a FixedWeightSet.
struct AddFixedWeightsView: View {
    let name: String
    @State var first = ""
    @State var max = ""
    @State var step = ""
    @State var showHelp = false
    @State var helpText = ""
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ name: String) {
        self.display = display
        self.name = name
        self.display.send(.BeginTransaction(name: "add fws weights"))
    }

    var body: some View {
        VStack() {
            Text("Add to " + self.name + self.display.edited).font(.largeTitle)

            HStack {
                Text("First:").font(.headline)
                TextField("10", text: self.$first)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .disableAutocorrection(true)
                    .onChange(of: self.first, perform: self.onEditedRange)
                Button("?", action: self.onFirstHelp).font(.callout).padding(.trailing)
            }.padding()

            HStack {
                Text("Step:").font(.headline)
                TextField("10", text: self.$step)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .disableAutocorrection(true)
                    .onChange(of: self.step, perform: self.onEditedRange)
                Button("?", action: self.onStepHelp).font(.callout).padding(.trailing)
            }.padding()

            HStack {
                Text("max:").font(.headline)
                TextField("200", text: self.$max)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .disableAutocorrection(true)
                    .onChange(of: self.max, perform: self.onEditedRange)
                Button("?", action: self.onMaxHelp).font(.callout).padding(.trailing)
            }.padding()
            Spacer()
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(self.display.hasError)
            }
            .padding()
        }
        .alert(isPresented: $showHelp) {   // and views can only have one alert
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
        .onAppear(perform: {self.display.send(.ValidateFixedWeightRange(self.first, self.step, self.max))})
    }

    private func onEditedRange(_ text: String) {
        self.display.send(.ValidateFixedWeightRange(self.first, self.step, self.max))
    }
        
    private func onFirstHelp() {
        self.helpText = "The lowest weight to add."
        self.showHelp = true
    }

    private func onStepHelp() {
        self.helpText = "The weight increment."
        self.showHelp = true
    }

    private func onMaxHelp() {
        self.helpText = "Weights stop being added after this is reached. If empty then only first will be added."
        self.showHelp = true
    }

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "add fws weights"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        if let f = Double(self.first) { // this should always work
            if let s = Double(self.step), let m = Double(self.max) {
                self.display.send(.AddFixedWeightRange(self.name, f, s, m))
            } else {
                self.display.send(.AddFixedWeightRange(self.name, f, 1, f))
            }
        }
        self.display.send(.ConfirmTransaction(name: "add fws weights"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct AddFixedWeightsSView_Previews: PreviewProvider {
    static let display = previewDisplay()

    static var previews: some View {
        AddFixedWeightsView(display, "Dumbbells")
    }
}

