# Build Configurations

Three xcconfig files map to three build configurations:

| xcconfig | Build config | Scheme | Bundle ID | API |
|---|---|---|---|---|
| `Debug.xcconfig` | Debug | PetSafety | `com.petsafety.PetSafety` | api.senra.pet |
| `Staging.xcconfig` | Staging | PetSafety Staging | `com.petsafety.PetSafety.staging` | staging.senra.pet |
| `Release.xcconfig` | Release | PetSafety | `com.petsafety.PetSafety` | api.senra.pet |

## One-time Xcode setup (manual, pbxproj edits are fragile)

1. **Add the Config group to the project**
   Xcode → File → Add Files → select `PetSafety/Config/` → Add folder reference (blue folder icon, not group).

2. **Duplicate Release → Staging**
   Project navigator → PetSafety (blue icon) → Info tab → Configurations → click `+` → "Duplicate Release Configuration" → rename to `Staging`.

3. **Link xcconfig files to configs**
   Same Configurations table. For the PetSafety project row:
   - Debug → `PetSafety/Config/Debug.xcconfig`
   - Staging → `PetSafety/Config/Staging.xcconfig`
   - Release → `PetSafety/Config/Release.xcconfig`
   Leave the test target rows as `<None>`.

4. **Duplicate the scheme**
   Product → Scheme → Manage Schemes → select `PetSafety` → Duplicate → rename to `PetSafety Staging`.
   Edit the new scheme → Run → Build Configuration = `Staging`. Do the same for Test/Archive if you want staging TestFlight builds.

5. **Update Info.plist**
   The `API_BASE_URL` Info.plist entry already references `$(API_BASE_URL)` from the active xcconfig. No further edit needed.

6. **Verify**
   Select the `PetSafety Staging` scheme, build + run on a simulator. The app icon label should read "SENRA Staging" and it should install alongside a prod build (different bundle id).
