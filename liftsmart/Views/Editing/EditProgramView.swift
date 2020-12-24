//  Created by Jesse Jones on 9/26/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

var editProgramID: Int = 0

struct EditProgramEntry: Identifiable {
    let name: String
    let color: Color
    let id: Int     // can't use this as an index because ids should change when entries change
    let index: Int

    init(_ name: String, _ color: Color, _ index: Int) {
        self.name = name
        self.color = color
        self.id = editProgramID
        self.index = index
        
        editProgramID += 1
    }
}

// TODO: Allow notes to be edited?
// TODO: Might be nice to allow user to support program snapshots. Would need to be able
// to create these, delete them, and load them. Would need a warning when loading.
struct EditProgramView: View {
    var program: Program
    let original: Program
    @State var name = ""
    @State var entries: [EditProgramEntry] = []
    @State var errText = ""
    @State var showEditActions: Bool = false
    @State var editIndex: Int = 0
    @State var showSheet: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    
    init(program: Program) {
        self.program = program
        self.original = program.clone()
    }

    var body: some View {
        VStack {
            Text("Edit Program").font(.largeTitle)

            HStack {
                Text("Name:").font(.headline)
                TextField("", text: self.$name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .disableAutocorrection(false)
            }.padding()

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
            EditTextView(title: "Workout Name", content: "", completion: self.doAdd)}
    }

    func refresh() {
        self.name = program.name

        self.entries = self.program.mapi({EditProgramEntry($1.name, $1.enabled ? .black : .gray, $0)})
        self.entries.append(EditProgramEntry("Add", .black, self.entries.count))
    }

    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if self.editIndex == self.entries.count - 1 {
            buttons.append(.default(Text("New Workout"), action: {self.onAdd()}))
        } else {
            let len = self.entries.count - 1

            if self.editIndex != 0 && len > 1 {
                buttons.append(.default(Text("Move Up"), action: {self.doMove(by: -1); self.refresh()}))
            }
            if self.editIndex < len - 1 && len > 1 {
                buttons.append(.default(Text("Move Down"), action: {self.doMove(by: 1); self.refresh()}))
            }
            if self.program[self.editIndex].enabled {
                buttons.append(.default(Text("Disable Workout"), action: {self.onToggleEnabled()}))
            } else {
                buttons.append(.default(Text("Enable Workout"), action: {self.onToggleEnabled()}))
            }
            buttons.append(.default(Text("Delete Workout"), action: {self.doDelete(); self.refresh()}))
        }

        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }

    func onAdd() {
        self.showSheet = true
    }

    func doAdd(_ name: String) {
        if let err = self.program.addWorkout(name) {
            self.errText = err
        } else {
            self.errText = ""
            self.refresh()
        }
    }
    
    private func onToggleEnabled() {
        self.program[self.editIndex].enabled = !self.program[self.editIndex].enabled
        self.refresh()
    }

    private func doDelete() {
        self.program.delete(self.editIndex)
        self.refresh()
    }

    private func doMove(by: Int) {
        self.program.moveWorkout(self.editIndex, by: by)
        self.refresh()
    }

    func onCancel() {
        self.program.restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.program.name = self.name

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditProgramView_Previews: PreviewProvider {
    static var previews: some View {
        EditProgramView(program: home())
    }
    
    private static func home() -> Program {
        func burpees() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Burpees", "Burpees", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func squats() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Squats", "Body-weight Squat", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func planks() -> Exercise { // TODO: this should be some sort of progression
            let durations = [
                DurationSet(secs: 60, restSecs: 90),
                DurationSet(secs: 60, restSecs: 90),
                DurationSet(secs: 60, restSecs: 90)]
            let sets = Sets.durations(durations, targetSecs: [60, 60, 60])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Planks", "Front Plank", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func curls() -> Exercise {
            let sets = Sets.maxReps(restSecs: [90, 90, 0])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Curls", "Hammer Curls", modality, Expected(weight: 9.0, reps: [65]))
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            e.current!.setIndex = 1
            return e
        }

        let workouts = [
            createWorkout("Cardio", [burpees(), squats()], day: nil).unwrap(),
            createWorkout("Lower", [burpees(), squats()], day: .wednesday).unwrap(),
            createWorkout("Upper", [planks(), curls()], day: .monday).unwrap()]
        return Program("Split", workouts)
    }
}

