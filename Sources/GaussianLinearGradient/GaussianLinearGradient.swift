import Darwin
import SwiftUI

/// A linear gradient whose opacity approximates a Gaussian-blurred hard edge.
///
/// `GaussianLinearGradient` renders with SwiftUI's `LinearGradient`, but uses
/// stops sampled from the cumulative normal distribution. This produces a
/// one-dimensional fade that resembles the opacity coverage of a blurred edge
/// without requiring a custom shader.
public struct GaussianLinearGradient: View {

  /// The color used at the opaque side of the gradient.
  public var color: Color

  /// Whether the stop at location `0`, nearest `startPoint`, should be transparent.
  public var transparentAtStart: Bool

  /// The unit-space start point passed through to `LinearGradient`.
  public var startPoint: UnitPoint

  /// The unit-space end point passed through to `LinearGradient`.
  public var endPoint: UnitPoint

  /// The number of stops used to approximate the continuous Gaussian curve.
  public var sampleCount: Int

  /// The standard deviation in normalized gradient coordinates.
  ///
  /// Smaller values make the transition harder around the center of the gradient.
  /// Larger values spread the fade more evenly across the whole gradient.
  public var standardDeviation: CGFloat

  /// Creates a Gaussian-like linear gradient.
  ///
  /// - Parameters:
  ///   - color: The color used at the opaque side of the gradient.
  ///   - transparentAtStart: Whether location `0` should be transparent.
  ///   - startPoint: The unit-space start point passed through to `LinearGradient`.
  ///   - endPoint: The unit-space end point passed through to `LinearGradient`.
  ///   - sampleCount: The number of stops used to approximate the continuous curve.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  public init(
    color: Color = .black,
    transparentAtStart: Bool = true,
    startPoint: UnitPoint = .top,
    endPoint: UnitPoint = .bottom,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) {
    self.color = color
    self.transparentAtStart = transparentAtStart
    self.startPoint = startPoint
    self.endPoint = endPoint
    self.sampleCount = sampleCount
    self.standardDeviation = standardDeviation
  }

  public var body: some View {
    LinearGradient(
      stops: Self.stops(
        color: color,
        transparentAtStart: transparentAtStart,
        sampleCount: sampleCount,
        standardDeviation: standardDeviation
      ),
      startPoint: startPoint,
      endPoint: endPoint
    )
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
    let clampedSampleCount = max(sampleCount, 2)
    let clampedStandardDeviation = max(standardDeviation, 0.0001)

    return (0..<clampedSampleCount).map { index in
      let location = CGFloat(index) / CGFloat(clampedSampleCount - 1)
      let coverage = normalizedGaussianCoverage(
        at: location,
        standardDeviation: clampedStandardDeviation
      )
      let alpha = transparentAtStart ? coverage : 1 - coverage

      return Gradient.Stop(
        color: color.opacity(Double(alpha)),
        location: location
      )
    }
  }

  nonisolated static func normalizedGaussianCoverage(
    at location: CGFloat,
    standardDeviation: CGFloat
  ) -> CGFloat {
    let lowerBound = normalCDF(-0.5 / standardDeviation)
    let upperBound = normalCDF(0.5 / standardDeviation)
    let normalizationRange = max(upperBound - lowerBound, 0.0001)
    let rawCoverage = normalCDF((location - 0.5) / standardDeviation)

    return min(max((rawCoverage - lowerBound) / normalizationRange, 0), 1)
  }

  nonisolated private static func normalCDF(_ value: CGFloat) -> CGFloat {
    CGFloat(0.5 * (1 + erf(Double(value) / sqrt(2))))
  }
}
