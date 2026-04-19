import CoreGraphics

public enum HUDLayoutResolver {
    public static func defaultFrame(in screenFrame: CGRect, size: CGSize, margin: CGFloat) -> CGRect {
        CGRect(
            x: screenFrame.maxX - size.width - margin,
            y: screenFrame.maxY - size.height - margin,
            width: size.width,
            height: size.height
        )
    }

    public static func resolve(
        savedFrame: CGRect?,
        screens: [CGRect],
        fallbackScreen: CGRect,
        size: CGSize,
        margin: CGFloat = 24
    ) -> CGRect {
        guard let savedFrame else {
            return defaultFrame(in: fallbackScreen, size: size, margin: margin)
        }

        if screens.contains(where: { $0.intersects(savedFrame) }) {
            return savedFrame
        }

        return defaultFrame(in: fallbackScreen, size: size, margin: margin)
    }
}
