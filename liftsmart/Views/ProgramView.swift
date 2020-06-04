//  Created by Jesse Jones on 5/30/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ProgramView: View {
    var program: Program
    
    var body: some View {
        NavigationView {
            List(0..<program.count) { i in
                NavigationLink(destination: WorkoutView(workout: self.program[i])) {
                    Text(self.program[i].name)
                    // TODO: need to have a sublabel with when the workout was last done
                }
            }
            .navigationBarTitle(Text(program.name))
        }
        // TODO: have a text view saying how long this program has been run for
        // and also how many times the user has worked out
    }
}

struct ProgramView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramView(program: program)
    }
}
