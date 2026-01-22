import SwiftUI

/// Shows what the pet's public profile looks like (what others see when scanning the QR tag)
struct PetPublicProfileView: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview Banner
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.blue)
                    Text("This is how others see \(pet.name)'s profile")
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
                AsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
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
                    Text("Hello! I'm \(pet.name)")
                        .font(.system(size: 26, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("You've just scanned my tag. Thank you for helping me!")
                        .font(.system(size: 15))
                        .foregroundColor(.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Text("\(pet.species.capitalized) \(pet.breed.map { "• \($0)" } ?? "")")
                        .font(.system(size: 15))
                        .foregroundColor(.mutedText)
                }

                // Owner Notification Notice
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Owner is automatically notified when tag is scanned")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(14)
                .padding(.horizontal, 24)

                // Contact Owner Section
                VStack(spacing: 16) {
                    Text("Contact Owner")
                        .font(.system(size: 18, weight: .bold))

                    Text("If found, please contact my owner")
                        .font(.system(size: 14))
                        .foregroundColor(.mutedText)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        // Primary phone
                        if let phone = pet.ownerPhone {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.tealAccent)
                                Text("Call: \(phone)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(14)
                        }

                        // Secondary phone
                        if let secondaryPhone = pet.ownerSecondaryPhone {
                            HStack(spacing: 12) {
                                Image(systemName: "phone")
                                    .foregroundColor(.tealAccent)
                                Text("Alt: \(secondaryPhone)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(14)
                        }

                        // Primary email
                        if let email = pet.ownerEmail {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.tealAccent)
                                Text("Email: \(email)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(14)
                        }

                        // Secondary email
                        if let secondaryEmail = pet.ownerSecondaryEmail {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.tealAccent)
                                Text("Alt: \(secondaryEmail)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(14)
                        }

                        // No contact info message
                        if pet.ownerPhone == nil && pet.ownerEmail == nil {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Contact info not set up yet")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Owner Address Section (if publicly visible)
                if let address = pet.ownerAddress {
                    VStack(spacing: 12) {
                        Text("Owner Location")
                            .font(.system(size: 18, weight: .bold))

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.tealAccent)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(address)
                                        .font(.system(size: 15, weight: .medium))
                                    if let line2 = pet.ownerAddressLine2, !line2.isEmpty {
                                        Text(line2)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    let cityLine = [pet.ownerCity, pet.ownerPostalCode].compactMap { $0 }.joined(separator: ", ")
                                    if !cityLine.isEmpty {
                                        Text(cityLine)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    if let country = pet.ownerCountry {
                                        Text(country)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Pet Info Cards
                VStack(spacing: 12) {
                    if let color = pet.color {
                        PublicProfileInfoCard(title: "Color", value: color, icon: "paintpalette.fill")
                    }

                    if let age = pet.age {
                        PublicProfileInfoCard(title: "Age", value: age, icon: "calendar")
                    }

                    if let uniqueFeatures = pet.uniqueFeatures {
                        PublicProfileInfoCard(title: "Unique Features", value: uniqueFeatures, icon: "star.fill")
                    }
                }
                .padding(.horizontal, 24)

                // Medical Information (Important!)
                if let medical = pet.medicalInfo {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "cross.case.fill")
                                .foregroundColor(.red)
                            Text("Medical Information")
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
                if let allergies = pet.allergies {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Allergies")
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
            }
            .padding(.top, 24)
            .padding(.bottom, 120) // Add padding to prevent content from being hidden under tab bar
        }
        .navigationTitle("Public Profile Preview")
        .navigationBarTitleDisplayMode(.inline)
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
        .background(Color(UIColor.systemGray6))
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
            profileImage: nil,
            isMissing: false,
            createdAt: "",
            updatedAt: "",
            ageYears: 4,
            ageMonths: 6,
            ageText: "4 years 6 months",
            ageIsApproximate: false,
            allergies: "Chicken, Beef",
            medications: nil,
            uniqueFeatures: "White spot on chest",
            sex: "Male",
            isNeutered: true,
            qrCode: "ABC123",
            dateOfBirth: "2020-01-01",
            ownerName: "John Doe",
            ownerPhone: "+44 7700 900000",
            ownerEmail: "john@example.com"
        ))
    }
}
