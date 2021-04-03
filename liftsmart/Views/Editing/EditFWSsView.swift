//  Created by Jesse Jones on 2/21/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

var fixedWeights: [String: FixedWeightSet] = [:]

/// Used to edit the list of FixedWeightSet's.
struct EditFWSsView: View {
    var exercise: Exercise
    let oldExercise: Exercise
    let oldWeights: [String: FixedWeightSet]
    @State var entries: [ListEntry] = []
    @State var showEditActions: Bool = false
    @State var editIndex: Int = 0             // TODO: be sure to lose this
    @State var showSheet: Bool = false
    @State var showAlert: Bool = false
    @State var alertMesg: String = ""
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ exercise: Exercise) {
        self.exercise = exercise
        self.oldExercise = exercise.clone()
        self.oldWeights = fixedWeights
    }

    var body: some View {
        VStack() {
            Text("Fixed Weight Sets").font(.largeTitle)

            List(self.entries) {entry in
                VStack() {
                    if entry.index >= 9000 {
                        Text(entry.name).foregroundColor(entry.color).font(.headline).italic()
                    } else {
                        Text(entry.name).foregroundColor(entry.color).font(.headline)
                    }
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {
                        self.editIndex = entry.index
                        if entry.index == 9889 {
                            self.onAdd()
                        } else {
                            self.showEditActions = true
                        }
                    }
            }

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
            OldEditTextView(title: "Name", content: "", validator: self.onValidName, completion: self.onAdded)}
        .alert(isPresented: $showAlert) {   // and views can only have one alert
            return Alert(
                title: Text("Confirm delete"),
                message: Text(self.alertMesg),
                primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                secondaryButton: .default(Text("Cancel")))
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
    
    func refresh() {
        let names = Array(fixedWeights.keys).sorted()
        if let name = name() {
            self.entries = names.mapi {ListEntry($1, $1 == name ? .blue : .black, $0)}
        } else {
            self.entries = names.mapi {ListEntry($1, .black, $0)}
        }
        self.entries.append(ListEntry("Add", .black, 9889))
    }
    
    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if let name = name(), name == self.entries[self.editIndex].name {
            buttons.append(.default(Text("Deactivate"), action: self.onDeactivate))
        } else {
            buttons.append(.default(Text("Activate"), action: self.onActivate))
        }
        buttons.append(.default(Text("Delete"), action: self.onDelete))
        buttons.append(.default(Text("Edit"), action: self.onEdit))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    func onActivate() {
        let name = self.entries[self.editIndex].name
        self.exercise.modality.apparatus = .fixedWeights(name: name)
        self.refresh()
    }
    
    func onDeactivate() {
        self.exercise.modality.apparatus = .fixedWeights(name: nil)
        self.refresh()
    }
    
    func doDelete() {
        let name = self.entries[self.editIndex].name
        fixedWeights[name] = nil
        
        self.refresh()
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
        
        let name = self.entries[self.editIndex].name
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
    
    func onEdit() {
        self.refresh()
    }

    func onValidName(_ name: String) -> String? {
        if name.isEmpty { // TODO: need to use isEmptyOrBlank
            return "Need a name"
        }
        
        return fixedWeights[name] != nil ? "Name already exists" : nil
    }
    
    func onAdded(_ name: String) {
        fixedWeights[name] = FixedWeightSet([])
        self.refresh()
    }

    func onAdd() {
        self.showSheet = true
    }

    func onCancel() {
        self.exercise.restore(self.oldExercise)
        fixedWeights = self.oldWeights
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditFWSsView_Previews: PreviewProvider {
    static var previews: some View {
        EditFWSsView(bench())
    }
    
    static func bench() -> Exercise {
        fixedWeights["Dumbbells"] = FixedWeightSet([5.0, 10.0, 15.0, 20.0])
        fixedWeights["Kettlebells"] = FixedWeightSet([10.0, 20.0, 30.0])

        let warmup = RepsSet(reps: RepRange(4), percent: WeightPercent(0.0), restSecs: 90)
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 3*60)
        let sets = Sets.repRanges(warmups: [warmup], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.fixedWeights(name: "Dumbbells"), sets)
        return Exercise("Split Squat", "Body-weight Split Squat", modality, Expected(weight: 16.4, reps: [8, 8, 8]))
    }
}
