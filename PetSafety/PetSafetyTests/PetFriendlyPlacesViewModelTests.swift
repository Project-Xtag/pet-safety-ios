import Testing
import Foundation
@testable import PetSafety

/// Configurable `APIServiceProtocol` mock for the pet-friendly VMs. Only the 4
/// pet-friendly methods are exercised; the rest satisfy conformance by throwing.
@MainActor
final class MockPetFriendlyAPIService: APIServiceProtocol {
    var nearbyResult: Result<[PetFriendlyPlace], Error> = .success([])
    var placeResult: Result<PetFriendlyPlace, Error> = .failure(APIError.notFound("stub"))
    var createResult: Result<SubmittedPetFriendlyPlace, Error> = .failure(APIError.serverError("stub"))
    var mineResult: Result<[PetFriendlyPlace], Error> = .success([])
    private(set) var createdPayload: CreatePetFriendlyPlaceRequest?

    func getNearbyPetFriendlyPlaces(latitude: Double, longitude: Double, radiusKm: Double, category: PetFriendlyPlace.Category?, market: String) async throws -> [PetFriendlyPlace] {
        try nearbyResult.get()
    }
    func getPetFriendlyPlace(id: String, market: String) async throws -> PetFriendlyPlace {
        try placeResult.get()
    }
    func createPetFriendlyPlace(_ payload: CreatePetFriendlyPlaceRequest) async throws -> SubmittedPetFriendlyPlace {
        createdPayload = payload
        return try createResult.get()
    }
    func getMyPetFriendlyPlaces() async throws -> [PetFriendlyPlace] {
        try mineResult.get()
    }

    // Unused conformance.
    func createAlert(_ request: CreateAlertRequest) async throws -> MissingPetAlert { throw APIError.serverError("n/a") }
    func getPets() async throws -> [Pet] { [] }
    func getAlerts() async throws -> [MissingPetAlert] { [] }
    func getNearbyAlerts(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [MissingPetAlert] { [] }
    func updateAlertStatus(id: String, status: String) async throws -> MissingPetAlert { throw APIError.serverError("n/a") }
    func markPetFound(petId: String) async throws -> Pet { throw APIError.serverError("n/a") }
    func updatePet(id: String, _ request: UpdatePetRequest) async throws -> Pet { throw APIError.serverError("n/a") }
    func reportSighting(alertId: String, sighting: ReportSightingRequest) async throws -> Sighting { throw APIError.serverError("n/a") }
}

@MainActor
private func makePlace(
    id: String = "p1",
    category: PetFriendlyPlace.Category = .cafeBar,
    name: String = "Kutya Kávézó",
    status: PetFriendlyPlace.Status? = nil
) -> PetFriendlyPlace {
    PetFriendlyPlace(
        id: id, category: category, name: name, address: "Fő utca 1",
        latitude: 47.5, longitude: 19.05,
        introduction: nil, phone: nil, website: nil, city: nil, postcode: nil,
        country: nil, distanceKm: nil, status: status, createdAt: nil, updatedAt: nil
    )
}

/// The create-201 shape (no coords) — mirrors the slim model the create path now returns.
@MainActor
private func makeSubmitted(
    id: String = "p1",
    category: PetFriendlyPlace.Category = .cafeBar,
    name: String = "Kutya Kávézó",
    status: PetFriendlyPlace.Status = .pending
) -> SubmittedPetFriendlyPlace {
    SubmittedPetFriendlyPlace(
        id: id, category: category, name: name, address: "Fő utca 1", status: status,
        introduction: nil, phone: nil, website: nil, city: nil, postcode: nil, country: nil
    )
}

@Suite("PetFriendlyPlacesViewModel — nearby")
@MainActor
struct PetFriendlyPlacesViewModelTests {
    @Test("loads places on success")
    func loadsOnSuccess() async {
        let mock = MockPetFriendlyAPIService()
        mock.nearbyResult = .success([makePlace(id: "a"), makePlace(id: "b")])
        let vm = PetFriendlyPlacesViewModel(apiService: mock)
        await vm.loadNearby(latitude: 47.5, longitude: 19.05, market: "HU")
        #expect(vm.places.count == 2)
        #expect(vm.notInMarket == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test("404 maps to notInMarket, NOT a generic error")
    func notInMarketOn404() async {
        let mock = MockPetFriendlyAPIService()
        mock.nearbyResult = .failure(APIError.notFound("off"))
        let vm = PetFriendlyPlacesViewModel(apiService: mock)
        await vm.loadNearby(latitude: 47.5, longitude: 19.05, market: "HU")
        #expect(vm.notInMarket == true)
        #expect(vm.errorMessage == nil)     // distinct from a generic error
        #expect(vm.places.isEmpty)
    }

    @Test("a non-404 error surfaces as errorMessage, not notInMarket")
    func genericError() async {
        let mock = MockPetFriendlyAPIService()
        mock.nearbyResult = .failure(APIError.serverError("boom"))
        let vm = PetFriendlyPlacesViewModel(apiService: mock)
        await vm.loadNearby(latitude: 47.5, longitude: 19.05, market: "HU")
        #expect(vm.notInMarket == false)
        #expect(vm.errorMessage != nil)
    }

    @Test("category filter is client-side over the loaded places")
    func categoryFilter() async {
        let mock = MockPetFriendlyAPIService()
        mock.nearbyResult = .success([
            makePlace(id: "a", category: .cafeBar),
            makePlace(id: "b", category: .hotel),
        ])
        let vm = PetFriendlyPlacesViewModel(apiService: mock)
        await vm.loadNearby(latitude: 47.5, longitude: 19.05, market: "HU")
        vm.selectedCategory = .hotel
        #expect(vm.filteredPlaces.map(\.id) == ["b"])
        vm.selectedCategory = nil
        #expect(vm.filteredPlaces.count == 2)
    }
}

@Suite("SubmitPetFriendlyPlaceViewModel")
@MainActor
struct SubmitPetFriendlyPlaceViewModelTests {
    private func filledVM(_ mock: MockPetFriendlyAPIService) -> SubmitPetFriendlyPlaceViewModel {
        let vm = SubmitPetFriendlyPlaceViewModel(apiService: mock)
        vm.category = .cafeBar
        vm.name = "Kutya Kávézó"
        vm.address = "Fő utca 1"
        return vm
    }

