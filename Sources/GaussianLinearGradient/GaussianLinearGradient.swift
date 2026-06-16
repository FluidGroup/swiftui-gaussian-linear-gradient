import Darwin
import SwiftUI

/// A linear gradient whose color ramp approximates a Gaussian-blurred hard edge.
///
/// `GaussianLinearGradient` renders with SwiftUI's `LinearGradient`, but uses
/// stops sampled from the cumulative normal distribution. This produces a
/// one-dimensional color transition that resembles the coverage of a blurred edge
/// without requiring a custom shader.
public struct GaussianLinearGradient: View, ShapeStyle {

  /// The color rendered at the beginning of the gradient's Gaussian ramp.
  public let startColor: Color

  /// The color rendered at the end of the gradient's Gaussian ramp.
  public let endColor: Color

  /// The unit-space start point passed through to `LinearGradient`.
  public let startPoint: UnitPoint

  /// The unit-space end point passed through to `LinearGradient`.
  public let endPoint: UnitPoint

  /// The number of stops used to approximate the continuous Gaussian curve.
  public let sampleCount: Int

  /// The standard deviation in normalized gradient coordinates.
  ///
  /// Smaller values make the transition harder around the center of the gradient.
  /// Larger values spread the fade more evenly across the whole gradient.
  public let standardDeviation: CGFloat

  @Environment(\.self) private var environment

