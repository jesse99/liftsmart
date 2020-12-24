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
    var workout: Workout
    let original: Workout
    @State var name = ""
    @State var daysLabel = ""
    @State var monLabel = ""
    @State var tuesLabel = ""
    @State var wedLabel = ""
    @State var thursLabel = ""
    @State var friLabel = ""
    @State var satLabel = ""
    @State var sunLabel = ""
    @State var entries: [EditWorkoutEntry] = []
    @State var errText = ""
    @State var showEditActions: Bool = false
    @State var editIndex: Int = 0
    @State var showSheet: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    
    init(workout: Workout) {
        self.workout = workout
        self.original = workout.clone()
    }
    
    var body: some View {
        VStack() {
            Text("Edit Workout").font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text("Name:").font(.headline)
                    TextField("", text: self.$name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(false)
                }.padding(.leading)
                Menu(self.daysLabel) {
                    Button(self.sunLabel, action: {self.toggleDay(.sunday)})
                    Button(self.monLabel, action:{self.toggleDay(.monday)})
                    Button(self.tuesLabel, action:{self.toggleDay(.tuesday)})
                    Button(self.wedLabel, action:{self.toggleDay(.wednesday)})
                    Button(self.thursLabel, action:{self.toggleDay(.thursday)})
                    Button(self.friLabel, action:{self.toggleDay(.friday)})
                    Button(self.satLabel, action:{self.toggleDay(.saturday)})
                    Button("Cancel", action: {})
                }.font(.callout).padding(.leading)
                
                List(self.entries) {entry in
                    VStack() {
                        if self.entries.last != nil && entry.id == self.entries.last!.id {
                            Text(entry.name).foregroundColor(entry.color).font(.headline).italic()
                        } else {
                            Text(entry.name).foregroundColor(entry.color).font(.headline)
                        }
                    }
                    .contentShape(Rectangle())  // so we can click within spacer
                        .onTapGesture {self.showEditActions = true; self.editIndex = entry.index}
                }
            }
            Text(self.errText).foregroundColor(.red).font(.callout).padding(.leading)

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
    
    func toggleDay(_ day: WeekDay) {
        self.workout.days[day.rawValue] = !self.workout.days[day.rawValue]
        self.refresh()
    }

    func refresh() {
        func daysStr(_ days: [Bool]) -> String {
            assert(days.count == 7)
            if days == [false, false, false, false, false, false, false] {
                return "Any Day"
            }

            if days == [true, true, true, true, true, true, true] {
                return "Every Day"
            }

            var labels: [String] = []
            let weekDays = days == [false, true, true, true, true, true, false]
            if weekDays {
                labels.append("Week Days")
            }

            let weekEnds = days == [true, false, false, false, false, false, true]
            if weekEnds {
                labels.append("Week Ends")
            }
            
            if !weekEnds && days[0] {
                labels.append("Sunday")
            }
            if !weekDays {
                if days[1] {
                    labels.append("Monday")
                }
                if days[2] {
                    labels.append("Tuesday")
                }
                if days[3] {
                    labels.append("Wednesday")
                }
                if days[4] {
                    labels.append("Thursday")
                }
                if days[5] {
                    labels.append("Friday")
                }
            }
            if !weekEnds && days[6] {
                labels.append("Saturday")
            }
            return labels.joined(separator: ", ")
        }
        
        func buttonStr(_ day: WeekDay) -> String {
            let modifier = self.workout.days[day.rawValue] ? "Remove " : "Add "
            let label = String(describing: day)
            return modifier + label
        }
        
        self.name = workout.name
        self.daysLabel = daysStr(workout.days)

        self.monLabel = buttonStr(.monday)
        self.tuesLabel = buttonStr(.tuesday)
        self.wedLabel = buttonStr(.wednesday)
        self.thursLabel = buttonStr(.thursday)
        self.friLabel = buttonStr(.friday)
        self.satLabel = buttonStr(.saturday)
        self.sunLabel = buttonStr(.sunday)

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
        self.workout.restore(self.original)
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

