import SwiftUI

/// Shows what the pet's public profile looks like (what others see when scanning the QR tag)
struct PetPublicProfileView: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    // Use owner info from pet if available (public scan), otherwise fall back to current user
    // Respects privacy settings when showing current user's info
    private var ownerPhone: String? {
        // If pet has owner phone (from public scan), use it (backend already filtered by privacy)
        if let phone = pet.ownerPhone {
            return phone
        }
        // For own pet preview, check privacy setting
        guard let user = authViewModel.currentUser else { return nil }
        let showPublicly = user.showPhonePublicly ?? true
        return showPublicly ? user.phone : nil
    }

    private var ownerEmail: String? {
        if let email = pet.ownerEmail {
            return email
        }
        guard let user = authViewModel.currentUser else { return nil }
        let showPublicly = user.showEmailPublicly ?? true
        return showPublicly ? user.email : nil
    }

    private var ownerAddress: String? {
        if let address = pet.ownerAddress {
            return address
        }
        guard let user = authViewModel.currentUser else { return nil }
        let showPublicly = user.showAddressPublicly ?? true
        return showPublicly ? user.address : nil
    }

    private var ownerAddressLine2: String? {
        if let line2 = pet.ownerAddressLine2 {
            return line2
        }
        guard let user = authViewModel.currentUser else { return nil }
        let showPublicly = user.showAddressPublicly ?? true
        return showPublicly ? user.addressLine2 : nil
    }

    private var ownerCity: String? {
        if let city = pet.ownerCity {
            return city
        }
        guard let user = authViewModel.currentUser else { return nil }
        let showPublicly = user.showAddressPublicly ?? true
        return showPublicly ? user.city : nil
    }

    private var ownerPostalCode: String? {
        if let postalCode = pet.ownerPostalCode {
            return postalCode
        }
        guard let user = authViewModel.currentUser else { return nil }
        let showPublicly = user.showAddressPublicly ?? true
        return showPublicly ? user.postalCode : nil
    }

    private var ownerCountry: String? {
        if let country = pet.ownerCountry {
            return country
        }
        guard let user = authViewModel.currentUser else { return nil }
        let showPublicly = user.showAddressPublicly ?? true
        return showPublicly ? user.country : nil
    }

    // Check if user has contact info but it's hidden due to privacy settings
    private var hasHiddenContactInfo: Bool {
        guard let user = authViewModel.currentUser else { return false }
        // Check if user has phone/email but privacy settings hide them
        let hasPhone = user.phone != nil && !user.phone!.isEmpty
        let hasEmail = user.email != nil && !user.email.isEmpty
        let phoneHidden = hasPhone && !(user.showPhonePublicly ?? true)
        let emailHidden = hasEmail && !(user.showEmailPublicly ?? true)
        return phoneHidden || emailHidden
    }

    private var hasHiddenAddressInfo: Bool {
        guard let user = authViewModel.currentUser else { return false }
        let hasAddress = user.address != nil && !user.address!.isEmpty
        return hasAddress && !(user.showAddressPublicly ?? true)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview Banner
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.blue)
                    Text(String(format: NSLocalizedString("public_profile_subtitle", comment: ""), pet.name))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(14)
                .padding(.horizontal, 24)

                // Pet Photo
                CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Circle()
                            .fill(Color.tealAccent.opacity(0.2))
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.tealAccent)
                    }
                }
                .frame(width: 140, height: 140)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                // Pet Name & Info
                VStack(spacing: 8) {
                    Text(String(format: NSLocalizedString("hello_pet_name", comment: ""), pet.name))
                        .font(.system(size: 26, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("scanned_tag_thanks")
                        .font(.system(size: 15))
                        .foregroundColor(.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Pet details row (values only, no labels)
                    HStack(spacing: 8) {
                        let details: [String] = {
                            var items: [String] = []
                            if let breed = pet.breed, !breed.isEmpty {
                                items.append(breed)
                            }
                            if let age = pet.age, !age.isEmpty {
                                items.append(age)
                            }
                            if let sex = pet.sex, sex.lowercased() != "unknown" {
                                var sexText = sex.capitalized
                                if pet.isNeutered == true {
                                    sexText += ", " + NSLocalizedString("neutered", comment: "")
                                }
                                items.append(sexText)
                            } else if pet.isNeutered == true {
                                items.append(NSLocalizedString("neutered", comment: ""))
                            }
                            return items
                        }()

                        ForEach(Array(details.enumerated()), id: \.offset) { index, detail in
                            if index > 0 {
                                Text("•")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            Text(detail)
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                        }
                    }
                }

                // Share Location Button (placeholder - shown in preview)
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                        Text("share_location_with_owner")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.tealAccent)
                    .cornerRadius(14)
                    .padding(.horizontal, 24)

                    Text(String(format: NSLocalizedString("owner_notified_sms_email", comment: ""), pet.name))
                        .font(.system(size: 12))
                        .foregroundColor(.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Contact Owner Section
                if ownerPhone != nil || ownerEmail != nil {
                    VStack(spacing: 16) {
                        Text("contact_owner")
                            .font(.system(size: 18, weight: .bold))

                        Text("contact_owner_plea")
                            .font(.system(size: 14))
                            .foregroundColor(.mutedText)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 12) {
                            // Phone (tappable to call)
                            if let phone = ownerPhone {
                                Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.tealAccent)
                                        Text(String(format: NSLocalizedString("call_phone", comment: ""), phone))
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.mutedText)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(14)
                                }
                            }

                            // Email (tappable to send email)
                            if let email = ownerEmail {
                                Link(destination: URL(string: "mailto:\(email)")!) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.tealAccent)
                                        Text(String(format: NSLocalizedString("email_contact", comment: ""), email))
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.mutedText)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(14)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    // No visible contact info - show appropriate message
                    if hasHiddenContactInfo {
                        // Contact info exists but is hidden due to privacy settings
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "eye.slash.fill")
                                    .foregroundColor(.blue)
                                Text("contact_info_hidden")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            Text("contact_info_hidden_hint")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    } else {
                        // No contact info set up at all
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            Text("contact_info_not_set")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    }
                }

                // Owner Address Section (if publicly visible)
                if let address = ownerAddress {
                    VStack(spacing: 12) {
                        Text("scanner_owner_address")
                            .font(.system(size: 18, weight: .bold))

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "house.fill")
                                .foregroundColor(.mutedText)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(address)
                                    .font(.system(size: 15, weight: .medium))
                                if let line2 = ownerAddressLine2, !line2.isEmpty {
                                    Text(line2)
                                        .font(.system(size: 14))
                                        .foregroundColor(.mutedText)
                                }
                                let cityLine = [ownerCity, ownerPostalCode].compactMap { $0 }.joined(separator: ", ")
                                if !cityLine.isEmpty {
                                    Text(cityLine)
                                        .font(.system(size: 14))
                                        .foregroundColor(.mutedText)
                                }
                                if let country = ownerCountry {
                                    Text(country)
                                        .font(.system(size: 14))
                                        .foregroundColor(.mutedText)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                }

                // Medical Information
                if let medical = pet.medicalInfo, !medical.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "cross.case.fill")
                                .foregroundColor(.red)
                            Text("scanner_medical_info")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                        }
                        Text(medical)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                }

                // Allergies
                if let allergies = pet.allergies, !allergies.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("allergies")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        Text(allergies)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                }

                // Notes
                if let notes = pet.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .foregroundColor(.blue)
                            Text("scanner_notes")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                }

                // How It Works Card
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("how_it_works")
                            .font(.system(size: 18, weight: .bold))
                        Text(String(format: NSLocalizedString("help_reunite_pet", comment: ""), pet.name))
                            .font(.system(size: 14))
                            .foregroundColor(.mutedText)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HowItWorksStep(number: "1", title: NSLocalizedString("step_share_location", comment: ""), description: String(format: NSLocalizedString("scanner_step1_dynamic_desc", comment: ""), pet.name))
                        HowItWorksStep(number: "2", title: NSLocalizedString("step_owner_notified", comment: ""), description: NSLocalizedString("step_owner_notified_desc", comment: ""))
                        HowItWorksStep(number: "3", title: NSLocalizedString("step_quick_reunion", comment: ""), description: String(format: NSLocalizedString("scanner_step3_dynamic_desc", comment: ""), pet.name))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .padding(.horizontal, 24)

                // Privacy Notice
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.mutedText)
                    Text(String(format: NSLocalizedString("privacy_notice", comment: ""), pet.name))
                        .font(.system(size: 12))
                        .foregroundColor(.mutedText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .padding(.horizontal, 24)
            }
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .navigationTitle(Text("public_profile_preview"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - How It Works Step
struct HowItWorksStep: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.tealAccent)
                .frame(width: 28, height: 28)
                .background(Color.tealAccent.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.mutedText)
            }
        }
    }
}

// MARK: - Public Profile Info Card
struct PublicProfileInfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.tealAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.mutedText)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

#Preview {
    NavigationView {
        PetPublicProfileView(pet: Pet(
            id: "1",
            ownerId: "1",
            name: "Max",
            species: "Dog",
            breed: "Golden Retriever",
            color: "Golden",
            weight: 30.0,
            microchipNumber: "123456789",
            medicalNotes: "Allergic to chicken",
            notes: "Friendly with kids",
            isMissing: false,
            createdAt: "",
            updatedAt: "",
            ageYears: 4,
            ageMonths: 6,
            ageText: "4 years 6 months",
            ageIsApproximate: false,
            allergies: "Chicken, Beef",
            uniqueFeatures: "White spot on chest",
            sex: "Male",
            isNeutered: true,
            qrCode: "ABC123",
            dateOfBirth: "2020-01-01",
            ownerName: "John Doe",
            ownerPhone: "+44 7700 900000",
            ownerEmail: "john@example.com",
            ownerAddress: "123 Oak Street",
            ownerAddressLine2: "Flat 4B",
            ownerCity: "London",
            ownerPostalCode: "SW1A 1AA",
            ownerCountry: "United Kingdom"
        ))
    }
    .environmentObject(AuthViewModel())
}
