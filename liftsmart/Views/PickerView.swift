//  Created by Jesse Jones on 11/1/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

var pickerId = 0

struct PickerEntry: Identifiable {
    let name: String
    let id: Int

    init(_ name: String) {
        self.name = name
        self.id = pickerId
        pickerId += 1
    }
}

/// View with a text field and a list. List is populated with items that match the list. User can select an item
/// from the list which then sets the text field (and re-populates the list).
struct PickerView: View {
    typealias Populate = (String) -> [String]
    typealias Confirm = (String) -> Void

    let title: String
    let prompt: String
    let initial: String
    let populate: Populate
    let confirm: Confirm
    @State var value = ""
    @State var entries: [PickerEntry] = []
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack() {
            Text(self.title).font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Text(self.prompt).font(.headline)
                    TextField("", text: self.$value)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .onChange(of: self.value, perform: self.onEditedText)
                }.padding(.leading)
            }
            Spacer()

            List(self.entries) {entry in
                VStack(alignment: .leading) {
                    Text(entry.name).font(.headline)
                }
                .contentShape(Rectangle())  // so we can click within spacer
                .onTapGesture {self.value = entry.name; self.refresh()}
            }

            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout)
            }.padding().onAppear {self.value = self.initial; self.refresh()}
        }
    }
    
    func refresh() {
        self.entries = self.populate(self.value).map({PickerEntry($0)})
    }

    func onEditedText(_ text: String) {
        refresh()
    }
    
    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func onOK() {
        self.confirm(self.value)
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct PickerView_Previews: PreviewProvider {
    static let breeds = ["Retrievers (Labrador)", "German Shepherd Dogs", "Retrievers (Golden)", "French Bulldogs", "Bulldogs", "Poodles", "Beagles", "Rottweilers", "Pointers (German Shorthaired)", "Pembroke Welsh Corgis", "Dachshunds", "Yorkshire Terriers", "Australian Shepherds", "Boxers", "Siberian Huskies", "Cavalier King Charles Spaniels", "Great Danes", "Miniature Schnauzers", "Doberman Pinschers", "Shih Tzu", "Boston Terriers", "Havanese", "Bernese Mountain Dogs", "Pomeranians", "Shetland Sheepdogs", "Brittanys", "Spaniels (English Springer)", "Spaniels (Cocker)", "Miniature American Shepherds", "Cane Corso", "Pugs", "Mastiffs", "Border Collies", "Vizslas", "Chihuahuas", "Maltese", "Basset Hounds", "Collies", "Weimaraners", "Newfoundlands", "Belgian Malinois", "Rhodesian Ridgebacks", "Bichons Frises", "West Highland White Terriers", "Shiba Inu", "Retrievers (Chesapeake Bay)", "Akitas", "St. Bernards", "Portuguese Water Dogs", "Spaniels (English Cocker)", "Bloodhounds", "Bullmastiffs", "Papillons", "Soft Coated Wheaten Terriers", "Australian Cattle Dogs", "Scottish Terriers", "Whippets", "Samoyeds", "Dalmatians", "Airedale Terriers", "Bull Terriers", "Wirehaired Pointing Griffons", "Pointers (German Wirehaired)", "Alaskan Malamutes", "Chinese Shar-Pei", "Cardigan Welsh Corgis", "Italian Greyhounds", "Dogues de Bordeaux", "Great Pyrenees", "Old English Sheepdogs", "Giant Schnauzers", "Cairn Terriers", "Greater Swiss Mountain Dogs", "Miniature Pinschers", "Russell Terriers", "Irish Wolfhounds", "Chow Chows", "Lhasa Apsos", "Setters (Irish)", "Chinese Crested", "Coton de Tulear", "Staffordshire Bull Terriers", "Pekingese", "Border Terriers", "American Staffordshire Terriers", "Retrievers (Nova Scotia Duck Tolling)", "Basenjis", "Keeshonden", "Spaniels (Boykin)", "Lagotti Romagnoli", "Rat Terriers", "Bouviers des Flandres", "Norwegian Elkhounds", "Anatolian Shepherd Dogs", "Leonbergers", "Brussels Griffons", "Standard Schnauzers", "Setters (English)", "Fox Terriers (Wire)", "Neapolitan Mastiffs", "Tibetan Terriers", "Norwich Terriers", "Belgian Tervuren", "Retrievers (Flat-Coated)", "Borzois", "Schipperkes", "Toy Fox Terriers", "Japanese Chin", "Silky Terriers", "Welsh Terriers", "Afghan Hounds", "Miniature Bull Terriers", "Setters (Gordon)", "Black Russian Terriers", "Pointers", "Spinoni Italiani", "Tibetan Spaniels", "Parson Russell Terriers", "Irish Terriers", "American Eskimo Dogs", "Beaucerons", "Fox Terriers (Smooth)", "German Pinschers", "American Hairless Terriers", "Salukis", "Belgian Sheepdogs", "Boerboels", "Tibetan Mastiffs", "Treeing Walker Coonhounds", "Spaniels (Welsh Springer)", "Norfolk Terriers", "Icelandic Sheepdogs", "Kerry Blue Terriers", "Spaniels (Clumber)", "Briards", "Bearded Collies", "Xoloitzcuintli", "Bluetick Coonhounds", "English Toy Spaniels", "Manchester Terriers", "Black and Tan Coonhounds", "Australian Terriers", "Redbone Coonhounds", "Spanish Water Dogs", "Wirehaired Vizslas", "Berger Picards", "Portuguese Podengo Pequenos", "Lakeland Terriers", "Scottish Deerhounds", "Affenpinschers", "Bedlington Terriers", "Petits Bassets Griffons Vendeens", "Spaniels (Field)", "Sealyham Terriers", "Setters (Irish Red and White)", "Pumik", "Nederlandse Kooikerhondjes", "Lowchen", "Swedish Vallhunds", "Pulik", "Pharaoh Hounds", "Greyhounds", "Retrievers (Curly-Coated)", "Spaniels (American Water)", "Finnish Lapphunds", "Kuvaszok", "Entlebucher Mountain Dogs", "Glen of Imaal Terriers", "Norwegian Buhunds", "Spaniels (Irish Water)", "Ibizan Hounds", "Otterhounds", "Polish Lowland Sheepdogs", "Dandie Dinmont Terriers", "American English Coonhounds", "Spaniels (Sussex)", "Plott Hounds", "Grand Basset Griffon Vendeens", "Canaan Dogs", "Bergamasco Sheepdogs", "Komondorok", "Pyrenean Shepherds", "Finnish Spitz", "Chinooks", "Cirnechi dell’Etna", "Harriers", "Skye Terriers", "Cesky Terriers", "American Foxhounds", "Azawakhs", "Sloughis", "Norwegian Lundehunds", "English Foxhounds"]
    
    static func populate(_ text: String) -> [String] {
        var names: [String] = []
        
        for candidate in breeds {
            if candidate.contains(text) {
                names.append(candidate)
            }
        }
        
        return names
    }
    
    static func onConfirm(_ text: String) {
    }
    
    static var previews: some View {
        PickerView(title: "Dog Breeds", prompt: "Breed: ", initial: "Terrier", populate: populate, confirm: onConfirm)
    }
}
