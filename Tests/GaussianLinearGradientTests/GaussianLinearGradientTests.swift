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
func colorStopsSupportThreeOrMoreResolvedColors() {
  let red = Color.Resolved(
    colorSpace: .sRGBLinear,
    red: 1,
    green: 0,
    blue: 0,
    opacity: 1
  )
  let green = Color.Resolved(
    colorSpace: .sRGBLinear,
    red: 0,
    green: 1,
    blue: 0,
    opacity: 1
  )
  let blue = Color.Resolved(
    colorSpace: .sRGBLinear,
    red: 0,
    green: 0,
    blue: 1,
    opacity: 1
  )

  let stops = GaussianLinearGradient.stops(
    colors: [red, green, blue],
    sampleCount: 3
  )

  let middle = stops[2].color.resolve(in: EnvironmentValues())

  #expect(stops.count == 5)
  #expect(stops.map(\.location) == [0, 0.25, 0.5, 0.75, 1])
  #expect(abs(middle.linearRed - 0) < 0.0001)
  #expect(abs(middle.linearGreen - 1) < 0.0001)
  #expect(abs(middle.linearBlue - 0) < 0.0001)
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
func linearGradientStyleInitializersAcceptMultipleColorsAndStops() {
  let colorsStyle = GaussianLinearGradient(
    colors: [.red, .green, .blue],
    startPoint: .leading,
    endPoint: .trailing
  )
  let stopsStyle = GaussianLinearGradient(
    stops: [
      Gradient.Stop(color: .red, location: 0),
      Gradient.Stop(color: .green, location: 0.35),
      Gradient.Stop(color: .blue, location: 1),
    ],
    startPoint: .leading,
    endPoint: .trailing
  )
  let gradientStyle = GaussianLinearGradient(
    gradient: Gradient(colors: [.red, .green, .blue]),
    startPoint: .top,
    endPoint: .bottom
  )

  _ = AnyShapeStyle(colorsStyle)
  _ = AnyShapeStyle(stopsStyle)
  _ = Rectangle().fill(gradientStyle)
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
