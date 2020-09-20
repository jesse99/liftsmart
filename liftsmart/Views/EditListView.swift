//  Created by Jesse Jones on 9/12/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

var listID: Int = 0

struct ListEntry: Identifiable {
    let name: String
    let id: Int
    let index: Int      // can't use this as an index because ids should change when entries change

    init(_ name: String, _ index: Int) {
        self.name = name
        self.id = listID
        self.index = index
        
        listID += 1
    }
}

/// Allows the user to edit sequences of arbitrary objects.
struct EditListView: View {
    typealias NamesFn = () -> [String]
    typealias AddFn = (String) -> String?   // returns an error message if the add failed
    typealias DeleteFn = (Int) -> Void
    typealias MoveDownFn = (Int) -> Void
    typealias MoveUpFn = (Int) -> Void
    
    @State var entries: [ListEntry] = []
    @State var errText = ""
    @State var showEditActions: Bool = false
    @State var editIndex: Int = 0
    @State var showSheet: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    let title: String
    var names: NamesFn
    var add: AddFn?
    var delete: DeleteFn?
    var moveDown: MoveDownFn?
    var moveUp: MoveUpFn?
    var addPrompt = "Entry"
    
    // TODO: have an optional red error message label at the bottom
    var body: some View {
        VStack {
            Text(self.title).font(.largeTitle)
            
            List(self.entries) {entry in
                VStack(alignment: .leading) {
                    if entry.id == self.entries.last!.id && self.add != nil {
                        Text(entry.name).font(.headline).italic()
                    } else {
                        Text(entry.name).font(.headline)
                    }
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {self.showEditActions = true; self.editIndex = entry.index}
            }
            Text(self.errText).foregroundColor(.red).font(.callout)

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
            EditTextView(title: "Edit \(self.addPrompt)", content: "", completion: self.onDoAdd)
        }
    }

    func refresh() {
        self.entries = self.names().mapi({ListEntry($1, $0)})
        if self.add != nil {
            self.entries.append(ListEntry("Add", self.entries.count))
        }
    }
    
    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        if self.add != nil && self.editIndex == self.entries.count - 1 {
            buttons.append(.default(Text("New \(addPrompt)"), action: {self.onAdd()}))
        } else {
            let len = self.add != nil ? self.entries.count - 1 : self.entries.count
            
            if let move = self.moveUp, self.editIndex != 0 && len > 1 {
                buttons.append(.default(Text("Move Up"), action: {move(self.editIndex); self.refresh()}))
            }
            if let move = self.moveDown, self.editIndex < len - 1 && len > 1 {
                buttons.append(.default(Text("Move Down"), action: {move(self.editIndex); self.refresh()}))
            }
            if let delete = self.delete {
                buttons.append(.default(Text("Delete"), action: {delete(self.editIndex); self.refresh()}))
            }
        }
        
        buttons.append(.cancel(Text("Cancel"), action: {}))
        
        return buttons
    }
    
    func onAdd() {
        self.showSheet = true
    }
    
    func onDoAdd(_ name: String) {
        if let err = self.add!(name) {
            self.errText = err
        } else {
            self.errText = ""
            self.refresh()
        }
    }

    func onCancel() {
        // TODO: call a cancel callback
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditListView_Previews: PreviewProvider {
    static var names = ["Alpha", "Beta", "Gamma"]
    
    static var previews: some View {
        EditListView(title: "Workouts", names: onNames, add: onAdd, delete: onDelete, addPrompt: "Workout")
    }
    
    static func onNames() -> [String] {
        return names
    }
    
    static func onDelete(_ index: Int) {
        names.remove(at: index)
    }

    static func onAdd(_ name: String) -> String? {
        if names.contains(name) {
            return "\(name) already exists."
        } else {
            names.append(name)
            return nil
        }
    }
}
