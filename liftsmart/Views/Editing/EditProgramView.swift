//  Created by Jesse Jones on 9/26/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

// TODO: Allow notes to be edited?
// TODO: Might be nice to allow user to support program snapshots. Would need to be able
// to create these, delete them, and load them. Would need a warning when loading.
struct EditProgramView: View {
    @State var name: String
    @State var currentWeek: String
    @State var selection: Workout? = nil
    @State var showEditActions = false
    @State var showAdd = false
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display) {
        self._name = State(initialValue: display.program.name)
        self.display = display
        if let start = display.program.blockStart, let numWeeks = display.program.numWeeks() {
            let thisWeek = liftsmart.currentWeek(blockStart: start, currentDate: Date(), numWeeks: numWeeks)
            self._currentWeek = State(initialValue: "\(thisWeek)")
        } else {
            self._currentWeek = State(initialValue: "")
        }
        self.display.send(.BeginTransaction(name: "edit program"))
    }

    var body: some View {
        VStack {
            Text("Edit Program" + self.display.edited).font(.largeTitle)

            HStack {
                Text("Name:").font(.headline)
                TextField("", text: self.$name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .autocapitalization(.words)
                    .disableAutocorrection(false)
                    .onChange(of: self.name, perform: self.onEditedName)
            }.padding(.leading).padding(.trailing)
            HStack {
                Text("Current Week:").font(.headline)   // TODO: probably should have help here
                TextField("1", text: self.$currentWeek)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .disableAutocorrection(false)
                    .onChange(of: self.currentWeek, perform: self.onEditedCurrentWeek)
            }.padding(.leading).padding(.trailing)
            Divider().background(Color.black)

            List(self.display.program.workouts) {workout in
                VStack(alignment: .leading) {
                    if workout.enabled {
                        Text(workout.name).font(.headline)
                    } else {
                        Text(workout.name).font(.headline).strikethrough(color: .red)
                    }
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {self.showEditActions = true; self.selection = workout}
            }
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: {self.showAdd = true}).font(.callout)
                Button("OK", action: onOK).font(.callout).disabled(self.display.hasError)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .sheet(isPresented: self.$showAdd) {
            EditTextView(self.display, title: "Workout Name", content: "", caps: .words, validator: {return .ValidateWorkoutName($0, nil)}, sender: {return .AddWorkout($0)})}
    }

    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if self.display.program.workouts.first !== self.selection {
            buttons.append(.default(Text("Move Up"), action: {self.doMove(by: -1)}))
        }
        if self.display.program.workouts.last !== self.selection {
            buttons.append(.default(Text("Move Down"), action: {self.doMove(by: 1)}))
        }
        if self.selection!.enabled {
            buttons.append(.default(Text("Disable Workout"), action: self.onToggleEnabled))
        } else {
            buttons.append(.default(Text("Enable Workout"), action: self.onToggleEnabled))
        }
        buttons.append(.destructive(Text("Delete Workout"), action: self.doDelete))

        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }

    private func onToggleEnabled() {
        self.display.send(.EnableWorkout(self.selection!, !self.selection!.enabled))
    }

    private func doDelete() {
        self.display.send(.DeleteWorkout(self.selection!))
    }

    private func doMove(by: Int) {
        self.display.send(.MoveWorkout(self.selection!, by))
    }

    func onEditedName(_ text: String) {
        self.display.send(.ValidateProgramName(self.display.program.name, text))
    }
    
    func onEditedCurrentWeek(_ text: String) {
        self.display.send(.ValidateCurrentWeek(text))
    }
    
    func onCancel() {
        self.display.send(.RollbackTransaction(name: "edit program"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        if name != self.display.program.name {
            self.display.send(.RenameProgram(self.display.program.name, self.name))
        }
        if let week = Int(self.currentWeek) {
            if let start = display.program.blockStart, let numWeeks = display.program.numWeeks() {
                if week != liftsmart.currentWeek(blockStart: start, currentDate: Date(), numWeeks: numWeeks) {
                    self.display.send(.SetCurrentWeek(week))
                }
            }
        } else {
            if self.display.program.blockStart != nil {
                self.display.send(.SetCurrentWeek(nil))
            }
        }
        self.display.send(.ConfirmTransaction(name: "edit program"))
        self.presentationMode.wrappedValue.dismiss()   
    }
}

struct EditProgramView_Previews: PreviewProvider {
    static var previews: some View {
        EditProgramView(previewDisplay())
    }
}

