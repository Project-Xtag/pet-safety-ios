import SwiftUI
import CoreLocation
import Combine
import UIKit

/// Prompt shown after marking a pet as found to encourage sharing a success story
struct SuccessStoryPromptView: View {
    let pet: Pet
    let onDismiss: () -> Void
    let onStorySubmitted: () -> Void

    @StateObject private var locationManager = LocationManager()
    @State private var showShareForm = false
    @State private var storyText = ""
    @State private var reunionCity = ""
    @State private var isPublic = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var isGeneratingShareCard = false
    @State private var showSocialShareSheet = false
    @State private var shareCardImage: UIImage?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    private let maxStoryLength = 150

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showShareForm {
                    shareFormView
                } else {
                    promptView
                }
            }
            .navigationTitle(showShareForm ? String(localized: "story_share_title") : String(localized: "story_great_news"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Request location when view appears
                locationManager.requestLocation()
            }
            .onReceive(locationManager.$location) { newLocation in
                if let location = newLocation {
                    userLocation = location
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(showShareForm ? String(localized: "back") : String(localized: "skip")) {
                        if showShareForm {
                            withAnimation {
                                showShareForm = false
                            }
                        } else {
                            onDismiss()
                        }
                    }
                }

                if showShareForm {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("story_post") {
                            submitStory()
                        }
                        .fontWeight(.semibold)
                        .disabled(isSubmitting)
                    }
                }
            }
            .sheet(isPresented: $showSocialShareSheet) {
                if let image = shareCardImage {
                    let caption = String(format: String(localized: "story_social_caption %@"), pet.name, pet.name)
                    ShareSheetView(activityItems: [image, caption])
                }
            }
        }
    }

    // MARK: - Share Sheet Wrapper
    private struct ShareSheetView: UIViewControllerRepresentable {
        let activityItems: [Any]

        func makeUIViewController(context: Context) -> UIActivityViewController {
            let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            vc.excludedActivityTypes = [
                .saveToCameraRoll,
                .print,
                .assignToContact,
                .addToReadingList,
                .airDrop,
                .markupAsPDF,
                .openInIBooks,
            ]
            return vc
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }

    // MARK: - Prompt View
    private var promptView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success Animation
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.tealAccent.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.tealAccent.opacity(0.25))
                        .frame(width: 90, height: 90)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.tealAccent)
                }

                Text("story_pet_is_home \(pet.name)")
                    .font(.title)
                    .fontWeight(.bold)
            }

            // Pet Photo
            CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: pet.species.lowercased() == "dog" ? "dog.fill" : "cat.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, height: 100)
            .background(Color(.systemGray6))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.tealAccent, lineWidth: 3)
            )

            // Message
            VStack(spacing: 12) {
                Text("story_share_reunion")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("story_inspire_others \(pet.name)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    withAnimation {
                        showShareForm = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("story_share_my_story")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.tealAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button {
                    generateAndShareCard()
                } label: {
                    HStack {
                        if isGeneratingShareCard {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isGeneratingShareCard ? String(localized: "story_generating_card") : String(localized: "story_share_good_news"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandOrange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isGeneratingShareCard)

                Button {
                    onDismiss()
                } label: {
                    Text("story_maybe_later")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Share Form View
    private var shareFormView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Pet Header
                HStack(spacing: 16) {
                    CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: pet.species.lowercased() == "dog" ? "dog.fill" : "cat.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pet.name)
                            .font(.headline)
                        Text("story_reunited")
                            .font(.subheadline)
                            .foregroundColor(.tealAccent)
                    }

                    Spacer()

                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.tealAccent)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Story Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("story_your_story")
                        .font(.headline)

                    TextEditor(text: $storyText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: storyText) { _, newValue in
                            if newValue.count > maxStoryLength {
                                storyText = String(newValue.prefix(maxStoryLength))
                            }
                        }

                    HStack {
                        Text("story_share_how \(pet.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(storyText.count)/\(maxStoryLength)")
                            .font(.caption)
                            .foregroundColor(storyText.count >= maxStoryLength ? .orange : .secondary)
                    }
                }

                // Reunion City
                VStack(alignment: .leading, spacing: 8) {
                    Text("story_city_optional")
                        .font(.headline)

                    TextField(String(localized: "story_city_placeholder"), text: $reunionCity)
                        .textFieldStyle(.roundedBorder)
                }

                // Privacy Toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $isPublic) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("story_share_publicly")
                                .font(.headline)
                            Text("story_share_publicly_desc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.tealAccent)
                }

                // Error Message
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // Submit Button
                Button {
                    submitStory()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSubmitting ? String(localized: "story_posting") : String(localized: "story_share_story"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(storyText.isEmpty ? Color.gray : Color.tealAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(storyText.isEmpty || isSubmitting)

                // Info
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("story_privacy_note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }

    // MARK: - Social Share Card
    private func generateAndShareCard() {
        isGeneratingShareCard = true
        Task {
            var petImage: UIImage?
            if let urlString = pet.photoUrl, let url = URL(string: urlString) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    petImage = UIImage(data: data)
                } catch {
                    // Use placeholder if photo fails to load
                }
            }

            let cardImage = ShareCardGenerator.generate(
                petName: pet.name,
                petImage: petImage,
                petSpecies: pet.species,
                city: pet.ownerCity
            )

            await MainActor.run {
                shareCardImage = cardImage
                isGeneratingShareCard = false
                showSocialShareSheet = true
            }
        }
    }

    // MARK: - Submit Story
    private func submitStory() {
        guard !storyText.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                _ = try await APIService.shared.createSuccessStorySimple(
                    petId: pet.id,
                    alertId: nil,
                    storyText: storyText.trimmingCharacters(in: .whitespacesAndNewlines),
                    reunionCity: reunionCity.isEmpty ? nil : reunionCity.trimmingCharacters(in: .whitespacesAndNewlines),
                    reunionLatitude: userLocation?.latitude,
                    reunionLongitude: userLocation?.longitude,
                    isPublic: isPublic
                )

                appState.showSuccess(String(localized: "story_shared_success"))
                onStorySubmitted()
            } catch {
                errorMessage = error.localizedDescription
            }

            isSubmitting = false
        }
    }
}

#Preview {
    SuccessStoryPromptView(
        pet: Pet(
            id: "1",
            ownerId: "1",
            name: "Max",
            species: "Dog",
            breed: "Golden Retriever",
            color: "Golden",
            weight: 30.0,
            microchipNumber: nil,
            medicalNotes: nil,
            notes: nil,
            profileImage: nil,
            isMissing: false,
            createdAt: "",
            updatedAt: ""
        ),
        onDismiss: {},
        onStorySubmitted: {}
    )
    .environmentObject(AppState())
}
