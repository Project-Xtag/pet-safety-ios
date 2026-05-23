import SwiftUI
import PhotosUI
import CoreLocation

/// Form a community member fills out when they find a stray pet.
/// Mirrors the web's FoundPetFormDialog.tsx — same fields, same
/// validation, same multipart submit.
///
/// Auth is optional: anonymous reporters get a single-use manage token
/// (stored in UserDefaults via FoundPetManageTokenStore) so the same
/// device can mark the report as reunited later without an account.
struct FoundPetFormView: View {
    @Environment(\.dismiss) private var dismiss

    /// Called with the freshly-created report so the caller can drop it
    /// into the local feed without waiting for the next /nearby refresh.
    var onSubmitted: ((CommunityFoundPet) -> Void)?

    @StateObject private var locationManager = LocationManager()

    @State private var species: CommunityFoundPet.Species = .dog
    @State private var sex: CommunityFoundPet.Sex = .unknown
    @State private var breed: String = ""
    @State private var color: String = ""
    @State private var descriptionText: String = ""
    @State private var foundAt: Date = Date()

    @State private var coordinate: CLLocationCoordinate2D?
    @State private var manualAddress: String = ""
    @State private var isCapturingLocation = false

    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: UIImage?

    @State private var shareContact = false
    @State private var reporterName: String = ""
    @State private var reporterEmail: String = ""
    @State private var reporterPhone: String = ""

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var validationMessage: String?

    private let breedMaxLength = 120
    private let colorMaxLength = 120
    private let descriptionMaxLength = 2000
    private let addressMaxLength = 500
    private let reporterNameMaxLength = 200

    var body: some View {
        NavigationView {
            Form {
                speciesSection
                sexSection
                detailsSection
                foundAtSection
                locationSection
                photoSection
                contactSection
                if let validationMessage {
                    Section { Text(validationMessage).foregroundColor(.errorColor).font(.appFont(size: 13)) }
                }
                if let errorMessage {
                    Section { Text(errorMessage).foregroundColor(.errorColor).font(.appFont(size: 13)) }
                }
            }
            .navigationTitle(String(localized: "found_pet_form_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { dismiss() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "found_pet_form_submit")) {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task { await loadPhoto(newItem) }
            }
        }
    }

    // MARK: - Sections

    private var speciesSection: some View {
        Section(header: Text("found_pet_form_species")) {
            Picker("found_pet_form_species", selection: $species) {
                Text("lost_and_found_species_dog_singular").tag(CommunityFoundPet.Species.dog)
                Text("lost_and_found_species_cat_singular").tag(CommunityFoundPet.Species.cat)
                Text("lost_and_found_species_other_singular").tag(CommunityFoundPet.Species.other)
            }
            .pickerStyle(.segmented)
        }
    }

    private var sexSection: some View {
        Section(header: Text("found_pet_form_sex")) {
            Picker("found_pet_form_sex", selection: $sex) {
                Text("found_pet_form_sex_male").tag(CommunityFoundPet.Sex.male)
                Text("found_pet_form_sex_female").tag(CommunityFoundPet.Sex.female)
                Text("found_pet_form_sex_unknown").tag(CommunityFoundPet.Sex.unknown)
            }
            .pickerStyle(.segmented)
        }
    }

    private var detailsSection: some View {
        Section(header: Text("found_pet_form_details")) {
            TextField(String(localized: "found_pet_form_breed_placeholder"), text: $breed)
                .onChange(of: breed) { _, v in if v.count > breedMaxLength { breed = String(v.prefix(breedMaxLength)) } }
            TextField(String(localized: "found_pet_form_color_placeholder"), text: $color)
                .onChange(of: color) { _, v in if v.count > colorMaxLength { color = String(v.prefix(colorMaxLength)) } }
            TextEditor(text: $descriptionText)
                .frame(minHeight: 90)
                .onChange(of: descriptionText) { _, v in
                    if v.count > descriptionMaxLength { descriptionText = String(v.prefix(descriptionMaxLength)) }
                }
        }
    }

    private var foundAtSection: some View {
        Section(header: Text("found_pet_form_found_at")) {
            DatePicker(
                "found_pet_form_found_at",
                selection: $foundAt,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
        }
    }

    private var locationSection: some View {
        Section(header: Text("found_pet_form_location")) {
            HStack {
                Button {
                    Task { await captureLocation() }
                } label: {
                    HStack {
                        if isCapturingLocation {
                            ProgressView()
                        } else {
                            Image(systemName: "location.circle.fill")
                        }
                        Text("found_pet_form_use_gps")
                    }
                }
                .buttonStyle(.bordered)
                Spacer()
                if let coordinate {
                    Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                        .font(.appFont(size: 11))
                        .foregroundColor(.mutedText)
                }
            }
            TextField(String(localized: "found_pet_form_address_placeholder"), text: $manualAddress)
                .textInputAutocapitalization(.words)
                .onChange(of: manualAddress) { _, v in
                    if v.count > addressMaxLength { manualAddress = String(v.prefix(addressMaxLength)) }
                }
            Text("found_pet_form_location_hint")
                .font(.appFont(size: 11))
                .foregroundColor(.mutedText)
        }
    }

    private var photoSection: some View {
        Section(header: Text("found_pet_form_photo")) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                HStack {
                    if let photoImage {
                        Image(uiImage: photoImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: "photo")
                            .font(.appFont(size: 32))
                            .foregroundColor(.mutedText)
                            .frame(width: 80, height: 80)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(photoImage == nil ? "found_pet_form_add_photo" : "found_pet_form_change_photo")
                            .font(.appFont(size: 15, weight: .semibold))
                        Text("found_pet_form_photo_hint")
                            .font(.appFont(size: 11))
                            .foregroundColor(.mutedText)
                    }
                    .padding(.leading, 8)
                    Spacer()
                }
            }
            if photoImage != nil {
                Button(role: .destructive) {
                    photoItem = nil
                    photoImage = nil
                } label: {
                    Label("found_pet_form_remove_photo", systemImage: "trash")
                }
            }
        }
    }

