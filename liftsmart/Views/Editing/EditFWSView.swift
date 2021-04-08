//  Created by Jesse Jones on 2/28/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

var listEntryID: Int = 0

struct ListEntry: Identifiable {
    let name: String
    let color: Color
    let id: Int     // can't use this as an index because ids should change when entries change
    let index: Int

    init(_ name: String, _ color: Color, _ index: Int) {
        self.name = name
        self.color = color
        self.id = listEntryID
        self.index = index
        
        listEntryID += 1
    }
}

/// Used to edit a single FixedWeightSet.
struct EditFWSView: View {
    class Stateful {
        var name: String = ""
        var weights: [Double] = []
    }
    
    var exercise: Exercise
    let state: Stateful
    @State var entries: [ListEntry] = []
    @State var showEditActions: Bool = false
    @State var editIndex: Int = 0             // TODO: be sure to lose this
    @State var showSheet: Bool = false
    @State var showAlert: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ exercise: Exercise) {
        self.exercise = exercise
        self.state = Stateful()

        switch self.exercise.modality.apparatus {
        case .fixedWeights(name: let name):
            if let n = name {
                self.state.name = n
                self.state.weights = fixedWeights[n]!.weights.sorted()
            }
        default:
            assert(false)
        }
    }

    var body: some View {
        VStack() {
            Text("Fixed Weight Set").font(.largeTitle)

            // TODO: we need a Binding here so Stateful doesn't seem so great
//            HStack {
//                Text("Name:").font(.headline)
//                TextField("", text: self.$name)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .keyboardType(.default)
//                    .disableAutocorrection(false)
//                    .onChange(of: self.name, perform: self.onEditedName)
//            }.padding()

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
//        .sheet(isPresented: self.$showSheet) {
//            OldEditTextView(title: "Weight", content: "", type: .decimalPad, validator: self.onValidWeight, completion: self.onAddWeight)}
//            EditTextView(title: "Name", content: "", validator: self.onValidName, completion: self.onEditedName)}
        .alert(isPresented: $showAlert) {   // and views can only have one alert
            return Alert(
                title: Text("Confirm delete"),
                primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                secondaryButton: .default(Text("Cancel")))
            }
    }

    func refresh() {
        self.entries = self.state.weights.mapi {ListEntry(friendlyUnitsWeight($1), .black, $0)}
        self.entries.append(ListEntry("Add", .black, 9889))
    }
    
    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.default(Text("Delete"), action: self.onDelete))
        buttons.append(.default(Text("Edit"), action: self.onEdit))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    func doDelete() {
        self.state.weights.remove(at: self.editIndex)
        self.refresh()
    }
    
    func onDelete() {
        self.showAlert = true
    }
    
    // TODO: do something here, probably want to implement add first
    func onEdit() {
        self.refresh()
    }

    func onValidWeight(_ str: String) -> String? {
        if let weight = Double(str) {
            if weight <= 0.0 {
                return "Weight should be larger than zero"
            }
            
            if self.state.weights.contains(where: {abs(weight - $0) > 0.001}) {
                return "Weight already exists"
            }
        } else {
            return "Weight should be a floating point number"
        }
        
        return nil
    }
    
    func onAddWeight(_ str: String) {
        let weight = Double(str)!
        if let index = self.state.weights.firstIndex(where: {$0 > weight}) {
            self.state.weights.insert(weight, at: index)
        } else {
            self.state.weights.append(weight)
        }
        self.refresh()
    }

    func onValidName(_ name: String) -> String? {
        if name.isEmpty { // TODO: need to use isEmptyOrBlank
            return "Need a name"
        }
        
        switch self.exercise.modality.apparatus {
        case .fixedWeights(name: let oldN):
            if let oldName = oldN {
                if name == oldName {
                    return nil
                }
            }
        default:
            assert(false)
        }

        return fixedWeights[name] != nil ? "Name already exists" : nil
    }

    func onAdd() {
        self.showSheet = true
    }

    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        fixedWeights[self.state.name] = FixedWeightSet(self.state.weights)
        self.exercise.modality.apparatus = .fixedWeights(name: self.state.name)

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditFWSView_Previews: PreviewProvider {
    static var previews: some View {
        EditFWSView(bench())
    }
    
    static func bench() -> Exercise {
        fixedWeights["Dumbbells"] = FixedWeightSet([5.0, 20.0, 10.0, 15.0])
        fixedWeights["Kettlebells"] = FixedWeightSet([10.0, 20.0, 30.0])

        let warmup = RepsSet(reps: RepRange(4), percent: WeightPercent(0.0), restSecs: 90)
        let work = RepsSet(reps: RepRange(min: 4, max: 8), restSecs: 3*60)
        let sets = Sets.repRanges(warmups: [warmup], worksets: [work, work, work], backoffs: [])
        let modality = Modality(Apparatus.fixedWeights(name: "Dumbbells"), sets)
        return Exercise("Split Squat", "Body-weight Split Squat", modality, Expected(weight: 16.4, reps: [8, 8, 8]))
    }
}

