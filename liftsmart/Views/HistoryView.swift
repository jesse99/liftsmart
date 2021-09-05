//  Created by Jesse Jones on 6/29/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct HistoryEntry: Identifiable {
    let record: History.Record
    let label: String
    let sublabel: String
    let note: String
    let id: Int

    init(_ record: History.Record, _ index: Int) {
        self.record = record
        self.label = record.label
        self.sublabel = record.completed.friendlyName()
        self.note = record.note
        self.id = index
    }
}

struct HistoryView: View {
    enum ActiveSheet {case editNote, editWeight}
    enum ActiveAlert {case deleteSelected, deleteAll}
    
    let workoutIndex: Int
    let exerciseID: Int
    @Environment(\.presentationMode) private var presentationMode
    @State var showEditActions: Bool = false
    @State var showSheet: Bool = false
    @State var sheetAction: HistoryView.ActiveSheet = .editNote
    @State var showAlert: Bool = false
    @State var alertAction: HistoryView.ActiveAlert = .deleteSelected
    @State var selection: HistoryEntry? = nil
    private let timer = RestartableTimer(every: TimeInterval.minutes(30))
    @ObservedObject var display: Display

    init(_ display: Display, _ workoutIndex: Int, _ exerciseID: Int) {
        self.display = display
        self.workoutIndex = workoutIndex
        self.exerciseID = exerciseID
    }

    var body: some View {
        let (entries, hasNote) = self.getEntries()
        VStack() {
            Text("\(exercise().name) History" + self.display.edited).font(.largeTitle)
            
            List(entries) {entry in
                VStack(alignment: .leading) {
                    HStack {
                        Text(entry.label).font(.headline)
                        Spacer()
                        Text(entry.sublabel).font(.headline)
                    }
                    if hasNote {
                        Text(entry.note).font(.subheadline)
                    }
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {self.showEditActions = true; self.selection = entry}
            }

            HStack {
                Button("Done", action: onDone).font(.callout)
            }
            .padding()
            .onAppear {self.timer.restart()}
            .onDisappear() {self.timer.stop()}
            .onReceive(timer.timer) {_ in self.display.send(.TimePassed)}   // subLabels will change as time passes
        }
            
        // Views can only have one sheet, see https://stackoverflow.com/questions/58837007/multiple-sheetispresented-doesnt-work-in-swiftui
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.sublabel), buttons: editButtons())}
        .sheet(isPresented: self.$showSheet) {
            if self.sheetAction == .editNote {
                EditTextView(self.display, title: "Edit Note", content: self.selection!.note, placeHolder: "user note", caps: .sentences, sender: self.onEditedNote)
            } else {
                EditTextView(self.display, title: "Edit Weight", content: friendlyWeight(self.selection!.record.weight), type: .decimalPad, validator: self.onValidWeight, sender: self.onEditedWeight)
            }}
        .alert(isPresented: $showAlert) {   // and views can only have one alert
            if self.alertAction == .deleteSelected {
                return Alert(
                    title: Text("Confirm delete"),
                    message: Text("From \(self.selection!.record.completed.friendlyName())"),
                    primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                    secondaryButton: .default(Text("Cancel")))
            } else {
                return Alert(
                    title: Text("Confirm delete all"),
                    message: Text("All \(entries.count) entries"),
                    primaryButton: .destructive(Text("Delete")) {self.doDeleteAll()},
                    secondaryButton: .default(Text("Cancel")))
            }}
    }
    
    func workout() -> Workout {
        return self.display.program.workouts[workoutIndex]
    }
    
    func exercise() -> Exercise {
        let instance = self.workout().exercises.first(where: {$0.id == self.exerciseID})!
        return self.display.program.exercises.first(where: {$0.name == instance.name})!
    }

    private func getEntries() -> ([HistoryEntry], Bool) {
        let items = Array(self.display.history.exercise(workout(), exercise()).suffix(200).reversed())
        let entries = items.mapi({HistoryEntry($1, $0)})
        return (entries, entries.any({!$0.note.isEmpty}))
    }

    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // Could allow label to be edited. Though if the user messes it up it'd be awkward
        // to undo that.
        buttons.append(.default(Text("Edit Weight"), action: {self.onEditWeight()}))
        buttons.append(.default(Text("Edit Note"), action: {self.onEditNote()}))
        buttons.append(.destructive(Text("Delete Entry"), action: {self.onDelete()}))
        buttons.append(.destructive(Text("Delete All"), action: {self.onDeleteAll()}))
        buttons.append(.cancel(Text("Cancel"), action: {}))
        
        return buttons
    }
    
    func onEditWeight() {
        self.showSheet = true
        self.sheetAction = .editWeight
    }

    func onEditNote() {
        self.showSheet = true
        self.sheetAction = .editNote
    }

    func onEditedNote(_ content: String) -> Action {
        return .SetHistoryNote(self.selection!.record, content)
    }

    func onEditedWeight(_ content: String) -> Action {
        return Action.SetHistoryWeight(self.selection!.record, Double(content)!)
    }

    func onValidWeight(_ content: String) -> Action {
        return .ValidateWeight(content, "weight")
    }
    
    func onDelete() {
        self.showAlert = true
        self.alertAction = .deleteSelected
    }

    func onDeleteAll() {
        self.showAlert = true
        self.alertAction = .deleteAll
    }
    
    func doDelete() {
        self.display.send(.DeleteHistory(workout(), self.exercise(), self.selection!.record))
    }

    func doDeleteAll() {
        self.display.send(.DeleteAllHistory(self.workout(), self.exercise()))
    }

    func onDone() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct HistoryView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workoutIndex = 0
    static let workout = display.program.workouts[workoutIndex]
    static let exercise = workout.exercises.first(where: {$0.name == "Curls"})!

    static var previews: some View {
        HistoryView(display, workoutIndex, exercise.id)
    }
}