    private var contactSection: some View {
        Section(header: Text("found_pet_form_contact")) {
            Toggle("found_pet_form_share_contact", isOn: $shareContact)
            if shareContact {
                TextField(String(localized: "found_pet_form_name_placeholder"), text: $reporterName)
                    .textContentType(.name)
                    .onChange(of: reporterName) { _, v in
                        if v.count > reporterNameMaxLength { reporterName = String(v.prefix(reporterNameMaxLength)) }
                    }
                TextField(String(localized: "found_pet_form_email_placeholder"), text: $reporterEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField(String(localized: "found_pet_form_phone_placeholder"), text: $reporterPhone)
                    .keyboardType(.phonePad)
            }
        }
    }

    // MARK: - Actions

    private func captureLocation() async {
        isCapturingLocation = true
        defer { isCapturingLocation = false }
        locationManager.requestLocation()
        // Poll up to 6 s for a fix, matching the web's geolocation timeout.
        var attempts = 0
        while locationManager.location == nil && attempts < 30 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            attempts += 1
        }
        if let loc = locationManager.location {
            coordinate = loc
        } else {
            errorMessage = String(localized: "found_pet_form_gps_unavailable")
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            photoImage = image
        }
    }

    private func submit() async {
        validationMessage = nil
        errorMessage = nil

        // Server-side validation requires (a) coordinates OR an address,
        // (b) a photo OR a non-empty description. Mirror locally so the
        // user gets immediate feedback rather than a roundtrip 400.
        let trimmedAddress = manualAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard coordinate != nil || !trimmedAddress.isEmpty else {
            validationMessage = String(localized: "found_pet_form_validation_location")
            return
        }
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard photoImage != nil || !trimmedDescription.isEmpty else {
            validationMessage = String(localized: "found_pet_form_validation_evidence")
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        // Geocode the manual address if no GPS — the backend will accept
        // either, but the web geocodes on the client and posts only
        // lat/lng. We do the same for parity.
        var lat: Double?
        var lng: Double?
        if let coordinate {
            lat = coordinate.latitude
            lng = coordinate.longitude
        } else if !trimmedAddress.isEmpty {
            if let geocoded = await geocode(trimmedAddress) {
                lat = geocoded.latitude
                lng = geocoded.longitude
            } else {
                errorMessage = String(localized: "found_pet_form_geocode_failed")
                return
            }
        }
        guard let lat, let lng else {
            errorMessage = String(localized: "found_pet_form_validation_location")
            return
        }

        let photoData = photoImage?.jpegData(compressionQuality: 0.8)

        let payload = CreateFoundPetRequest(
            species: species,
            sex: sex,
            breed: trimmedString(breed),
            color: trimmedString(color),
            description: trimmedString(descriptionText),
            foundAt: foundAt,
            lat: lat,
            lng: lng,
            foundAddress: trimmedString(manualAddress),
            reporterName: shareContact ? trimmedString(reporterName) : nil,
            reporterEmail: shareContact ? trimmedString(reporterEmail) : nil,
            reporterPhone: shareContact ? trimmedString(reporterPhone) : nil,
            photoData: photoData
        )

        do {
            let (report, manageToken) = try await APIService.shared.createFoundPet(payload)
            FoundPetManageTokenStore.append(FoundPetManageToken(id: report.id, token: manageToken))
            onSubmitted?(report)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func trimmedString(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private func geocode(_ address: String) async -> CLLocationCoordinate2D? {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            return placemarks.first?.location?.coordinate
        } catch {
            return nil
        }
    }
}
