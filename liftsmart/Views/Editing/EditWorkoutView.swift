//  Created by Jesse Jones on 9/26/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

enum WorkoutSheetType {
    case add
    case changeApparatus
    case changeType
}

// TODO: After a paste new was trying to do a change instead of a new when this was a @State variable.
var workoutSheetType = WorkoutSheetType.add

struct EditWorkoutView: View {
    var workout: Workout
    @State var name: String
    @State var showEditActions: Bool = false
    @State var selection: Exercise? = nil
    @State var showSheet: Bool = false
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ workout: Workout) {
        self.workout = workout
        self.display = display
        self._name = State(initialValue: workout.name)        
        self.display.send(.BeginTransaction(name: "edit workout"))
    }

    var body: some View {
        VStack() {
            Text("Edit Workout" + self.display.edited).font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text("Name:").font(.headline)
                    TextField("", text: self.$name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(false)
                        .onChange(of: self.name, perform: self.onEditedName)
                }.padding(.leading)
                Menu(daysStr(workout.days)) {
                    Button(buttonStr(.sunday), action: {self.onToggleDay(.sunday)})
                    Button(buttonStr(.monday), action:{self.onToggleDay(.monday)})
                    Button(buttonStr(.tuesday), action:{self.onToggleDay(.tuesday)})
                    Button(buttonStr(.wednesday), action:{self.onToggleDay(.wednesday)})
                    Button(buttonStr(.thursday), action:{self.onToggleDay(.thursday)})
                    Button(buttonStr(.friday), action:{self.onToggleDay(.friday)})
                    Button(buttonStr(.saturday), action:{self.onToggleDay(.saturday)})
                    Button("Cancel", action: {})
                }.font(.callout).padding(.leading)
                
                List(self.workout.exercises) {exercise in
                    VStack() {
                        if exercise.enabled {
                            Text(exercise.name).font(.headline)
                        } else {
                            Text(exercise.name).font(.headline).strikethrough(color: .red)
                        }
                    }
                    .contentShape(Rectangle())  // so we can click within spacer
                        .onTapGesture {
                            self.selection = exercise
                            self.showEditActions = true
                        }
                }
            }
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Paste", action: self.onPaste).font(.callout).disabled(self.display.exerciseClipboard == nil)
                Button("Add", action: self.onAdd).font(.callout)
                Button("OK", action: onOK).font(.callout).disabled(self.display.hasError)
            }
            .padding()
        }

//        case ChangeExerciseApparatus(Exercise, Apparatus)
//        case ChangeExerciseSets(Exercise, Sets)
//        case AddExercise(Workout, String)
        
        // TODO: look like all we need to do here is finish these three
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
//        .sheet(isPresented: self.$showSheet) {
//            switch workoutSheetType {
//            case .add:
//                AddExerciseView(workout: self.workout, dismiss: self.refresh)
//            case .changeType:
//                ChangeTypeView(workout: self.workout, index: self.editIndex, dismiss: self.refresh)
//            case .changeApparatus:
//                ChangeApparatusView(workout: self.workout, index: self.editIndex, dismiss: self.refresh)
//            }
//        }
    }
        
    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.default(Text("Change Apparatus"), action: {self.onChangeApparatus()}))
        buttons.append(.default(Text("Change Type"), action: {self.onChangeType()}))
        buttons.append(.default(Text("Copy"), action: {self.onCopy()}))
        buttons.append(.default(Text("Cut"), action: {self.onCopy(); self.onDelete()}))
        if self.selection!.enabled {
            buttons.append(.default(Text("Disable Exercise"), action: {self.onToggleEnabled()}))
        } else {
            buttons.append(.default(Text("Enable Exercise"), action: {self.onToggleEnabled()}))
        }
        buttons.append(.default(Text("Delete Exercise"), action: {self.onDelete()}))
        if self.workout.exercises.first != self.selection {
            buttons.append(.default(Text("Move Up"), action: {self.onMove(by: -1)}))
        }
        if self.workout.exercises.last != self.selection {
            buttons.append(.default(Text("Move Down"), action: {self.onMove(by: 1)}))
        }

        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
//    func doAdd(_ name: String) {
//        self.workout.addExercise(name)
//    }
    
    func onAdd() {
        workoutSheetType = .add
        self.showSheet = true
    }

    func onChangeApparatus() {
        workoutSheetType = .changeApparatus
        self.showSheet = true
    }

    func onChangeType() {
        workoutSheetType = .changeType
        self.showSheet = true
    }

    func onToggleDay(_ day: WeekDay) {
        self.display.send(.ToggleWorkoutDay(self.workout, day))
    }

    private func onToggleEnabled() {
        self.display.send(.ToggleEnableExercise(self.selection!))
    }

    private func onCopy() {
        self.display.send(.CopyExercise(self.selection!))
    }

    private func onPaste() {
        self.display.send(.PasteExercise(self.workout))
    }

    private func onDelete() {
        self.display.send(.DelExercise(self.workout, self.selection!))
    }

    private func onMove(by: Int) {
        self.display.send(.MoveExercise(self.workout, self.selection!, by))
    }
    
    func onEditedName(_ text: String) {
        self.display.send(.ValidateWorkoutName(text))
    }
    
    func onCancel() {
        self.display.send(.RollbackTransaction(name: "edit workout"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.display.send(.SetWorkoutName(self.workout, self.name))
        self.display.send(.ConfirmTransaction(name: "edit workout"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func buttonStr(_ day: WeekDay) -> String {
        let modifier = self.workout.days[day.rawValue] ? "Remove " : "Add "
        let label = String(describing: day)
        return modifier + label
    }
    
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
}

struct EditWorkoutView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[0]
    
    static var previews: some View {
        EditWorkoutView(display, workout)
    }
}

