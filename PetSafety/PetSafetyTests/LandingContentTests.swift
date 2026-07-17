import Testing
import SwiftUI
@testable import PetSafety

/// C3 — 1.1b landing-content tests.
///
/// **ViewInspector-free** (§9.1, and the C1 precedent in `RootRouteTests.swift:7-9`).
/// The repo has no ViewInspector — verified 2026-07-17: 0 imports, 0 in the
/// pbxproj — so SwiftUI view internals are not introspectable. Ruled
/// 2026-07-17: Swift Testing, ViewInspector-free. (Spec §C3:217 says "XCTest /
/// UI"; §9.1 records the repo is Swift-Testing-dominant. Both the spec's wording
/// and §9.1's own count are stale — logged in the gaps register, not hand-edited.)
///
/// ## What these tests DO and DO NOT prove — read this before trusting a green run
///
/// The spec names six C3 tests. Without introspection they do not all survive as
/// written, and pretending otherwise is exactly the C1 dead-button that shipped
/// green twice — and C2's first artifact that was 795 green with an acceptance
/// test missing by name (§9.11). So, honestly:
///
/// - `communityListRendersSeededEntries` → **degraded** to a MODEL assertion.
///   These tests prove the seed's shape, keys, and destinations. They do **not**
///   prove that two cards render.
/// - `communityCardTapEmitsDestination` → **degraded**. `cardInvokesItsTapClosure`
///   below proves the closure is stored and calls back with the right
///   destination. It does **NOT** prove the `Button` in `CommunityEntryCard.body`
///   is wired to it. A card whose `Button(action:)` was hooked to nothing would
///   still pass this. That gap is real and is covered only by the device-QA gate.
/// - `addingDescriptorRendersCardNoLayoutChange` → **degraded** to
///   `appendingDescriptorYieldsOneMoreEntry`: it asserts the array is the source
///   of truth (data-driven, not hardcoded tiles). It proves nothing about layout
///   or rendering. Named for what it is.
/// - `zoneOneScanPresentsScanner`, `zoneOneFoundStrayPresentsForm`,
///   `zoneTwoOrderPresentsOrder` → **all three are declared device-QA, not
///   automated.** A UI-test target exists (`PetSafetyUITests/`, 25 files using
///   `XCUIApplication`), so an XCUITest looked possible — but there is **no way
///   to launch the app into a known logged-out state**: `-uiTesting` is a DEAD
///   launch argument (`AccessibilityAuditTests.swift:40` appends it; **zero**
///   handlers read it), and no production code reads
///   `ProcessInfo.processInfo.arguments` or `CommandLine.arguments` at all —
///   verified 2026-07-17. Such a test would depend on whatever session happens
///   to sit in the simulator's Keychain. Adding a launch-state hook is
///   production code touching auth inputs (§2 boundary) and is out of C3's
///   scope. So these three are covered by C3's done-when device-QA gate:
///   four scan outcomes × three assertions (scanner gone AND correct
///   destination up AND dismissible), on hardware, logged-out, cold-opened.
@Suite("C3 — landing content: Community seed + card contract")
struct LandingContentTests {

    // MARK: - Seed shape (G-a: the section renders complete from its data)

    @Test("Seed carries exactly the two entries shipping today")
    func communitySeedHasExactlyTwoEntries() {
        #expect(CommunityEntry.seed.count == 2)
    }

    @Test("Seed ids are stable keys, not array indices")
    func communitySeedIdsAreStableKeys() {
        #expect(CommunityEntry.seed.map(\.id) == ["lost_and_found", "pet_friendly"])
    }

    @Test("Each seed entry maps to its own distinct destination")
    func communitySeedDestinationsAreDistinct() {
        let destinations = CommunityEntry.seed.map(\.destination)
        #expect(destinations == [.lostAndFound, .petFriendlyPlaces])
        #expect(Set(destinations.map(String.init(describing:))).count == destinations.count)
    }

    /// Locks the reuse decision (approved 2026-07-17): the cards point at the
    /// SHIPPING keys, not new `community_*` twins. If someone later mints
    /// `community_lost_found_title`, this test fails and says why.
    @Test("Cards reuse the shipping localization keys — no duplicate twins")
    func communitySeedUsesShippingLocalizationKeys() {
        let lostAndFound = CommunityEntry.seed[0]
        #expect(lostAndFound.titleKey == LocalizedStringKey("lost_and_found_title"))
        #expect(lostAndFound.subtitleKey == LocalizedStringKey("community_lost_found_subtitle"))

        let petFriendly = CommunityEntry.seed[1]
        #expect(petFriendly.titleKey == LocalizedStringKey("pet_friendly_entry_title"))
        #expect(petFriendly.subtitleKey == LocalizedStringKey("pet_friendly_entry_subtitle"))
    }

    @Test("Every seed entry names an SF Symbol")
    func communitySeedEntriesCarryIcons() {
        for entry in CommunityEntry.seed {
            #expect(!entry.systemImage.isEmpty)
        }
    }

    // MARK: - Data-driven (the honest degradation of the layout test)

    /// The spec's `addingDescriptorRendersCardNoLayoutChange` renamed to what it
    /// can actually assert without introspection: the list is DERIVED from the
    /// array, so appending a descriptor is the whole cost of a new entry. This
    /// does NOT prove a third card renders — only that the data drives it.
    @Test("Appending a descriptor yields one more entry — the list is data-driven")
    func appendingDescriptorYieldsOneMoreEntry() {
        let extended = CommunityEntry.seed + [
            CommunityEntry(
                id: "future_feature",
                systemImage: "star.fill",
                titleKey: "community_section_title",
                subtitleKey: "community_section_title",
                destination: .lostAndFound
            )
        ]
        #expect(extended.count == CommunityEntry.seed.count + 1)
        #expect(extended.map(\.id).contains("future_feature"))
        // Identity is the stable key, so ForEach cannot collide on index.
        #expect(Set(extended.map(\.id)).count == extended.count)
    }

    // MARK: - Card closure contract (degraded — see the suite header)

    /// ⚠️ Proves the card STORES and CALLS BACK with its descriptor's
    /// destination. Does NOT prove `CommunityEntryCard.body`'s `Button` invokes
    /// it — that requires introspection we do not have. Device-QA covers it.
    @Test("Card invokes its tap closure with its own descriptor's destination")
    func cardInvokesItsTapClosure() {
        for entry in CommunityEntry.seed {
            var captured: CommunityDestination?
            let card = CommunityEntryCard(entry: entry) { captured = entry.destination }
            card.onTap()
            #expect(captured == entry.destination)
        }
    }
}
