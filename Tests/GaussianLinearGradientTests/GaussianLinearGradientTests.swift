import SwiftUI
import Testing
@testable import GaussianLinearGradient

@Test
func stopsUseRequestedSampleCountAndNormalizedLocations() {
  let stops = GaussianLinearGradient.stops(sampleCount: 5)

  #expect(stops.count == 5)
  #expect(stops.map(\.location) == [0, 0.25, 0.5, 0.75, 1])
}

@Test
func stopsClampSampleCountToAtLeastTwo() {
  let stops = GaussianLinearGradient.stops(sampleCount: 0)

  #expect(stops.count == 2)
  #expect(stops.map(\.location) == [0, 1])
}

@Test
func colorStopsInterpolateResolvedStartAndEndColors() {
  let startColor = Color.Resolved(
    colorSpace: .sRGBLinear,
    red: 1,
    green: 0,
    blue: 0,
    opacity: 0.25
  )
  let endColor = Color.Resolved(
    colorSpace: .sRGBLinear,
    red: 0,
    green: 0,
    blue: 1,
    opacity: 1
  )

  let stops = GaussianLinearGradient.stops(
    startColor: startColor,
    endColor: endColor,
    sampleCount: 3
  )

  let first = stops[0].color.resolve(in: EnvironmentValues())
  let middle = stops[1].color.resolve(in: EnvironmentValues())
  let last = stops[2].color.resolve(in: EnvironmentValues())

  #expect(abs(first.linearRed - 1) < 0.0001)
  #expect(abs(first.linearBlue - 0) < 0.0001)
  #expect(abs(first.opacity - 0.25) < 0.0001)
  #expect(abs(middle.linearRed - 0.5) < 0.0001)
  #expect(abs(middle.linearBlue - 0.5) < 0.0001)
  #expect(abs(last.linearRed - 0) < 0.0001)
  #expect(abs(last.linearBlue - 1) < 0.0001)
  #expect(abs(last.opacity - 1) < 0.0001)
}

@Test
func gaussianLinearGradientCanBeUsedAsShapeStyle() {
  let style = GaussianLinearGradient(
    startColor: .clear,
    endColor: .blue,
    startPoint: .leading,
    endPoint: .trailing,
    sampleCount: 3
  )

  let resolved: LinearGradient = style.resolve(in: EnvironmentValues())
  _ = AnyShapeStyle(style)
  _ = Rectangle().fill(style)

  #expect(type(of: resolved) == LinearGradient.self)
}

@Test
func normalizedGaussianCoverageIsMonotonic() {
  let samples = stride(from: CGFloat(0), through: 1, by: 0.1).map {
    GaussianLinearGradient.normalizedGaussianCoverage(
      at: $0,
      standardDeviation: 0.22
    )
  }

  #expect(samples == samples.sorted())
}

@Test
func normalizedGaussianCoverageIsSymmetricAroundCenter() {
  let low = GaussianLinearGradient.normalizedGaussianCoverage(
    at: 0.25,
    standardDeviation: 0.22
  )
  let high = GaussianLinearGradient.normalizedGaussianCoverage(
    at: 0.75,
    standardDeviation: 0.22
  )

  #expect(abs((low + high) - 1) < 0.0001)
}
