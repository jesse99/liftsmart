//  Created by Jesse Jones on 2/21/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

/// Used to edit the list of FixedWeightSet's.
struct EditFWSsView: View {
    var exercise: Exercise
    @State var showEditActions: Bool = false
    @State var selection: ListEntry? = nil
    @State var showSheet: Bool = false
    @State var showAlert: Bool = false
    @State var alertMesg: String = ""
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ exercise: Exercise) {
        self.display = display
        self.exercise = exercise
        self.display.send(.BeginTransaction(name: "change fixed weight sets"))
    }

    var body: some View {
        VStack() {
            Text("Fixed Weight Sets" + self.display.edited).font(.largeTitle)

            List(self.getEntries()) {entry in
                VStack() {
                    Text(entry.name).foregroundColor(entry.color).font(.headline)
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {
                        self.selection = entry
                        self.showEditActions = true
                    }
            }
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: self.onAdd).font(.callout)
                Button("OK", action: onOK).font(.callout).disabled(self.display.hasError)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .sheet(isPresented: self.$showSheet) {
            EditTextView(self.display, title: "Name", content: "", validator: self.onValidName, sender: self.onAdded)}
        .alert(isPresented: $showAlert) {   // and views can only have one alert
            return Alert(
                title: Text("Confirm delete"),
                message: Text(self.alertMesg),
                primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                secondaryButton: .default(Text("Cancel")))
            }
    }
    
    func getEntries() -> [ListEntry] {
        let names = Array(self.display.fixedWeights.keys).sorted()
        if let name = name() {
            return names.mapi {ListEntry($1, $1 == name ? .blue : .black, $0)}
        } else {
            return names.mapi {ListEntry($1, .black, $0)}
        }
    }

    func name() -> String? {
        switch self.exercise.modality.apparatus {
        case .fixedWeights(name: let name):
            return name
        default:
            assert(false)
            return nil
        }
    }
    
    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if let name = name(), name == self.selection!.name {
            buttons.append(.default(Text("Deactivate"), action: self.onDeactivate))
        } else {
            buttons.append(.default(Text("Activate"), action: self.onActivate))
        }
        buttons.append(.destructive(Text("Delete"), action: self.onDelete))
        buttons.append(.default(Text("Edit"), action: self.onEdit))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    func onActivate() {
        self.display.send(.ActivateFixedWeightSet(self.selection!.name, self.exercise))
    }
    
    func onDeactivate() {
        self.display.send(.DeactivateFixedWeightSet(self.exercise))
    }
    
    func doDelete() {
        self.display.send(.DeleteFixedWeightSet(self.selection!.name))
    }
    
    func onDelete() {
        func findUses(_ name: String) -> [String] {
            var uses: [String] = []
            
            for workout in programX.workouts {
                for exercise in workout.exercises {
                    switch exercise.modality.apparatus {
                    case .fixedWeights(name: let n):
                        if n == name {
                            uses.append(exercise.name)
                        }
                    default:
                        break
                    }
                }
            }
            
            return uses.sorted()
        }
        
        self.showAlert = true
        
        let name = self.selection!.name
        let uses = findUses(name)
        if uses.count == 0 {
            self.alertMesg = "\(name) isn't being used"
        } else if uses.count == 1 {
            self.alertMesg = "\(name) is used by \(uses[0])"
        } else if uses.count == 2 {
            self.alertMesg = "\(name) is used by \(uses[0]) and \(uses[1])"
        } else if uses.count > 2 {
            self.alertMesg = "\(name) is used by \(uses[0]), \(uses[1]), ..."
        }
    }
    
    // TODO: implement this
    func onEdit() {
//        self.refresh()
    }

    func onValidName(_ name: String) -> Action {
        return .ValidateFixedWeightSetName(name)
    }
    
    func onAdded(_ name: String) -> Action {
        return .AddFixedWeightSet(name)
    }

    func onAdd() {
        self.showSheet = true
    }

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "change fixed weight sets"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.display.send(.ConfirmTransaction(name: "change fixed weight sets"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditFWSsView_Previews: PreviewProvider {
    static let display = previewDisplay()
    static let workout = display.program.workouts[1]
    static let exercise = workout.exercises.first(where: {$0.name == "Split Squat"})!

    static var previews: some View {
        EditFWSsView(display, exercise)
    }
}
