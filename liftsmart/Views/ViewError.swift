//  Created by Jesse Jones on 2/15/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import Foundation
import SwiftUI

// This is used to avoid losing UI errors as the user switches context. For example if there are A and B text fields
// and each has validation upon changes then without this class the user could have an error on editing A that is
// lost if the user switches to B without fixing the problem.
class ViewError {
    // Two stage initialization because of the awkward way views are initalized.
    func set(_ message: Binding<String>, _ color: Binding<Color>) {
        self.message = message
        self.color = color
    }
    
    func add(key: String, error inMesg: String) {
        assert(!key.isEmpty)
        assert(!inMesg.isEmpty)
        
        var mesg = inMesg
        if !mesg.hasSuffix(".") {
            mesg += "."
        }
        
        errors[key] = mesg
        warnings[key] = nil
        
        // In order for the UI to update properly we need to make changes to a binding that
        // is directly used by a view.
        if self.message != nil {
            self.message!.wrappedValue = getMessage()   // TODO: could skip this if inMesg didn't change
            self.color!.wrappedValue = !errors.isEmpty ? Color.red : Color.orange
        }
    }
    
    func add(key: String, warning inMesg: String) {
        assert(!key.isEmpty)
        assert(!inMesg.isEmpty)
        
        var mesg = inMesg
        if !mesg.hasSuffix(".") {
            mesg += "."
        }
        
        errors[key] = nil
        warnings[key] = mesg
        
        if self.message != nil {
            self.message!.wrappedValue = getMessage()
            self.color!.wrappedValue = !errors.isEmpty ? Color.red : Color.orange
        }
    }
    
    func reset(key: String) {
        assert(!key.isEmpty)

        errors[key] = nil
        warnings[key] = nil
        
        if self.message != nil {
            self.message!.wrappedValue = getMessage()
            self.color!.wrappedValue = !errors.isEmpty ? Color.red : Color.orange
        }
    }
    
    var isEmpty: Bool {
        get {
            return errors.isEmpty && warnings.isEmpty
        }
    }

    private func getMessage() -> String {
        var result = ""
        
        var keys = errors.keys.sorted() // allows callers some control over which errors are reported first
        for key in keys {
            if !result.isEmpty {
                result += " "
            }
            result += errors[key]!
        }
        
        keys = warnings.keys.sorted()
        for key in keys {
            if !result.isEmpty {
                result += " "
            }
            result += warnings[key]!
        }
        
        return result
    }

    private var message: Binding<String>? = nil
    private var color: Binding<Color>? = nil
    
    private var errors: [String: String] = [:]
    private var warnings: [String: String] = [:]
}
