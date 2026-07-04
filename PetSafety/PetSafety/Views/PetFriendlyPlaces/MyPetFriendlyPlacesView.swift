import SwiftUI

/// The owner's own pet-friendly submissions, ALL statuses (M3d). Pushed from ProfileView.
///
/// Unlike the public read, `/mine` returns `status` on every row, so THIS is where status
/// is the point — and where the nil-collapse note has a real consumer. Status is driven
/// off the real `Status` enum via `statusDisplay` (exhaustive pending/approved/rejected/
/// unknown); a nil status renders as NO badge (never folded into `.pending`), `.unknown`
/// as its own grey state. The row reuses `PlaceCard`, which shows the status badge when
/// `status` is present (here) and the distance when it isn't (nearby).
///
/// AUTH + market: `getMyPetFriendlyPlaces()` is authenticated and PARAMLESS — no `?market=`
/// (the flag gate reads the user's country server-side). A 404 here is NOT a dark-market
/// signal (unlike the nearby list), so the mine VM surfaces it as a generic error, never
/// `notInMarket`.
struct MyPetFriendlyPlacesView: View {
    @StateObject private var viewModel = MyPetFriendlyPlacesViewModel()
    @State private var selectedPlace: PetFriendlyPlace?

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    if viewModel.isLoading && viewModel.places.isEmpty {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 240)
                    } else if let error = viewModel.errorMessage {
                        infoState(systemImage: "exclamationmark.triangle", text: error)
                    } else if viewModel.places.isEmpty {
                        infoState(systemImage: "tray", text: String(localized: "pet_friendly_mine_empty"))
                    } else {
                        ForEach(viewModel.places) { place in
                            Button { selectedPlace = place } label: { PlaceCard(place: place) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(String(localized: "pet_friendly_mine_title"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(item: $selectedPlace) { place in
            PetFriendlyPlaceDetailSheet(place: place)
        }
    }

    private func infoState(systemImage: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage).font(.system(size: 34)).foregroundColor(.brandOrange)
            Text(text).font(.appFont(size: 14)).foregroundColor(.mutedText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .padding(24)
    }
}
