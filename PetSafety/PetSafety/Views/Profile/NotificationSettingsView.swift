import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @AppStorage("emailNotificationsEnabled") private var emailNotificationsEnabled = true
    @AppStorage("smsNotificationsEnabled") private var smsNotificationsEnabled = false

    // Alert Types
    @AppStorage("notifyMissingPetAlerts") private var notifyMissingPetAlerts = true
    @AppStorage("notifyNearbyAlerts") private var notifyNearbyAlerts = true

    // Updates
    @AppStorage("notifyOrderUpdates") private var notifyOrderUpdates = true
    @AppStorage("notifyAccountActivity") private var notifyAccountActivity = true
    @AppStorage("notifyProductUpdates") private var notifyProductUpdates = false
    @AppStorage("notifyMarketingEmails") private var notifyMarketingEmails = false

    var body: some View {
        List {
            Section(header: Text("Notification Channels"), footer: Text("Choose how you want to receive notifications")) {
                Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                Toggle("Email Notifications", isOn: $emailNotificationsEnabled)
                Toggle("SMS Notifications", isOn: $smsNotificationsEnabled)
            }

            Section(header: Text("Pet Alerts"), footer: Text("Notifications about missing pets in your area")) {
                Toggle("Missing Pet Alerts", isOn: $notifyMissingPetAlerts)
                Toggle("Nearby Alerts (10km)", isOn: $notifyNearbyAlerts)
            }

            Section(header: Text("Account & Orders"), footer: Text("Stay updated on your account activity and orders")) {
                Toggle("Order Updates", isOn: $notifyOrderUpdates)
                Toggle("Account Activity", isOn: $notifyAccountActivity)
            }

            Section(header: Text("Optional Updates"), footer: Text("News, tips, and promotional content")) {
                Toggle("Product Updates", isOn: $notifyProductUpdates)
                Toggle("Marketing Emails", isOn: $notifyMarketingEmails)
            }

            Section {
                Button(action: { testNotification() }) {
                    HStack {
                        Spacer()
                        Image(systemName: "bell.badge")
                        Text("Send Test Notification")
                        Spacer()
                    }
                }
            }

            Section(footer: Text("You can change these settings at any time. Critical alerts about your pets will always be sent.")) {
                EmptyView()
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func testNotification() {
        // In a real app, this would trigger a test notification
        // For now, it's just a placeholder
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
    }
}
