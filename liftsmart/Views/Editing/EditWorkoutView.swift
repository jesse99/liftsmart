//  Created by Jesse Jones on 9/26/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditWorkoutView: View {
    let workout: Workout
    @State var name = ""
//    @State var entries: [ListEntry] = []  
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack {
            Text("Edit Workout").font(.largeTitle)

            HStack {
                Text("Name:").font(.headline)
                TextField("", text: self.$name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .disableAutocorrection(false)
            }.padding()
            Spacer()

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
    }

    func refresh() {
        self.name = program.name
    }

    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.workout.name = self.name   // TODO: save changes
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        EditWorkoutView(workout: cardio())
    }
    
    private static func cardio() -> Workout {
        func burpees() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Burpees", "Burpees", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func squats() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Squats", "Body-weight Squat", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }

        return createWorkout("Cardio", [burpees(), squats()], day: nil).unwrap()
    }
}