    @Test("success returns the created place, clears error states, omits country")
    func submitSuccess() async {
        let mock = MockPetFriendlyAPIService()
        mock.createResult = .success(makeSubmitted(status: .pending))
        let vm = filledVM(mock)
        let result = await vm.submit()
        #expect(result != nil)
        #expect(vm.duplicate == nil)
        #expect(vm.addressError == nil)
        #expect(vm.formError == nil)
        #expect(vm.isSubmitting == false)
        #expect(mock.createdPayload?.country == nil)         // HU-implicit
        #expect(mock.createdPayload?.category == "cafe_bar")  // slug, not .unknown
    }

    @Test("409 sets `duplicate` (distinct), NOT formError")
    func submitDuplicate() async {
        let mock = MockPetFriendlyAPIService()
        mock.createResult = .failure(APIError.duplicatePlace(existing: "Kutya Kávézó"))
        let vm = filledVM(mock)
        let result = await vm.submit()
        #expect(result == nil)
        #expect(vm.duplicate?.existingName == "Kutya Kávézó")
        #expect(vm.formError == nil)      // not collapsed into the generic error
        #expect(vm.addressError == nil)
    }

    @Test("409 with no `existing` (23505 backstop) still sets duplicate with nil name")
    func submitDuplicateNoName() async {
        let mock = MockPetFriendlyAPIService()
        mock.createResult = .failure(APIError.duplicatePlace(existing: nil))
        let vm = filledVM(mock)
        _ = await vm.submit()
        #expect(vm.duplicate != nil)
        #expect(vm.duplicate?.existingName == nil)
        #expect(vm.formError == nil)
    }

    @Test("422 geocode sets `addressError` (address field), NOT formError")
    func submitGeocodeFailed() async {
        let mock = MockPetFriendlyAPIService()
        mock.createResult = .failure(APIError.geocodeFailed("Nem sikerült a cím geokódolása."))
        let vm = filledVM(mock)
        let result = await vm.submit()
        #expect(result == nil)
        #expect(vm.addressError == "Nem sikerült a cím geokódolása.")
        #expect(vm.formError == nil)      // not collapsed
        #expect(vm.duplicate == nil)
    }

