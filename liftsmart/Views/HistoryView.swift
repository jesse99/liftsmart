//  Created by Jesse Jones on 6/29/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct HistoryView: View {
    var items: [History.Record]
    let title: String
    @Environment(\.presentationMode) private var presentationMode
    @State var hasNote: Bool = false
    @State var labels: [String] = Array(repeating: "", count: 200)
    @State var subLabels: [String] = Array(repeating: "", count: 200)
    @State var notes: [String] = Array(repeating: "", count: 200)
    @State var showEditActions: Bool = false
    @State var showEditNote: Bool = false
    @State var editIndex: Int = 0
    private let timer = RestartableTimer(every: TimeInterval.hours(Exercise.window/2))

    // Note that updating @State members in init doesn't actually work: https://stackoverflow.com/questions/61661581/swiftui-view-apparently-laid-out-before-init-runs
    init(history: History, workout: Workout, exercise: Exercise) {
        self.items = Array(history.exercise(workout, exercise).suffix(200).reversed())
        self.title = "\(exercise.name) History"
        self.hasNote = self.items.any({!$0.note.isEmpty})
    }

    var body: some View {
        VStack() {
            Text(title).font(.largeTitle)
            List(0..<items.count) { i in
                VStack(alignment: .leading) {
                    HStack {
                        Text(self.labels[i]).font(.headline)
                        Spacer()
                        Text(self.subLabels[i]).font(.headline)
                    }
                    if self.hasNote {
                        Text(self.notes[i]).font(.subheadline)
                    }
                }
                .contentShape(Rectangle())  // so we can click within spacer
                .onTapGesture {self.showEditActions = true; self.editIndex = i}
            }
            
            Divider()
            HStack {
                Button("Done", action: onDone).font(.callout)
                // TODO: probably should have a clear button (with confirm alert)
            }
            .padding()
            .onAppear {self.refresh(); self.timer.restart()}
            .onDisappear() {self.timer.stop()}
            .onReceive(timer.timer) {_ in self.refresh()}
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.subLabels[self.editIndex]), buttons: editButtons())}
        .sheet(isPresented: self.$showEditNote) {
            EditTextView(title: "Edit Note", placeHolder: "user note", content: self.notes[self.editIndex], completion: self.onEditedNote)}
    }
    
    // subLabels will change as time passes so we need the timer to ensure that our UI updates accordingly.
    // labels and notes can change via our nested sheet so we update those when this view appears.
    func refresh() {
        labels = items.map({self.label($0)})
        subLabels = items.map({$0.completed.daysName()})    // smallest reported interval is days so timer period can be very long
        notes = items.map({$0.note})
        self.hasNote = self.items.any({!$0.note.isEmpty})
    }
    
    func label(_ record: History.Record) -> String {
        if record.weight > 0.0 {
            return "\(record.label) @ \(friendlyUnitsWeight(record.weight))"
        } else {
            return record.label
        }
    }
    
    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        buttons.append(.default(Text("Edit Weight"), action: {self.onEditWeight()}))
        buttons.append(.default(Text("Edit Note"), action: {self.onEditNote()}))
        buttons.append(.destructive(Text("Delete Entry"), action: {self.onDelete()}))
        buttons.append(.cancel(Text("Cancel"), action: {}))
        
        return buttons
    }
    
    func onEditWeight() {
        // TODO: probably want a new reuseable view for this
        print("onEditWeight for \(editIndex)")
    }

    func onEditNote() {
        self.showEditNote = true
    }

    func onEditedNote(_ content: String) {
        self.items[self.editIndex].note = content
        self.refresh()
    }

    func onDelete() {
        print("onDelete for \(editIndex)")
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
        let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        let exercise = Exercise("Squats", "Body-weight Squat", modality)
        let workout = Workout("Lower", [exercise])!

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