  /// Creates a Gaussian-like linear gradient.
  ///
  /// - Parameters:
  ///   - startColor: The color rendered at location `0`, nearest `startPoint`.
  ///   - endColor: The color rendered at location `1`, nearest `endPoint`.
  ///   - startPoint: The unit-space start point passed through to `LinearGradient`.
  ///   - endPoint: The unit-space end point passed through to `LinearGradient`.
  ///   - sampleCount: The number of stops used to approximate the continuous curve.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  nonisolated public init(
    startColor: Color = .clear,
    endColor: Color = .black,
    startPoint: UnitPoint = .top,
    endPoint: UnitPoint = .bottom,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) {
    self.startColor = startColor
    self.endColor = endColor
    self.startPoint = startPoint
    self.endPoint = endPoint
    self.sampleCount = sampleCount
    self.standardDeviation = standardDeviation
  }

  /// Creates a Gaussian-like fade between transparency and one color.
  ///
  /// This initializer preserves the original single-color API. Use
  /// `init(startColor:endColor:startPoint:endPoint:sampleCount:standardDeviation:)`
  /// when the gradient should transition between two explicit colors.
  ///
  /// - Parameters:
  ///   - color: The color used at the opaque side of the gradient.
  ///   - transparentAtStart: Whether location `0` should be transparent.
  ///   - startPoint: The unit-space start point passed through to `LinearGradient`.
  ///   - endPoint: The unit-space end point passed through to `LinearGradient`.
  ///   - sampleCount: The number of stops used to approximate the continuous curve.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  nonisolated public init(
    color: Color,
    transparentAtStart: Bool = true,
    startPoint: UnitPoint = .top,
    endPoint: UnitPoint = .bottom,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) {
    self.init(
      startColor: transparentAtStart ? .clear : color,
      endColor: transparentAtStart ? color : .clear,
      startPoint: startPoint,
      endPoint: endPoint,
      sampleCount: sampleCount,
      standardDeviation: standardDeviation
    )
  }

  public var body: LinearGradient {
    resolve(in: environment)
  }

  /// Resolves the Gaussian-like ramp into a concrete SwiftUI linear gradient.
  ///
  /// SwiftUI asks shape styles to resolve environment-dependent values before
  /// drawing. Returning `LinearGradient` keeps this style compatible with
  /// `fill`, `background`, and other `ShapeStyle`-based APIs while preserving
  /// the same rendering path used by the view body.
  ///
  /// - Parameter environment: The environment used to resolve dynamic colors.
  /// - Returns: A `LinearGradient` whose stops follow the Gaussian coverage curve.
  nonisolated public func resolve(in environment: EnvironmentValues) -> LinearGradient {
    LinearGradient(
      stops: Self.stops(
        startColor: startColor.resolve(in: environment),
        endColor: endColor.resolve(in: environment),
        sampleCount: sampleCount,
        standardDeviation: standardDeviation
      ),
      startPoint: startPoint,
      endPoint: endPoint
    )
  }

  /// Creates gradient stops that approximate a blurred transition between two colors.
  ///
  /// This overload accepts resolved colors so the interpolation works on iOS 17 and
  /// macOS 14, where `Color.mix(with:by:in:)` is not available.
  ///
  /// - Parameters:
  ///   - startColor: The resolved color rendered at location `0`.
  ///   - endColor: The resolved color rendered at location `1`.
  ///   - sampleCount: The number of stops used to approximate the continuous curve.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  /// - Returns: Stops suitable for constructing a SwiftUI `LinearGradient`.
  nonisolated public static func stops(
    startColor: Color.Resolved,
    endColor: Color.Resolved,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) -> [Gradient.Stop] {
    sampledStops(sampleCount: sampleCount, standardDeviation: standardDeviation) { coverage in
      Color(interpolatedColor(from: startColor, to: endColor, fraction: coverage))
    }
  }

  /// Creates gradient stops that approximate the opacity ramp of a blurred hard edge.
  ///
  /// A Gaussian blur spreads an edge by integrating the blur kernel across the edge,
  /// so this samples the cumulative normal distribution rather than the bell curve itself.
  ///
  /// - Parameters:
  ///   - color: The color used at the opaque side of the gradient.
  ///   - transparentAtStart: Whether location `0` should be transparent.
  ///   - sampleCount: The number of stops used to approximate the continuous curve.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  /// - Returns: Stops suitable for constructing a SwiftUI `LinearGradient`.
  nonisolated public static func stops(
    color: Color = .black,
    transparentAtStart: Bool = true,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) -> [Gradient.Stop] {
    sampledStops(sampleCount: sampleCount, standardDeviation: standardDeviation) { coverage in
      let alpha = transparentAtStart ? coverage : 1 - coverage
      return color.opacity(Double(alpha))
    }
  }

  nonisolated private static func sampledStops(
    sampleCount: Int,
    standardDeviation: CGFloat,
    color: (CGFloat) -> Color
  ) -> [Gradient.Stop] {
    let clampedSampleCount = max(sampleCount, 2)
    let clampedStandardDeviation = max(standardDeviation, 0.0001)
    let lowerBound = normalCDF(-0.5 / clampedStandardDeviation)
    let upperBound = normalCDF(0.5 / clampedStandardDeviation)
    let normalizationRange = max(upperBound - lowerBound, 0.0001)

    return (0..<clampedSampleCount).map { index in
      let location = CGFloat(index) / CGFloat(clampedSampleCount - 1)
      let rawCoverage = normalCDF((location - 0.5) / clampedStandardDeviation)
      let coverage = normalizedGaussianCoverage(
        rawCoverage: rawCoverage,
        lowerBound: lowerBound,
        normalizationRange: normalizationRange
      )

      return Gradient.Stop(
        color: color(coverage),
        location: location
      )
    }
  }

  nonisolated static func interpolatedColor(
    from startColor: Color.Resolved,
    to endColor: Color.Resolved,
    fraction: CGFloat
  ) -> Color.Resolved {
    let fraction = Float(min(max(fraction, 0), 1))

    return Color.Resolved(
      colorSpace: .sRGBLinear,
      red: startColor.linearRed + (endColor.linearRed - startColor.linearRed) * fraction,
      green: startColor.linearGreen + (endColor.linearGreen - startColor.linearGreen) * fraction,
      blue: startColor.linearBlue + (endColor.linearBlue - startColor.linearBlue) * fraction,
      opacity: startColor.opacity + (endColor.opacity - startColor.opacity) * fraction
    )
  }

  nonisolated static func normalizedGaussianCoverage(
    at location: CGFloat,
    standardDeviation: CGFloat
  ) -> CGFloat {
    let clampedStandardDeviation = max(standardDeviation, 0.0001)
    let lowerBound = normalCDF(-0.5 / clampedStandardDeviation)
    let upperBound = normalCDF(0.5 / clampedStandardDeviation)
    let normalizationRange = max(upperBound - lowerBound, 0.0001)
    let rawCoverage = normalCDF((location - 0.5) / clampedStandardDeviation)

    return normalizedGaussianCoverage(
      rawCoverage: rawCoverage,
      lowerBound: lowerBound,
      normalizationRange: normalizationRange
    )
  }

  nonisolated private static func normalizedGaussianCoverage(
    rawCoverage: CGFloat,
    lowerBound: CGFloat,
    normalizationRange: CGFloat
  ) -> CGFloat {
    return min(max((rawCoverage - lowerBound) / normalizationRange, 0), 1)
  }

  nonisolated private static func normalCDF(_ value: CGFloat) -> CGFloat {
    CGFloat(0.5 * (1 + erf(Double(value) / sqrt(2))))
  }
}
