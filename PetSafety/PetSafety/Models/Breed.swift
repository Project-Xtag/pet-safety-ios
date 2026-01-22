import Foundation

/// Breed data for autocomplete in pet registration
struct Breed: Identifiable, Hashable {
    let id: String
    let name: String
    let species: String
}

/// Breed data matching backend /api/breeds endpoint
struct BreedData {
    /// All dog breeds (50 most popular)
    static let dogBreeds: [Breed] = [
        Breed(id: "dog-labrador-retriever", name: "Labrador Retriever", species: "dog"),
        Breed(id: "dog-german-shepherd", name: "German Shepherd", species: "dog"),
        Breed(id: "dog-golden-retriever", name: "Golden Retriever", species: "dog"),
        Breed(id: "dog-french-bulldog", name: "French Bulldog", species: "dog"),
        Breed(id: "dog-bulldog", name: "Bulldog", species: "dog"),
        Breed(id: "dog-poodle", name: "Poodle", species: "dog"),
        Breed(id: "dog-beagle", name: "Beagle", species: "dog"),
        Breed(id: "dog-rottweiler", name: "Rottweiler", species: "dog"),
        Breed(id: "dog-german-shorthaired-pointer", name: "German Shorthaired Pointer", species: "dog"),
        Breed(id: "dog-dachshund", name: "Dachshund", species: "dog"),
        Breed(id: "dog-pembroke-welsh-corgi", name: "Pembroke Welsh Corgi", species: "dog"),
        Breed(id: "dog-australian-shepherd", name: "Australian Shepherd", species: "dog"),
        Breed(id: "dog-yorkshire-terrier", name: "Yorkshire Terrier", species: "dog"),
        Breed(id: "dog-boxer", name: "Boxer", species: "dog"),
        Breed(id: "dog-cavalier-king-charles-spaniel", name: "Cavalier King Charles Spaniel", species: "dog"),
        Breed(id: "dog-doberman-pinscher", name: "Doberman Pinscher", species: "dog"),
        Breed(id: "dog-great-dane", name: "Great Dane", species: "dog"),
        Breed(id: "dog-miniature-schnauzer", name: "Miniature Schnauzer", species: "dog"),
        Breed(id: "dog-siberian-husky", name: "Siberian Husky", species: "dog"),
        Breed(id: "dog-shih-tzu", name: "Shih Tzu", species: "dog"),
        Breed(id: "dog-boston-terrier", name: "Boston Terrier", species: "dog"),
        Breed(id: "dog-bernese-mountain-dog", name: "Bernese Mountain Dog", species: "dog"),
        Breed(id: "dog-pomeranian", name: "Pomeranian", species: "dog"),
        Breed(id: "dog-havanese", name: "Havanese", species: "dog"),
        Breed(id: "dog-shetland-sheepdog", name: "Shetland Sheepdog", species: "dog"),
        Breed(id: "dog-brittany", name: "Brittany", species: "dog"),
        Breed(id: "dog-english-springer-spaniel", name: "English Springer Spaniel", species: "dog"),
        Breed(id: "dog-cocker-spaniel", name: "Cocker Spaniel", species: "dog"),
        Breed(id: "dog-miniature-american-shepherd", name: "Miniature American Shepherd", species: "dog"),
        Breed(id: "dog-border-collie", name: "Border Collie", species: "dog"),
        Breed(id: "dog-vizsla", name: "Vizsla", species: "dog"),
        Breed(id: "dog-pug", name: "Pug", species: "dog"),
        Breed(id: "dog-weimaraner", name: "Weimaraner", species: "dog"),
        Breed(id: "dog-basset-hound", name: "Basset Hound", species: "dog"),
        Breed(id: "dog-mastiff", name: "Mastiff", species: "dog"),
        Breed(id: "dog-chihuahua", name: "Chihuahua", species: "dog"),
        Breed(id: "dog-collie", name: "Collie", species: "dog"),
        Breed(id: "dog-maltese", name: "Maltese", species: "dog"),
        Breed(id: "dog-newfoundland", name: "Newfoundland", species: "dog"),
        Breed(id: "dog-rhodesian-ridgeback", name: "Rhodesian Ridgeback", species: "dog"),
        Breed(id: "dog-west-highland-white-terrier", name: "West Highland White Terrier", species: "dog"),
        Breed(id: "dog-belgian-malinois", name: "Belgian Malinois", species: "dog"),
        Breed(id: "dog-bichon-frise", name: "Bichon Frise", species: "dog"),
        Breed(id: "dog-bloodhound", name: "Bloodhound", species: "dog"),
        Breed(id: "dog-akita", name: "Akita", species: "dog"),
        Breed(id: "dog-portuguese-water-dog", name: "Portuguese Water Dog", species: "dog"),
        Breed(id: "dog-st-bernard", name: "St. Bernard", species: "dog"),
        Breed(id: "dog-papillon", name: "Papillon", species: "dog"),
        Breed(id: "dog-australian-cattle-dog", name: "Australian Cattle Dog", species: "dog"),
        Breed(id: "dog-scottish-terrier", name: "Scottish Terrier", species: "dog"),
    ]

