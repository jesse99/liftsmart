//  Created by Jesse Jones on 9/26/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

var editWorkoutID: Int = 0

struct EditWorkoutEntry: Identifiable {
    let name: String
    let color: Color
    let id: Int     // can't use this as an index because ids should change when entries change
    let index: Int

    init(_ name: String, _ color: Color, _ index: Int) {
        self.name = name
        self.color = color
        self.id = editWorkoutID
        self.index = index
        
        editWorkoutID += 1
    }
}

struct EditWorkoutView: View {
    let workout: Workout
    @State var name = ""
    @State var entries: [EditWorkoutEntry] = []
    @State var errText = ""
    @State var showEditActions: Bool = false
    @State var editIndex: Int = 0
    @State var showSheet: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack {
            Text("Edit Workout").font(.largeTitle)

            HStack {
                Text("Name:").font(.headline)
                TextField("", text: self.$name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .disableAutocorrection(false)
            }.padding()
            Divider()
            
            List(self.entries) {entry in
                VStack(alignment: .leading) {
                    if self.entries.last != nil && entry.id == self.entries.last!.id {
                        Text(entry.name).foregroundColor(entry.color).font(.headline).italic()
                    } else {
                        Text(entry.name).foregroundColor(entry.color).font(.headline)
                    }
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {self.showEditActions = true; self.editIndex = entry.index}
            }
            Text(self.errText).foregroundColor(.red).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout)
            }
            .padding()
            .onAppear {self.refresh()}
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.entries[self.editIndex].name), buttons: editButtons())}
        .sheet(isPresented: self.$showSheet) {
            EditTextView(title: "Exercise Name", content: "", completion: self.doAdd)}
    }

    func refresh() {
        self.name = workout.name

        self.entries = self.workout.exercises.mapi({EditWorkoutEntry($1.name, $1.enabled ? .black : .gray, $0)})
        self.entries.append(EditWorkoutEntry("Add", .black, self.entries.count))
    }
    
    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if self.editIndex == self.entries.count - 1 {
            buttons.append(.default(Text("New Exercise"), action: {self.onAdd()}))
        } else {
            let len = self.entries.count - 1

            if self.editIndex != 0 && len > 1 {
                buttons.append(.default(Text("Move Up"), action: {self.doMove(by: -1); self.refresh()}))
            }
            if self.editIndex < len - 1 && len > 1 {
                buttons.append(.default(Text("Move Down"), action: {self.doMove(by: 1); self.refresh()}))
            }
            if self.workout.exercises[self.editIndex].enabled {
                buttons.append(.default(Text("Disable Exercise"), action: {self.onToggleEnabled()}))
            } else {
                buttons.append(.default(Text("Enable Exercise"), action: {self.onToggleEnabled()}))
            }
            buttons.append(.default(Text("Delete Exercise"), action: {self.doDelete(); self.refresh()}))
        }

        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    func onAdd() {
        self.showSheet = true
    }

    func doAdd(_ name: String) {
        self.workout.addExercise(name)

        self.errText = ""
        self.refresh()
    }

    private func onToggleEnabled() {
        self.workout.exercises[self.editIndex].enabled = !self.workout.exercises[self.editIndex].enabled
        self.refresh()
    }

    private func doDelete() {
        self.workout.exercises.remove(at: self.editIndex)
        self.refresh()
    }

    private func doMove(by: Int) {
        self.workout.moveExercise(self.editIndex, by: by)
        self.refresh()
    }
    
    func onCancel() {
        // TODO: need to revert changes
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.workout.name = self.name

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        EditWorkoutView(workout: cardio())
    }
    
    private static func cardio() -> Workout {
        func burpees() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Burpees", "Burpees", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func squats() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Squats", "Body-weight Squat", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }

        return createWorkout("Cardio", [burpees(), squats()], day: nil).unwrap()
    }
}

