import SwiftUI

struct ContactsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundColor(.purple)

            VStack(spacing: 8) {
                Text("Emergency Contacts")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("Add emergency contacts who will be notified if your pet goes missing")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 16) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Contact")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(12)
                }
                .disabled(true)

                Text("This feature will be available soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .navigationTitle("Contacts")
        .adaptiveList()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        ContactsView()
    }
}
