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

                    // Pet details row (matching web design)
                    HStack(spacing: 16) {
                        if !pet.species.isEmpty {
                            Text("**Species:** \(pet.species.capitalized)")
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                        }
                        if let breed = pet.breed {
                            Text("**Breed:** \(breed)")
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                        }
                    }

                    HStack(spacing: 16) {
                        if let age = pet.age {
                            Text("**Age:** \(age)")
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                        }
                        if let color = pet.color {
                            Text("**Color:** \(color)")
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                        }
                    }
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

                // Share Location Button (placeholder - shown in preview)
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                        Text("Share My Location with Owner")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.tealAccent)
                    .cornerRadius(14)
                    .padding(.horizontal, 24)

                    Text("\(pet.name)'s owner will receive an SMS and email with your location")
                        .font(.system(size: 12))
                        .foregroundColor(.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Contact Owner Section
                if pet.ownerPhone != nil || pet.ownerEmail != nil {
                    VStack(spacing: 16) {
                        Text("Contact Owner")
                            .font(.system(size: 18, weight: .bold))

                        Text("Please let my owner know that you have found me. Tap on the share location button or call them on the phone number below.")
                            .font(.system(size: 14))
                            .foregroundColor(.mutedText)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 12) {
                            // Phone (tappable to call)
                            if let phone = pet.ownerPhone {
                                Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.tealAccent)
                                        Text("Call: \(phone)")
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
                            if let email = pet.ownerEmail {
                                Link(destination: URL(string: "mailto:\(email)")!) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.tealAccent)
                                        Text("Email: \(email)")
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
                    // No contact info message
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
                    .padding(.horizontal, 24)
                }

                // Owner Address Section (if publicly visible)
                if let address = pet.ownerAddress {
                    VStack(spacing: 12) {
                        Text("Owner Location")
                            .font(.system(size: 18, weight: .bold))

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "house.fill")
                                .foregroundColor(.mutedText)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(address)
                                    .font(.system(size: 15, weight: .medium))
                                if let line2 = pet.ownerAddressLine2, !line2.isEmpty {
                                    Text(line2)
                                        .font(.system(size: 14))
                                        .foregroundColor(.mutedText)
                                }
                                let cityLine = [pet.ownerCity, pet.ownerPostalCode].compactMap { $0 }.joined(separator: ", ")
                                if !cityLine.isEmpty {
                                    Text(cityLine)
                                        .font(.system(size: 14))
                                        .foregroundColor(.mutedText)
                                }
                                if let country = pet.ownerCountry {
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

                // How It Works Card
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How It Works")
                            .font(.system(size: 18, weight: .bold))
                        Text("Help reunite \(pet.name) with their owner safely")
                            .font(.system(size: 14))
                            .foregroundColor(.mutedText)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HowItWorksStep(number: "1", title: "Share Your Location", description: "Click the button above to share where you found \(pet.name)")
                        HowItWorksStep(number: "2", title: "Owner Gets Notified", description: "The owner receives an SMS with your location on Google Maps")
                        HowItWorksStep(number: "3", title: "Quick Reunion", description: "Stay near the location so the owner can find you and \(pet.name)")
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
                    Text("Your privacy matters. We'll only share your location with \(pet.name)'s owner with your explicit consent.")
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
        .navigationTitle("Public Profile Preview")
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
}
