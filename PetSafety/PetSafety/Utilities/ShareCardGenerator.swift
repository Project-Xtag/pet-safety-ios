import UIKit

struct ShareCardGenerator {
    static func generate(petName: String, petImage: UIImage?, petSpecies: String, city: String? = nil) -> UIImage {
        let size = CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // Teal background
            UIColor(red: 77/255, green: 184/255, blue: 196/255, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Logo (compact)
            if let logo = UIImage(named: "LogoNew") {
                let logoHeight: CGFloat = 60
                let logoWidth = (logo.size.width / logo.size.height) * logoHeight
                let logoRect = CGRect(
                    x: (size.width - logoWidth) / 2,
                    y: 25,
                    width: logoWidth,
                    height: logoHeight
                )
                logo.draw(in: logoRect)
            } else {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 36),
                    .foregroundColor: UIColor.white
                ]
                let text = "TagMe Now"
                let textSize = text.size(withAttributes: attrs)
                text.draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: 35), withAttributes: attrs)
            }

            // "Reunited!" text
            let reunitedAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.white
            ]
            let reunitedText = "Reunited!"
            let reunitedSize = reunitedText.size(withAttributes: reunitedAttrs)
            reunitedText.draw(
                at: CGPoint(x: (size.width - reunitedSize.width) / 2, y: 95),
                withAttributes: reunitedAttrs
            )

            // Top divider
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: 140, y: 155))
            ctx.addLine(to: CGPoint(x: size.width - 140, y: 155))
            ctx.strokePath()

            // Pet photo (circular) — maximized
            let photoRadius: CGFloat = 270
            let photoCenterX = size.width / 2
            let photoCenterY: CGFloat = 460

            // White border circle
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(
                x: photoCenterX - photoRadius - 6,
                y: photoCenterY - photoRadius - 6,
                width: (photoRadius + 6) * 2,
                height: (photoRadius + 6) * 2
            ))

            if let petImage = petImage {
                let photoRect = CGRect(
                    x: photoCenterX - photoRadius,
                    y: photoCenterY - photoRadius,
                    width: photoRadius * 2,
                    height: photoRadius * 2
                )
                ctx.saveGState()
                ctx.addEllipse(in: photoRect)
                ctx.clip()
                petImage.draw(in: photoRect)
                ctx.restoreGState()
            } else {
                // Placeholder circle
                ctx.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
                ctx.fillEllipse(in: CGRect(
                    x: photoCenterX - photoRadius,
                    y: photoCenterY - photoRadius,
                    width: photoRadius * 2,
                    height: photoRadius * 2
                ))
                let pawAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 140),
                    .foregroundColor: UIColor.white
                ]
                let paw = "🐾"
                let pawSize = paw.size(withAttributes: pawAttrs)
                paw.draw(
                    at: CGPoint(x: photoCenterX - pawSize.width / 2, y: photoCenterY - pawSize.height / 2),
                    withAttributes: pawAttrs
                )
            }

            // Pet name + city
            let nameText: String
            if let city = city, !city.isEmpty {
                nameText = "\(petName), \(city)"
            } else {
                nameText = petName
            }
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 44),
                .foregroundColor: UIColor.white
            ]
            let nameSize = nameText.size(withAttributes: nameAttrs)
            nameText.draw(
                at: CGPoint(x: (size.width - nameSize.width) / 2, y: 768),
                withAttributes: nameAttrs
            )

            // Bottom divider
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: 140, y: 845))
            ctx.addLine(to: CGPoint(x: size.width - 140, y: 845))
            ctx.strokePath()

            // Website URL
            let urlAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28),
                .foregroundColor: UIColor.white
            ]
            let urlText = "senra.pet"
            let urlSize = urlText.size(withAttributes: urlAttrs)
            urlText.draw(
                at: CGPoint(x: (size.width - urlSize.width) / 2, y: 880),
                withAttributes: urlAttrs
            )
        }
    }
}
