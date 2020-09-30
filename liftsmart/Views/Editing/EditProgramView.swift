//  Created by Jesse Jones on 9/26/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

// TODO: probably want to just move this into EditProgramView
//struct EditListView: View {
//    typealias NamesFn = () -> [String]
//    typealias AddFn = (String) -> String?   // returns an error message if the add failed
//    typealias DeleteFn = (Int) -> Void
//    typealias MoveDownFn = (Int) -> Void
//    typealias MoveUpFn = (Int) -> Void
//    
//    @State var entries: [ListEntry] = []
//    @State var errText = ""
//    @State var showEditActions: Bool = false
//    @State var editIndex: Int = 0
//    @State var showSheet: Bool = false
//    @Environment(\.presentationMode) private var presentationMode
//    let title: String
//    var names: NamesFn
//    var add: AddFn?
//    var delete: DeleteFn?
//    var moveDown: MoveDownFn?
//    var moveUp: MoveUpFn?
//    var addPrompt = "Entry"
//    
//    var body: some View {
//        VStack {
//            Text(self.title).font(.largeTitle)
//            
//            List(self.entries) {entry in
//                VStack(alignment: .leading) {
//                    if entry.id == self.entries.last!.id && self.add != nil {
//                        Text(entry.name).font(.headline).italic()
//                    } else {
//                        Text(entry.name).font(.headline)
//                    }
//                }
//                .contentShape(Rectangle())  // so we can click within spacer
//                    .onTapGesture {self.showEditActions = true; self.editIndex = entry.index}
//            }
//            Text(self.errText).foregroundColor(.red).font(.callout)
//
//            Divider()
//            HStack {
//                Button("Cancel", action: onCancel).font(.callout)
//                Spacer()
//                Spacer()
//                Button("OK", action: onOK).font(.callout)
//            }
//            .padding()
//            .onAppear {self.refresh()}
//        }
//        .actionSheet(isPresented: $showEditActions) {
//            ActionSheet(title: Text(self.entries[self.editIndex].name), buttons: editButtons())}
//        .sheet(isPresented: self.$showSheet) {
//            EditTextView(title: "Edit \(self.addPrompt)", content: "", completion: self.onDoAdd)
//        }
//    }
//
//    func refresh() {
//        self.entries = self.names().mapi({ListEntry($1, $0)})
//        if self.add != nil {
//            self.entries.append(ListEntry("Add", self.entries.count))
//        }
//    }
//    
//    func editButtons() -> [ActionSheet.Button] {
//        var buttons: [ActionSheet.Button] = []
//        
//        if self.add != nil && self.editIndex == self.entries.count - 1 {
//            buttons.append(.default(Text("New \(addPrompt)"), action: {self.onAdd()}))
//        } else {
//            let len = self.add != nil ? self.entries.count - 1 : self.entries.count
//            
//            if let move = self.moveUp, self.editIndex != 0 && len > 1 {
//                buttons.append(.default(Text("Move Up"), action: {move(self.editIndex); self.refresh()}))
//            }
//            if let move = self.moveDown, self.editIndex < len - 1 && len > 1 {
//                buttons.append(.default(Text("Move Down"), action: {move(self.editIndex); self.refresh()}))
//            }
//            if let delete = self.delete {
//                buttons.append(.default(Text("Delete"), action: {delete(self.editIndex); self.refresh()}))
//            }
//        }
//        
//        buttons.append(.cancel(Text("Cancel"), action: {}))
//        
//        return buttons
//    }
//    
//    func onAdd() {
//        self.showSheet = true
//    }
//    
//    func onDoAdd(_ name: String) {
//        if let err = self.add!(name) {
//            self.errText = err
//        } else {
//            self.errText = ""
//            self.refresh()
//        }
//    }
//
//    func onCancel() {
//        // TODO: call a cancel callback
//        self.presentationMode.wrappedValue.dismiss()
//    }
//
//    func onOK() {
//        self.presentationMode.wrappedValue.dismiss()
//    }
//}

struct EditProgramView: View {
    let program: Program
    @State var name = ""
//    @State var entries: [ListEntry] = []  // TODO: might be able to use ProgramEntry here
    @Environment(\.presentationMode) private var presentationMode
    
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
            Spacer()

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
    }

    func refresh() {
        self.name = program.name
    }

    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.program.name = self.name   // TODO: save changes
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditProgramView_Previews: PreviewProvider {
    static var previews: some View {
        EditProgramView(program: home())
    }
    
    private static func home() -> Program {
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
        
        func planks() -> Exercise { // TODO: this should be some sort of progression
            let durations = [
                DurationSet(secs: 60, restSecs: 90)!,
                DurationSet(secs: 60, restSecs: 90)!,
                DurationSet(secs: 60, restSecs: 90)!]
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

