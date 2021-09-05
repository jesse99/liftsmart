//  Created by Jesse Jones on 12/19/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditRepRangesView: View {
    let name: String
    let sets: Binding<Sets>
    let expectedReps: Binding<[Int]>
    @State var showHelp = false
    @State var helpText = ""
    @State var repsModal = false
    @State var repsKind = EditRepsSetView.Kind.Warmup
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ name: String, _ sets: Binding<Sets>, _ expectedReps: Binding<[Int]>) {
        self.display = display
        self.name = name
        self.sets = sets
        self.expectedReps = expectedReps
    }

    var body: some View {
        VStack() {
            Text("Edit " + self.name + self.display.edited).font(.largeTitle).padding()

            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button("Warmups", action: self.onWarmups).font(.callout)
                        Spacer()
                        Button("?", action: {
                            self.helpText = "Optional sets to be done with a lighter weight."
                            self.showHelp = true
                        }).font(.callout).padding(.trailing)
                    }.padding(.leading)
                    Divider()
                    HStack {
                        Button("Work Sets", action: self.onWorkSets).font(.callout)
                        Spacer()
                        Button("?", action: {
                            self.helpText = "Sets to be done with 100% or so of the weight."
                            self.showHelp = true
                        }).font(.callout).padding(.trailing)
                    }.padding(.leading)
                    Divider()
                    HStack {
                        Button("Backoff", action: self.onBackoff).font(.callout)
                        Spacer()
                        Button("?", action: {
                            self.helpText = "Optional sets to be done with a reduced weight."
                            self.showHelp = true
                        }).font(.callout).padding(.trailing)
                    }.padding(.leading)
                    .sheet(isPresented: self.$repsModal) {EditRepsSetView(self.display, self.name, self.repsKind, self.sets, self.expectedReps)}
                }
            }
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
    }
    
    private func onWarmups() {
        self.repsModal = true
        self.repsKind = .Warmup
    }
    
    private func onWorkSets() {
        self.repsModal = true
        self.repsKind = .WorkSets
    }
    
    private func onBackoff() {
        self.repsModal = true
        self.repsKind = .Backoff
    }
    
    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditRepRangesView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let exercise = display.program.exercises.first(where: {$0.name == "Split Squat"})!
    static let sets = Binding.constant(exercise.modality.sets)
    static let expectedReps = Binding.constant(exercise.expected.reps)

    static var previews: some View {
        EditRepRangesView(display, exercise.name, sets, expectedReps)
    }
}

