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
    let originalName: String
    @State var name: String
    @State var showEditActions: Bool = false
    @State var showSheet: Bool = false
    @State var showAlert: Bool = false
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
                    .disableAutocorrection(false)
                    .onChange(of: self.name, perform: self.onEditedName)
            }.padding()

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
            Spacer()
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("Add", action: onAdd).font(.callout) // TODO: also need Add Extra/Magnet
                Button("OK", action: onOK).font(.callout).disabled(self.display.hasError)
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .sheet(isPresented: self.$showSheet) {
            EditTextView(self.display, title: "Weight", content: "", type: .decimalPad, validator: self.onValidWeight, sender: self.onAddWeight)}
        .alert(isPresented: $showAlert) {   // and views can only have one alert
            return Alert(
                title: Text("Confirm delete"),
                primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                secondaryButton: .default(Text("Cancel")))
            }
    }

    private func getEntries() -> [ListEntry] {
        let weights = display.fixedWeights[self.originalName]?.weights ?? []
        return weights.mapi {ListEntry(friendlyUnitsWeight($1), .black, $0)}
    }
    
    private func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.destructive(Text("Delete"), action: self.onDelete))
        buttons.append(.default(Text("Edit"), action: self.onEdit))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    private func onEditedName(_ text: String) {
        self.display.send(.ValidateFixedWeightSetName(self.originalName, text))
    }
    
    func doDelete() {
        self.display.send(.DeleteFixedWeight(self.originalName, self.selection!.index))
    }
    
    func onDelete() {
        self.showAlert = true
    }
    
    // TODO: do something here, probably want to implement add first
    func onEdit() {
    }

    func onValidWeight(_ str: String) -> Action {
        return .ValidateFixedWeight(self.originalName, str)
    }
    
    func onAddWeight(_ str: String) -> Action {
        return .AddFixedWeight(self.originalName, Double(str)!)
    }

    func onAdd() {
        self.showSheet = true
    }

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "edit fws"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        if self.name != self.originalName {
            let weights = self.display.fixedWeights[self.originalName]?.weights ?? []
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

