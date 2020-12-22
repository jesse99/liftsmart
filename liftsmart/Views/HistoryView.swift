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
    
    var history: History
    let workout: Workout
    let exercise: Exercise
    let title: String
    @Environment(\.presentationMode) private var presentationMode
    @State var entries: [HistoryEntry] = []
    @State var hasNote: Bool = false
    @State var showEditActions: Bool = false
    @State var showSheet: Bool = false
    @State var sheetAction: HistoryView.ActiveSheet = .editNote
    @State var showAlert: Bool = false
    @State var alertAction: HistoryView.ActiveAlert = .deleteSelected
    @State var editIndex: Int = 0
    private let timer = RestartableTimer(every: TimeInterval.minutes(30))

    // Note that updating @State members in init doesn't actually work: https://stackoverflow.com/questions/61661581/swiftui-view-apparently-laid-out-before-init-runs
    init(history: History, workout: Workout, exercise: Exercise) {
        self.history = history
        self.workout = workout
        self.exercise = exercise
        self.title = "\(exercise.name) History"
        self.refresh()
    }

    var body: some View {
        VStack() {
            Text(title).font(.largeTitle)
            
            List(self.entries) {entry in
                VStack(alignment: .leading) {
                    HStack {
                        Text(entry.label).font(.headline)
                        Spacer()
                        Text(entry.sublabel).font(.headline)
                    }
                    if self.hasNote {
                        Text(entry.note).font(.subheadline)
                    }
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {self.showEditActions = true; self.editIndex = entry.id}
            }
            
            HStack {
                Button("Done", action: onDone).font(.callout)
            }
            .padding()
            .onAppear {self.refresh(); self.timer.restart()}
            .onDisappear() {self.timer.stop()}
            .onReceive(timer.timer) {_ in self.refresh()}
        }
            
        // Views can only have one sheet, see https://stackoverflow.com/questions/58837007/multiple-sheetispresented-doesnt-work-in-swiftui
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.entries[self.editIndex].sublabel), buttons: editButtons())}
        .sheet(isPresented: self.$showSheet) {
            if self.sheetAction == .editNote {
                EditTextView(title: "Edit Note", placeHolder: "user note", content: self.entries[self.editIndex].note, completion: self.onEditedNote)
            } else {
                EditTextView(title: "Edit Weight", content: friendlyWeight(self.entries[self.editIndex].record.weight), type: .decimalPad, validator: self.onValidWeight, completion: self.onEditedWeight)
            }}
        .alert(isPresented: $showAlert) {   // and views can only have one alert
            if self.alertAction == .deleteSelected {
                return Alert(
                    title: Text("Confirm delete"),
                    message: Text("From \(self.entries[self.editIndex].record.completed.friendlyName())"),
                    primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                    secondaryButton: .default(Text("Cancel")))
            } else {
                return Alert(
                    title: Text("Confirm delete all"),
                    message: Text("All \(self.entries.count) entries"),
                    primaryButton: .destructive(Text("Delete")) {self.doDeleteAll()},
                    secondaryButton: .default(Text("Cancel")))
            }}
    }
    
    // subLabels will change as time passes so we need the timer to ensure that our UI updates accordingly.
    // labels and notes can change via our nested sheet so we update those when this view appears.
    func refresh() {
        let items = Array(history.exercise(workout, exercise).suffix(200).reversed())
        self.entries = items.mapi({HistoryEntry($1, $0)})
        self.hasNote = self.entries.any({!$0.note.isEmpty})
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

    func onEditedNote(_ content: String) {
        self.entries[self.editIndex].record.note = content
        self.refresh()

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
    }
    
    func onEditedWeight(_ content: String) {
        self.entries[self.editIndex].record.weight = Double(content)!
        self.refresh()
        
        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
    }

    func onValidWeight(_ content: String) -> String? {
        if let weight = Double(content) {
            if weight < 0.0 {
                return "Weight cannot be negative"
            }
            return nil
        } else {
            return "Not a number"
        }
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
        // Note that it's problematic to pass editIndex into history becaise editIndex
        // indexes into entries which is a transformed version of history.
        self.history.delete(workout, exercise, self.entries[self.editIndex].record)
        self.refresh()
        
        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
    }

    func doDeleteAll() {
        self.history.deleteAll(workout, exercise)
        self.refresh()
        
        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
    }

    func onDone() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        createView()
    }
    
    private static func createView() -> HistoryView {
        let durations = createDurations(secs: [60], rest: [60])
        let sets = Sets.durations(durations)
        let modality = Modality(Apparatus.bodyWeight, sets)
        let exercise = Exercise("Squats", "Body-weight Squat", modality)
        let workout = createWorkout("Lower", [exercise], day: nil).unwrap()

        let history = History()
        exercise.current = Current(weight: 0.0)
        exercise.current?.startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        exercise.current!.setIndex = 1
        history.append(workout, exercise)

        exercise.current?.startDate = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
        history.append(workout, exercise)
        
        exercise.current?.startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        history.append(workout, exercise)
        
        exercise.current?.startDate = Date()
        exercise.current = Current(weight: 10.0)
        let record = history.append(workout, exercise)
        record.note = "Felt strong!"

        return HistoryView(history: history, workout: workout, exercise: exercise)
    }
}
