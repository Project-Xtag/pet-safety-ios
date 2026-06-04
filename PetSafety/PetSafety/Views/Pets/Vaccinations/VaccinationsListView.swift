import SwiftUI

/// Full vaccination ("health record") list for a single pet — sectioned into
/// Active and Expired, with pull-to-refresh and a bottom-pinned add affordance.
///
/// Shares the pet-detail section's `VaccinationsViewModel` (passed in as an
/// `@ObservedObject`, never re-created) so edits and deletes made here reflect in
/// the pet-detail section and fire the same `onDidMutate` hook that keeps the
/// home card in sync — there is only ever one per-pet VM instance, owned by
/// `PetDetailView`.
///
/// Naming (Stage B decision #5): "vaccination record" / "health record" only —
/// never "passport," "certificate," or "official document." A disclaimer footer
/// states this is a personal record, not an official travel document.
struct VaccinationsListView: View {
    @ObservedObject var viewModel: VaccinationsViewModel
    let species: String

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var appState: AppState
    @State private var showingAddForm = false

    /// Active = not expired (valid + expiring), soonest expiry first (nil expiry
    /// last). Expired = most overdue first. Status is the client-derived
    /// `Vaccination.status`, identical to the pill the rows render.
    private var active: [Vaccination] {
        viewModel.vaccinations
            .filter { $0.status != .expired }
            .sorted { lhs, rhs in
                switch (lhs.daysUntilExpiry, rhs.daysUntilExpiry) {
                case let (l?, r?): return l < r
                case (nil, _?):    return false   // no-expiry sorts after dated
                case (_?, nil):    return true
                case (nil, nil):   return false
                }
            }
    }

    private var expired: [Vaccination] {
        viewModel.vaccinations
            .filter { $0.status == .expired }
            .sorted { ($0.daysUntilExpiry ?? 0) < ($1.daysUntilExpiry ?? 0) }
    }

    var body: some View {
        content
            .navigationTitle("vaccinations_title")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { addBar }
            .task {
                // Shared VM is usually already loaded by PetDetailView; cover the
                // case where this view is reached before that completed.
                if viewModel.vaccinations.isEmpty && !viewModel.isLoading {
                    await viewModel.load()
                }
            }
            // Sheets don't inherit EnvironmentObjects — re-inject what the form needs.
            .sheet(isPresented: $showingAddForm) {
                AddVaccinationView(viewModel: viewModel, species: species)
                    .environmentObject(authViewModel)
                    .environmentObject(appState)
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.vaccinations.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.loadFailed && viewModel.vaccinations.isEmpty {
            failureState
        } else if viewModel.vaccinations.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var list: some View {
        List {
            if !active.isEmpty {
                Section("vaccinations_section_active") {
                    ForEach(active) { row($0) }
                }
            }
            if !expired.isEmpty {
                Section("vaccinations_section_expired") {
                    ForEach(expired) { row($0) }
                }
            }
            Section {
                Text("vaccinations_disclaimer")
                    .font(.appFont(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private func row(_ vaccination: Vaccination) -> some View {
        NavigationLink(destination: VaccinationDetailView(viewModel: viewModel, vaccinationId: vaccination.id)) {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(vaccination.vaccineNameSnapshot)
                    .font(.appFont(size: 15, weight: .medium))
                    .foregroundColor(.ink)
                Text(String(format: NSLocalizedString("vaccinations_administered_value", comment: ""),
                            VaccinationDate.displayString(vaccination.administeredAt)))
                    .font(.appFont(size: 13))
                    .foregroundColor(.secondary)
                if let expiresAt = vaccination.expiresAt {
                    Text(String(format: NSLocalizedString("vaccinations_expires_value", comment: ""),
                                VaccinationDate.displayString(expiresAt)))
                        .font(.appFont(size: 13))
                        .foregroundColor(.secondary)
                } else {
                    Text("vaccinations_no_expiry")
                        .font(.appFont(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if vaccination.isMandatory { VaccinationMandatoryPill() }
                VaccinationStatusPill(status: vaccination.status)
            }
        }
        .padding(.vertical, 4)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "syringe")
                .font(.appFont(size: 40))
                .foregroundColor(.secondary)
            Text("vaccinations_section_empty")
                .font(.appFont(.body))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var failureState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.appFont(size: 40))
                .foregroundColor(.secondary)
            Text("vaccinations_load_failed")
                .font(.appFont(.body))
                .foregroundColor(.secondary)
            Button("retry") { Task { await viewModel.load() } }
                .buttonStyle(BrandButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var addBar: some View {
        Button(action: { showingAddForm = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("vaccinations_add_cta")
            }
        }
        .buttonStyle(BrandButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
