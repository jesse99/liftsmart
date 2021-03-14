//  Created by Jesse Jones on 9/26/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

// TODO: Allow notes to be edited?
// TODO: Might be nice to allow user to support program snapshots. Would need to be able
// to create these, delete them, and load them. Would need a warning when loading.
struct EditProgramView: View {
    @State var name: String
    @State var selection: Workout? = nil
    @State var showEditActions = false
    @State var showAdd = false
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display) {
        self._name = State(initialValue: display.program.name)
        self.display = display
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
                    .disableAutocorrection(false)
                    .onChange(of: self.name, perform: self.onEditedName)
            }.padding()

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
                Button("Add", action: onAdd).font(.callout)
                Button("OK", action: onOK).font(.callout).disabled(self.display.hasError)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .sheet(isPresented: self.$showAdd) {
            OldEditTextView(title: "Workout Name", content: "", completion: self.doAdd)}
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
        buttons.append(.default(Text("Delete Workout"), action: self.doDelete))

        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }

    func onAdd() {
        self.showAdd = true
    }

    func doAdd(_ name: String) {
//        if let err = self.program.addWorkout(name) {
//            self.errText = err
//        } else {
//            self.errText = ""
//            self.refresh()
//        }
    }
    
    private func onToggleEnabled() {
        self.display.send(.EnableWorkout(self.selection!, !self.selection!.enabled))
    }

    private func doDelete() {
        self.display.send(.DelWorkout(self.selection!))
    }

    private func doMove(by: Int) {
        self.display.send(.MoveWorkout(self.selection!, by))
    }

    func onEditedName(_ text: String) {
        self.display.send(.SetProgramName(text))
    }
    
    func onCancel() {
        self.display.send(.RollbackTransaction(name: "edit program"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.display.send(.ConfirmTransaction(name: "edit program"))
        self.presentationMode.wrappedValue.dismiss()   
    }
}

struct EditProgramView_Previews: PreviewProvider {
    static var previews: some View {
        EditProgramView(previewDisplay())
    }
}