    /// All cat breeds (50 most popular)
    static let catBreeds: [Breed] = [
        Breed(id: "cat-domestic-shorthair", name: "Domestic Shorthair", species: "cat"),
        Breed(id: "cat-domestic-longhair", name: "Domestic Longhair", species: "cat"),
        Breed(id: "cat-siamese", name: "Siamese", species: "cat"),
        Breed(id: "cat-persian", name: "Persian", species: "cat"),
        Breed(id: "cat-maine-coon", name: "Maine Coon", species: "cat"),
        Breed(id: "cat-ragdoll", name: "Ragdoll", species: "cat"),
        Breed(id: "cat-bengal", name: "Bengal", species: "cat"),
        Breed(id: "cat-abyssinian", name: "Abyssinian", species: "cat"),
        Breed(id: "cat-british-shorthair", name: "British Shorthair", species: "cat"),
        Breed(id: "cat-sphynx", name: "Sphynx", species: "cat"),
        Breed(id: "cat-scottish-fold", name: "Scottish Fold", species: "cat"),
        Breed(id: "cat-birman", name: "Birman", species: "cat"),
        Breed(id: "cat-russian-blue", name: "Russian Blue", species: "cat"),
        Breed(id: "cat-oriental-shorthair", name: "Oriental Shorthair", species: "cat"),
        Breed(id: "cat-devon-rex", name: "Devon Rex", species: "cat"),
        Breed(id: "cat-himalayan", name: "Himalayan", species: "cat"),
        Breed(id: "cat-american-shorthair", name: "American Shorthair", species: "cat"),
        Breed(id: "cat-norwegian-forest-cat", name: "Norwegian Forest Cat", species: "cat"),
        Breed(id: "cat-exotic-shorthair", name: "Exotic Shorthair", species: "cat"),
        Breed(id: "cat-burmese", name: "Burmese", species: "cat"),
        Breed(id: "cat-tonkinese", name: "Tonkinese", species: "cat"),
        Breed(id: "cat-cornish-rex", name: "Cornish Rex", species: "cat"),
        Breed(id: "cat-somali", name: "Somali", species: "cat"),
        Breed(id: "cat-turkish-angora", name: "Turkish Angora", species: "cat"),
        Breed(id: "cat-balinese", name: "Balinese", species: "cat"),
        Breed(id: "cat-siberian", name: "Siberian", species: "cat"),
        Breed(id: "cat-manx", name: "Manx", species: "cat"),
        Breed(id: "cat-bombay", name: "Bombay", species: "cat"),
        Breed(id: "cat-egyptian-mau", name: "Egyptian Mau", species: "cat"),
        Breed(id: "cat-ocicat", name: "Ocicat", species: "cat"),
        Breed(id: "cat-japanese-bobtail", name: "Japanese Bobtail", species: "cat"),
        Breed(id: "cat-chartreux", name: "Chartreux", species: "cat"),
        Breed(id: "cat-korat", name: "Korat", species: "cat"),
        Breed(id: "cat-turkish-van", name: "Turkish Van", species: "cat"),
        Breed(id: "cat-singapura", name: "Singapura", species: "cat"),
        Breed(id: "cat-american-curl", name: "American Curl", species: "cat"),
        Breed(id: "cat-ragamuffin", name: "RagaMuffin", species: "cat"),
        Breed(id: "cat-havana-brown", name: "Havana Brown", species: "cat"),
        Breed(id: "cat-selkirk-rex", name: "Selkirk Rex", species: "cat"),
        Breed(id: "cat-laperm", name: "LaPerm", species: "cat"),
        Breed(id: "cat-nebelung", name: "Nebelung", species: "cat"),
        Breed(id: "cat-pixie-bob", name: "Pixie-Bob", species: "cat"),
        Breed(id: "cat-american-bobtail", name: "American Bobtail", species: "cat"),
        Breed(id: "cat-cymric", name: "Cymric", species: "cat"),
        Breed(id: "cat-european-burmese", name: "European Burmese", species: "cat"),
        Breed(id: "cat-american-wirehair", name: "American Wirehair", species: "cat"),
        Breed(id: "cat-snowshoe", name: "Snowshoe", species: "cat"),
        Breed(id: "cat-chausie", name: "Chausie", species: "cat"),
        Breed(id: "cat-savannah", name: "Savannah", species: "cat"),
        Breed(id: "cat-toyger", name: "Toyger", species: "cat"),
    ]

    /// Get breeds for a specific species
    static func breeds(for species: String) -> [Breed] {
        switch species.lowercased() {
        case "dog":
            return dogBreeds
        case "cat":
            return catBreeds
        default:
            return []
        }
    }

    /// Search breeds by name with optional species filter
    static func search(_ query: String, species: String? = nil) -> [Breed] {
        let lowercasedQuery = query.lowercased()
        let breedsToSearch: [Breed]

        if let species = species {
            breedsToSearch = breeds(for: species)
        } else {
            breedsToSearch = dogBreeds + catBreeds
        }

        return breedsToSearch.filter { breed in
            breed.name.lowercased().contains(lowercasedQuery)
        }
    }
}
