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
