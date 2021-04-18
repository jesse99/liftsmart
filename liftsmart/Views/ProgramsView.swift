//  Created by Jesse Jones on 4/17/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

/// Used to edit saved programs.
struct ProgramsView: View {
    @State var showEditActions = false
    @State var showAdd = false
    @State var showRename = false
    @State var showAlert = false
    @State var selection: ListEntry? = nil
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display, _ name: String) {
        self.display = display
    }

    var body: some View {
        VStack() {
            Text("Programs\(self.display.edited)").font(.largeTitle)

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
//            .sheet(isPresented: self.$showRename) {EditTextView(self.display, title: "\(self.name) Weight", content: friendlyWeight(self.display.fixedWeights[self.originalName]!.weights[self.selection!.index]), validator: self.onValidWeight, sender: self.onEditedWeight)}
            Spacer()
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)

            Divider()
            HStack {
                Spacer()
                Button("Add", action: onAdd)
                    .font(.callout)
//                    .sheet(isPresented: self.$showAdd) {EditTextView(self.display, title: "\(self.name) Weight", content: friendlyWeight(self.display.fixedWeights[self.originalName]!.weights[self.selection!.index]), validator: self.onValidWeight, sender: self.onEditedWeight)}
            }
            .padding()
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.selection!.name), buttons: editButtons())}
        .alert(isPresented: $showAlert) {   // and views can only have one alert
                return Alert(
                    title: Text("Confirn delete"),
                    message: Text(self.selection!.name),
                    primaryButton: .destructive(Text("Delete")) {self.doDelete()},
                    secondaryButton: .default(Text("Cancel")))
            }
    }

    private func getEntries() -> [ListEntry] {
        return self.display.programs.keys.mapi {ListEntry($1, $1 == self.display.program.name ? .blue : .black, $0)}
    }
    
    private func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        buttons.append(.default(Text("Activate"), action: self.onActivate))
        buttons.append(.destructive(Text("Delete"), action: self.onDelete))
        buttons.append(.default(Text("Rename"), action: self.onRename))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
//    private func onEditedName(_ text: String) {
//        self.display.send(.ValidateFixedWeightSetName(self.originalName, text))
//    }
//
//    func onValidWeight(_ text: String) -> Action {
//        if let newWeight = Double(text) {
//            let originalWeight = self.display.fixedWeights[self.originalName]!.weights[self.selection!.index]
//            if abs(newWeight - originalWeight) <= 0.01 {
//                return .NoOp
//            }
//        }
//
//        return .ValidateWeight(text, "weight")
//    }
//
//    func onEditedWeight(_ text: String) -> Action {
//        let newWeight = Double(text)!
//        let originalWeight = self.display.fixedWeights[self.originalName]!.weights[self.selection!.index]
//        if abs(newWeight - originalWeight) <= 0.01 {
//            return .NoOp
//        }
//
//        self.display.send(.DeleteFixedWeight(self.originalName, self.selection!.index), updateUI: false)
//        return .AddFixedWeight(self.originalName, newWeight)
//    }

    func doDelete() {
//        self.display.send(.DeleteFixedWeight(self.originalName, self.selection!.index))
    }
    
    func onDelete() {
        self.showAlert = true
    }
    
    func onActivate() {
    }
    
    func onRename() {
        self.showRename = true
    }

    func onAdd() {
        self.showAdd = true
    }
}

struct ProgramsView_Previews: PreviewProvider {
    static let display = previewDisplay()

    static var previews: some View {
        ProgramsView(display, "Dumbbells")
    }
}

