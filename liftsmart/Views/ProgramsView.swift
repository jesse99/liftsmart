//  Created by Jesse Jones on 4/17/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

/// Used to manage saved programs.
struct ProgramsView: View {
    @State var showEditActions = false
    @State var showAdd = false
    @State var showRename = false
    @State var showAlert = false
    @State var selection: ListEntry? = nil
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode
    
    init(_ display: Display) {
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
            .sheet(isPresented: self.$showRename) {EditTextView(self.display, title: "Rename \(self.selection!.name)", content: "", validator: self.onValidRename, sender: self.onRename)}
            Spacer()
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)

            Divider()
            HStack {
                Spacer()
                Button("Add", action: onAdd)
                    .font(.callout)
                    .sheet(isPresented: self.$showAdd) {EditTextView(self.display, title: "Add Program", content: "", validator: self.onValidNewName, sender: self.onNew)}
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
        let names = Array(self.display.programs.keys).sorted()
        return names.mapi {ListEntry($1, $1 == self.display.program.name ? .blue : .black, $0)}
    }
    
    private func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []

        if self.selection!.name != self.display.program.name {
            buttons.append(.default(Text("Activate"), action: self.onActivate))
            buttons.append(.destructive(Text("Delete"), action: self.onDelete))
        }
        buttons.append(.default(Text("Rename"), action: self.onRename))
        buttons.append(.cancel(Text("Cancel"), action: {}))

        return buttons
    }
    
    func onActivate() {
        self.display.send(.ActivateProgram(self.selection!.name))
    }
    
    func onDelete() {
        self.showAlert = true
    }
    
    func doDelete() {
        self.display.send(.DeleteProgram(self.selection!.name))
    }
    
    func onRename() {
        self.showRename = true
    }

    func onAdd() {
        self.showAdd = true
    }

    private func onValidRename(_ newName: String) -> Action {
        return .ValidateProgramName(self.display.program.name, newName)
    }

    private func onRename(_ newName: String) -> Action {
        if newName != self.selection!.name {
            return .RenameProgram(self.selection!.name, newName)
        } else {
            return .NoOp
        }
    }
    
    private func onValidNewName(_ name: String) -> Action {
        return .ValidateProgramName("", name)
    }

    private func onNew(_ name: String) -> Action {
        let program = defaultProgram(name)
        return .AddProgram(program)
    }
}

struct ProgramsView_Previews: PreviewProvider {
    static let display = previewDisplay()

    static var previews: some View {
        ProgramsView(display)
    }
}

