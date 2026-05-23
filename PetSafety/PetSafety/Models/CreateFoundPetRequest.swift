import Foundation

/// Payload for `POST /community/found-pets`. Encoded as multipart/form-data
/// because the optional photo upload is binary — JSON-only would need a
/// pre-upload step we don't have on this endpoint.
///
/// Backend validation (createFoundPetSchema in the backend):
///   - species required
///   - sex defaults to .unknown when omitted
///   - foundAt required, must not be more than 60s in the future
///   - lat/lng required
///   - either photoData OR a non-empty description must be present
///   - reporter contact fields are all optional
struct CreateFoundPetRequest {
    let species: CommunityFoundPet.Species
    let sex: CommunityFoundPet.Sex
    let breed: String?
    let color: String?
    let description: String?
    let foundAt: Date
    let lat: Double
    let lng: Double
    let foundAddress: String?
    let reporterName: String?
    let reporterEmail: String?
    let reporterPhone: String?
    let photoData: Data?

    /// Build the multipart body. Mirrors the web's FormData construction;
    /// only sends fields that are present (the backend rejects empty strings
    /// on a couple of optional fields, e.g. reporterEmail).
    func multipartBody(boundary: String) -> Data {
        var body = Data()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append(value.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }

        appendField(name: "species", value: species.rawValue)
        appendField(name: "sex", value: sex.rawValue)
        appendField(name: "foundAt", value: isoFormatter.string(from: foundAt))
        appendField(name: "lat", value: String(lat))
        appendField(name: "lng", value: String(lng))

        if let breed, !breed.isEmpty { appendField(name: "breed", value: breed) }
        if let color, !color.isEmpty { appendField(name: "color", value: color) }
        if let description, !description.isEmpty { appendField(name: "description", value: description) }
        if let foundAddress, !foundAddress.isEmpty { appendField(name: "foundAddress", value: foundAddress) }
        if let reporterName, !reporterName.isEmpty { appendField(name: "reporterName", value: reporterName) }
        if let reporterEmail, !reporterEmail.isEmpty { appendField(name: "reporterEmail", value: reporterEmail) }
        if let reporterPhone, !reporterPhone.isEmpty { appendField(name: "reporterPhone", value: reporterPhone) }

        if let photoData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"found-pet.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(photoData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
