//  Created by Jesse Jones on 9/26/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

// TODO: Allow notes to be edited?
// TODO: Might be nice to allow user to support program snapshots. Would need to be able
// to create these, delete them, and load them. Would need a warning when loading.
struct EditProgramView: View {
    @State var name = ""
    @State var selection: Workout? = nil
    @State var showEditActions = false
    @State var showSheet = false
    @EnvironmentObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init() {
        self.display.send(.BeginTransaction(name: "edit program"))
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
                    .onChange(of: self.name, perform: self.onEditedName)
            }.padding()

            List(self.display.program.workouts) {workout in
                VStack(alignment: .leading) {
                    Text(workout.name).foregroundColor(.black).font(.headline)
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
            .onAppear {self.refresh()}
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .sheet(isPresented: self.$showSheet) {
            EditTextView(title: "Workout Name", content: "", completion: self.doAdd)}
    }

    func refresh() {
        self.name = self.display.program.name
    }

    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if self.display.program.workouts.first !== self.selection {
            buttons.append(.default(Text("Move Up"), action: {self.doMove(by: -1); self.refresh()}))
        }
        if self.display.program.workouts.last !== self.selection {
            buttons.append(.default(Text("Move Down"), action: {self.doMove(by: 1); self.refresh()}))
        }
        if self.selection!.enabled {
            buttons.append(.default(Text("Disable Workout"), action: {self.onToggleEnabled()}))
        } else {
            buttons.append(.default(Text("Enable Workout"), action: {self.onToggleEnabled()}))
        }
        buttons.append(.default(Text("Delete Workout"), action: {self.doDelete(); self.refresh()}))

        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }

    func onAdd() {
        self.showSheet = true
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
//        self.program[self.editIndex].enabled = !self.program[self.editIndex].enabled
//        self.refresh()
    }

    private func doDelete() {
//        self.program.delete(self.editIndex)
//        self.refresh()
    }

    private func doMove(by: Int) {
//        self.program.moveWorkout(self.editIndex, by: by)
//        self.refresh()
    }

    func onEditedName(_ text: String) {
        self.program.name = self.name
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
        EditProgramView().environmentObject(previewDisplay())
    }
}

