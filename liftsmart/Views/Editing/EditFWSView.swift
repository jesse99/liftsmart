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
    enum ActiveAlert {case deleteSelected, deleteAll}

    let originalName: String
    @State var name: String
    @State var showEditActions = false
    @State var showAdd = false
    @State var showEdit = false
    @State var showAlert = false
    @State var alertAction: HistoryView.ActiveAlert = .deleteSelected
    @State var selection: ListEntry? = nil
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ name: String) {
        self.display = display
        self.originalName = name
        self._name = State(initialValue: name)
        self.display.send(.BeginTransaction(name: "edit fws"))
    }

    var body: some View {
        VStack() {
            Text("Fixed Weights\(self.display.edited)").font(.largeTitle)

            HStack {
                Text("Name:").font(.headline)
                TextField("", text: self.$name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .autocapitalization(.words)
                    .disableAutocorrection(false)
                    .onChange(of: self.name, perform: self.onEditedName)
            }.padding(.leading).padding(.trailing)
            Divider().background(Color.black)

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
            .sheet(isPresented: self.$showEdit) {EditTextView(self.display, title: "\(self.name) Weight", content: friendlyWeight(self.display.fixedWeights[self.originalName]![self.selection!.index]), validator: self.onValidWeight, sender: self.onEditedWeight)}
            Spacer()
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)

            Divider()
            HStack {
                // TODO: also need Add Extra/Magnet
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: onAdd)
                    .font(.callout)
                    .sheet(isPresented: self.$showAdd) {AddFixedWeightsView(self.display, self.originalName)}
                Button("OK", action: onOK).font(.callout).disabled(self.display.hasError)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .alert(isPresented: $showAlert) {   // and views can only have one alert
            if self.alertAction == .deleteSelected {
                return Alert(
                    title: Text("Confirn delete"),
                    message: Text(self.selection!.name),
                    primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                    secondaryButton: .default(Text("Cancel")))
            } else {
                return Alert(
                    title: Text("Confirm delete all"),
                    message: Text("\(self.display.fixedWeights[self.originalName]!.count) weights"),
                    primaryButton: .destructive(Text("Delete")) {self.doDeleteAll()},
                    secondaryButton: .default(Text("Cancel")))
            }}
    }

    private func getEntries() -> [ListEntry] {
        let weights = display.fixedWeights[self.originalName] ?? FixedWeightSet()
        return weights.mapi {ListEntry(friendlyUnitsWeight($1), .black, $0)}
    }
    
    private func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.destructive(Text("Delete"), action: self.onDelete))
        buttons.append(.destructive(Text("Delete All"), action: self.onDeleteAll))
        buttons.append(.default(Text("Edit"), action: self.onEdit))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    private func onEditedName(_ text: String) {
        self.display.send(.ValidateFixedWeightSetName(self.originalName, text))
    }

    func onValidWeight(_ text: String) -> Action {
        if let newWeight = Double(text) {
            let originalWeight = self.display.fixedWeights[self.originalName]![self.selection!.index]
            if abs(newWeight - originalWeight) <= 0.01 {
                return .ValidateWeight("3435534", "weight") // bit of a hack but we need to clear the error key
            }
        }
        
        return .ValidateWeight(text, "weight")
    }
    
    func onEditedWeight(_ text: String) -> Action {
        let newWeight = Double(text)!
        let originalWeight = self.display.fixedWeights[self.originalName]![self.selection!.index]
        if abs(newWeight - originalWeight) <= 0.01 {
            return .NoOp
        }
        
        self.display.send(.DeleteFixedWeight(self.originalName, self.selection!.index), updateUI: false)
        return .AddFixedWeight(self.originalName, newWeight)
    }

    func doDelete() {
        self.display.send(.DeleteFixedWeight(self.originalName, self.selection!.index))
    }
    
    func doDeleteAll() {
        self.display.send(.SetFixedWeightSet(self.originalName, FixedWeightSet()))
    }
    
    func onDelete() {
        self.showAlert = true
        self.alertAction = .deleteSelected
    }
    
    func onDeleteAll() {
        self.showAlert = true
        self.alertAction = .deleteAll
    }
    
    func onEdit() {
        self.showEdit = true
    }

    func onAdd() {
        self.showAdd = true
    }

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "edit fws"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        if self.name != self.originalName {
            let weights = self.display.fixedWeights[self.originalName] ?? FixedWeightSet()
            self.display.send(.DeleteFixedWeightSet(self.originalName))
            self.display.send(.SetFixedWeightSet(self.name, weights))
        }

        self.display.send(.ConfirmTransaction(name: "edit fws"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditFWSView_Previews: PreviewProvider {
    static let display = previewDisplay()

    static var previews: some View {
        EditFWSView(display, "Dumbbells")
    }
}

