import SwiftUI

/// Detail sheet for a community-submitted found-pet report. Opened from
/// the Lost & Found list / map. Mirrors the web's FoundPetDetailDialog
/// content: photo, species/sex/breed/color, description, found-at,
/// address, and an "Open in maps" CTA that hands off to the existing
/// MapAppPickerView (Apple Maps / Google Maps / Waze).
struct FoundPetDetailView: View {
    let report: CommunityFoundPet
    @Environment(\.dismiss) private var dismiss
    @State private var showMapPicker = false

    private static let amber = Color(red: 0.96, green: 0.62, blue: 0.04)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photo
                    statusRow
                    descriptionBlock
                    metadataBlock
                    contactBlock
                    openInMapsButton
                }
                .padding(20)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(String(localized: "found_pet_detail_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common_done")) { dismiss() }
                }
            }
            .sheet(isPresented: $showMapPicker) {
                MapAppPickerView(
                    location: LocationData(
                        latitude: report.foundLatitude,
                        longitude: report.foundLongitude,
                        isApproximate: false
                    ),
                    petName: report.breed ?? String(localized: "lost_and_found_status_community")
                )
            }
        }
    }

    private var photo: some View {
        Group {
            if let urlString = report.photoUrl, let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Self.amber.opacity(0.15))
                }
            } else {
                ZStack {
                    Rectangle().fill(Self.amber.opacity(0.15))
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Self.amber)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(4/3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Text("lost_and_found_status_community")
                .font(.appFont(size: 10, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Self.amber)
                .clipShape(Capsule())
            Text(speciesLabel(report.species))
                .font(.appFont(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            Text(sexLabel(report.sex))
                .font(.appFont(size: 12))
                .foregroundColor(.mutedText)
        }
    }

    @ViewBuilder
    private var descriptionBlock: some View {
        if let desc = report.description, !desc.isEmpty {
            Text(desc)
                .font(.appFont(size: 14))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var metadataBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let breed = report.breed, !breed.isEmpty {
                metadataRow(icon: "tag.fill", label: String(localized: "found_pet_detail_breed"), value: breed)
            }
            if let color = report.color, !color.isEmpty {
                metadataRow(icon: "paintpalette.fill", label: String(localized: "found_pet_detail_color"), value: color)
            }
            metadataRow(
                icon: "calendar",
                label: String(localized: "found_pet_detail_found_at"),
                value: foundAtFormatted
            )
            if let addr = report.foundAddress, !addr.isEmpty {
                metadataRow(icon: "mappin.and.ellipse", label: String(localized: "found_pet_detail_address"), value: addr)
            }
            if let km = report.distanceKm {
                metadataRow(
                    icon: "location.fill",
                    label: String(localized: "found_pet_detail_distance"),
                    value: String(format: "%.1f km", km)
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.cream)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(Color.softBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var contactBlock: some View {
        let name = report.reporterName
        let email = report.reporterEmail
        let phone = report.reporterPhone
        let anyContact = (name != nil) || (email != nil) || (phone != nil)
        if anyContact {
            VStack(alignment: .leading, spacing: 10) {
                Text("found_pet_detail_finder_contact")
                    .font(.appFont(size: 11, weight: .bold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(.mutedText)
                if let name { metadataRow(icon: "person.fill", label: String(localized: "found_pet_detail_finder_name"), value: name) }
                if let email {
                    Link(destination: URL(string: "mailto:\(email)") ?? URL(string: "https://senra.pet")!) {
                        metadataRow(icon: "envelope.fill", label: String(localized: "found_pet_detail_finder_email"), value: email)
                    }
                }
                if let phone {
                    Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") ?? URL(string: "https://senra.pet")!) {
                        metadataRow(icon: "phone.fill", label: String(localized: "found_pet_detail_finder_phone"), value: phone)
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            Text("found_pet_detail_no_contact")
                .font(.appFont(size: 12))
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.leading)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var openInMapsButton: some View {
        Button {
            showMapPicker = true
        } label: {
            HStack {
                Image(systemName: "map.fill")
                Text("found_pet_detail_open_in_maps")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryPillButtonStyle())
    }

    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.mutedText)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.appFont(size: 11))
                    .foregroundColor(.mutedText)
                Text(value)
                    .font(.appFont(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }

    // MARK: - Helpers

    private var foundAtFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: report.foundAt)
    }

    private func speciesLabel(_ s: CommunityFoundPet.Species) -> String {
        switch s {
        case .dog: return String(localized: "lost_and_found_species_dog_singular")
        case .cat: return String(localized: "lost_and_found_species_cat_singular")
        case .other: return String(localized: "lost_and_found_species_other_singular")
        }
    }

    private func sexLabel(_ s: CommunityFoundPet.Sex) -> String {
        switch s {
        case .male: return String(localized: "found_pet_form_sex_male")
        case .female: return String(localized: "found_pet_form_sex_female")
        case .unknown: return String(localized: "found_pet_form_sex_unknown")
        }
    }
}