    @Test("other errors surface as formError")
    func submitGenericError() async {
        let mock = MockPetFriendlyAPIService()
        mock.createResult = .failure(APIError.serverError("boom"))
        let vm = filledVM(mock)
        let result = await vm.submit()
        #expect(result == nil)
        #expect(vm.formError != nil)
        #expect(vm.duplicate == nil)
        #expect(vm.addressError == nil)
    }

    @Test("canSubmit requires category + name + address")
    func canSubmitValidation() {
        let vm = SubmitPetFriendlyPlaceViewModel(apiService: MockPetFriendlyAPIService())
        #expect(vm.canSubmit == false)
        vm.category = .cafeBar
        vm.name = "X"
        vm.address = "Y"
        #expect(vm.canSubmit == true)
        vm.address = "   "               // whitespace-only is not valid
        #expect(vm.canSubmit == false)
    }
}

@Suite("MyPetFriendlyPlacesViewModel")
@MainActor
struct MyPetFriendlyPlacesViewModelTests {
    @Test("loads my submissions and preserves each status")
    func loadsMine() async {
        let mock = MockPetFriendlyAPIService()
        mock.mineResult = .success([
            makePlace(id: "a", status: .approved),
            makePlace(id: "b", status: .rejected),
        ])
        let vm = MyPetFriendlyPlacesViewModel(apiService: mock)
        await vm.load()
        #expect(vm.places.count == 2)
        #expect(vm.places[0].status == .approved)
        #expect(vm.places[1].status == .rejected)
    }

    @Test("a read shape that omits `status` decodes to nil status — never .pending")
    func nilStatusPreserved() throws {
        // Nearby-shape JSON (no `status` key). nil = "omitted", distinct from .pending.
        let json = #"{"id":"x","category":"cafe_bar","name":"C","address":"A","lat":47.5,"lng":19.05}"#
        let place = try JSONDecoder().decode(PetFriendlyPlace.self, from: Data(json.utf8))
        #expect(place.status == nil)
        #expect(place.distanceKm == nil)
    }

    @Test("error surfaces as errorMessage")
    func loadError() async {
        let mock = MockPetFriendlyAPIService()
        mock.mineResult = .failure(APIError.serverError("boom"))
        let vm = MyPetFriendlyPlacesViewModel(apiService: mock)
        await vm.load()
        #expect(vm.errorMessage != nil)
        #expect(vm.places.isEmpty)
    }
}

/// The create-201 fix, proven against a REAL coord-less body (routes.ts:218 RETURNING omits
/// lat/lng) — BOTH directions from the SAME JSON string: the slim model decodes it, and the
/// coord-required model throws on it. This is a live decode, not a pre-built object renamed.
@Suite("Create-201 decode — coord-less body")
struct SubmittedPetFriendlyPlaceDecodeTests {
    // Exactly what the backend sends on 201: the `{ success, data: { place } }` envelope
    // with id/category/name/address/status and no lat/lng (routes.ts:218 RETURNING).
    private let coordlessBody = Data(#"""
    {"success":true,"data":{"place":{"id":"p3","category":"cafe_bar","name":"New Cafe","address":"Z","status":"pending"}}}
    """#.utf8)

    @Test("coord-less 201 decodes into the slim SubmittedPetFriendlyPlace")
    func slimDecodesCoordlessBody() throws {
        let response = try JSONDecoder().decode(SubmitPetFriendlyPlaceResponse.self, from: coordlessBody)
        #expect(response.data.place.id == "p3")
        #expect(response.data.place.category == .cafeBar)
        #expect(response.data.place.status == .pending)
        #expect(response.data.place.city == nil)
    }

    @Test("the SAME coord-less body throws against the coord-required PetFriendlyPlace")
    func sharedModelThrowsOnCoordlessBody() {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(PetFriendlyPlaceResponse.self, from: coordlessBody)
        }
    }
}
