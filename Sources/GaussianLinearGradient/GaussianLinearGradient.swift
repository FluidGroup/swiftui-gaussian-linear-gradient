import Darwin
@preconcurrency import SwiftUI

/// A linear gradient whose color ramp approximates Gaussian-blurred transitions.
///
/// `GaussianLinearGradient` renders with SwiftUI's `LinearGradient`, but uses
/// stops sampled from the cumulative normal distribution. This produces
/// one-dimensional color transitions that resemble the coverage of blurred edges
/// without requiring a custom shader.
public struct GaussianLinearGradient: View, ShapeStyle {

  /// The source gradient whose color ramp is rendered with Gaussian sampling.
  ///
  /// This mirrors the primary `LinearGradient` initializer so callers can provide
  /// any number of colors or explicit stops.
  public let gradient: Gradient

  /// The unit-space start point passed through to `LinearGradient`.
  public let startPoint: UnitPoint

  /// The unit-space end point passed through to `LinearGradient`.
  public let endPoint: UnitPoint

  /// The number of samples used to approximate each continuous Gaussian transition.
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
  ///   - gradient: The source gradient whose stops define the colors to render.
  ///   - startPoint: The unit-space start point passed through to `LinearGradient`.
  ///   - endPoint: The unit-space end point passed through to `LinearGradient`.
  ///   - sampleCount: The number of samples used for each color transition.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  nonisolated public init(
    gradient: Gradient,
    startPoint: UnitPoint,
    endPoint: UnitPoint,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) {
    self.gradient = gradient
    self.startPoint = startPoint
    self.endPoint = endPoint
    self.sampleCount = sampleCount
    self.standardDeviation = standardDeviation
  }

  /// Creates a Gaussian-like linear gradient from an evenly spaced color list.
  ///
  /// This initializer matches `LinearGradient(colors:startPoint:endPoint:)`.
  ///
  /// - Parameters:
  ///   - colors: The colors to distribute evenly along the gradient.
  ///   - startPoint: The unit-space start point passed through to `LinearGradient`.
  ///   - endPoint: The unit-space end point passed through to `LinearGradient`.
  ///   - sampleCount: The number of samples used for each color transition.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  nonisolated public init(
    colors: [Color],
    startPoint: UnitPoint,
    endPoint: UnitPoint,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) {
    self.init(
      gradient: Gradient(colors: colors),
      startPoint: startPoint,
      endPoint: endPoint,
      sampleCount: sampleCount,
      standardDeviation: standardDeviation
    )
  }

  /// Creates a Gaussian-like linear gradient from explicitly located stops.
  ///
  /// This initializer matches `LinearGradient(stops:startPoint:endPoint:)`.
  ///
  /// - Parameters:
  ///   - stops: The explicitly located gradient stops to render.
  ///   - startPoint: The unit-space start point passed through to `LinearGradient`.
  ///   - endPoint: The unit-space end point passed through to `LinearGradient`.
  ///   - sampleCount: The number of samples used for each color transition.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  nonisolated public init(
    stops: [Gradient.Stop],
    startPoint: UnitPoint,
    endPoint: UnitPoint,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) {
    self.init(
      gradient: Gradient(stops: stops),
      startPoint: startPoint,
      endPoint: endPoint,
      sampleCount: sampleCount,
      standardDeviation: standardDeviation
    )
  }

  /// Creates a Gaussian-like linear gradient between two colors.
  ///
  /// This preserves the original two-color API. Prefer
  /// `init(colors:startPoint:endPoint:sampleCount:standardDeviation:)` or
  /// `init(stops:startPoint:endPoint:sampleCount:standardDeviation:)` when the
  /// gradient has more than two colors.
  ///
  /// - Parameters:
  ///   - startColor: The color rendered at location `0`, nearest `startPoint`.
  ///   - endColor: The color rendered at location `1`, nearest `endPoint`.
  ///   - startPoint: The unit-space start point passed through to `LinearGradient`.
  ///   - endPoint: The unit-space end point passed through to `LinearGradient`.
  ///   - sampleCount: The number of samples used for the color transition.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  nonisolated public init(
    startColor: Color = .clear,
    endColor: Color = .black,
    startPoint: UnitPoint = .top,
    endPoint: UnitPoint = .bottom,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) {
    self.init(
      colors: [startColor, endColor],
      startPoint: startPoint,
      endPoint: endPoint,
      sampleCount: sampleCount,
      standardDeviation: standardDeviation
    )
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
  ///   - sampleCount: The number of samples used for the color transition.
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
        resolvedStops: gradient.stops.map {
          ResolvedGradientStop(
            color: $0.color.resolve(in: environment),
            location: $0.location
          )
        },
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
  ///   - sampleCount: The number of samples used for the color transition.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  /// - Returns: Stops suitable for constructing a SwiftUI `LinearGradient`.
  nonisolated public static func stops(
    startColor: Color.Resolved,
    endColor: Color.Resolved,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) -> [Gradient.Stop] {
    stops(
      resolvedStops: [
        ResolvedGradientStop(color: startColor, location: 0),
        ResolvedGradientStop(color: endColor, location: 1),
      ],
      sampleCount: sampleCount,
      standardDeviation: standardDeviation
    )
  }

  /// Creates gradient stops that approximate Gaussian transitions through many colors.
  ///
  /// The supplied colors are distributed evenly, matching `Gradient(colors:)`.
  /// Each neighboring color pair is sampled independently so three or more colors
  /// keep their interior color stops.
  ///
  /// - Parameters:
  ///   - colors: The resolved colors to distribute evenly along the gradient.
  ///   - sampleCount: The number of samples used for each color transition.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  /// - Returns: Stops suitable for constructing a SwiftUI `LinearGradient`.
  nonisolated public static func stops(
    colors: [Color.Resolved],
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) -> [Gradient.Stop] {
    stops(
      resolvedStops: resolvedStops(from: colors),
      sampleCount: sampleCount,
      standardDeviation: standardDeviation
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
  ///   - sampleCount: The number of samples used for the color transition.
  ///   - standardDeviation: The standard deviation in normalized gradient coordinates.
  /// - Returns: Stops suitable for constructing a SwiftUI `LinearGradient`.
  nonisolated public static func stops(
    color: Color = .black,
    transparentAtStart: Bool = true,
    sampleCount: Int = 24,
    standardDeviation: CGFloat = 0.22
  ) -> [Gradient.Stop] {
    sampledStops(
      startLocation: 0,
      endLocation: 1,
      sampleCount: sampleCount,
      standardDeviation: standardDeviation
    ) { coverage in
      let alpha = transparentAtStart ? coverage : 1 - coverage
      return color.opacity(Double(alpha))
    }
  }

  nonisolated private static func sampledStops(
    startLocation: CGFloat,
    endLocation: CGFloat,
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
      let fraction = CGFloat(index) / CGFloat(clampedSampleCount - 1)
      let rawCoverage = normalCDF((fraction - 0.5) / clampedStandardDeviation)
      let coverage = normalizedGaussianCoverage(
        rawCoverage: rawCoverage,
        lowerBound: lowerBound,
        normalizationRange: normalizationRange
      )

      return Gradient.Stop(
        color: color(coverage),
        location: startLocation + (endLocation - startLocation) * fraction
      )
    }
  }

  nonisolated private static func stops(
    resolvedStops: [ResolvedGradientStop],
    sampleCount: Int,
    standardDeviation: CGFloat
  ) -> [Gradient.Stop] {
    let stops = normalizedStops(resolvedStops)

    return stops.indices.dropLast().flatMap { index in
      let startStop = stops[index]
      let endStop = stops[index + 1]
      let segmentStops = sampledStops(
        startLocation: startStop.location,
        endLocation: endStop.location,
        sampleCount: sampleCount,
        standardDeviation: standardDeviation
      ) { coverage in
        Color(interpolatedColor(from: startStop.color, to: endStop.color, fraction: coverage))
      }

      return index == stops.startIndex ? segmentStops : Array(segmentStops.dropFirst())
    }
  }

  nonisolated private static func resolvedStops(from colors: [Color.Resolved]) -> [ResolvedGradientStop] {
    guard colors.count > 1 else {
      return colors.first.map { [ResolvedGradientStop(color: $0, location: 0)] } ?? []
    }

    return colors.enumerated().map { index, color in
      ResolvedGradientStop(
        color: color,
        location: CGFloat(index) / CGFloat(colors.count - 1)
      )
    }
  }

  nonisolated private static func normalizedStops(
    _ stops: [ResolvedGradientStop]
  ) -> [ResolvedGradientStop] {
    guard let firstStop = stops.first else {
      return [
        ResolvedGradientStop(color: .transparentBlack, location: 0),
        ResolvedGradientStop(color: .transparentBlack, location: 1),
      ]
    }

    guard stops.count > 1 else {
      return [
        ResolvedGradientStop(color: firstStop.color, location: 0),
        ResolvedGradientStop(color: firstStop.color, location: 1),
      ]
    }

    return stops
      .enumerated()
      .map { stop in
        (
          offset: stop.offset,
          stop: ResolvedGradientStop(
            color: stop.element.color,
            location: min(max(stop.element.location, 0), 1)
          )
        )
      }
      .sorted { lhs, rhs in
        if lhs.stop.location == rhs.stop.location {
          return lhs.offset < rhs.offset
        }

        return lhs.stop.location < rhs.stop.location
      }
      .map(\.stop)
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

/// A color stop after resolving SwiftUI environment-dependent color values.
private struct ResolvedGradientStop {

  /// The color resolved against the current SwiftUI environment.
  let color: Color.Resolved

  /// The unit-space location of the stop inside the source gradient.
  let location: CGFloat
}

private extension Color.Resolved {

  /// A transparent fallback color used when the source gradient has no stops.
  static let transparentBlack = Color.Resolved(
    colorSpace: .sRGBLinear,
    red: 0,
    green: 0,
    blue: 0,
    opacity: 0
  )
}
