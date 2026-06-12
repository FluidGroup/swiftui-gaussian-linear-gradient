# GaussianLinearGradient

A SwiftUI `LinearGradient` wrapper that approximates the opacity ramp of a Gaussian-blurred hard edge.

```swift
import GaussianLinearGradient
import SwiftUI

GaussianLinearGradient(
  color: .black,
  transparentAtStart: false,
  startPoint: .bottom,
  endPoint: .top,
  sampleCount: 24,
  standardDeviation: 0.22
)
.frame(height: 72)
```

## Stops

Use `GaussianLinearGradient.stops(...)` when you want to build your own `LinearGradient`:

```swift
LinearGradient(
  stops: GaussianLinearGradient.stops(
    color: .black,
    transparentAtStart: true
  ),
  startPoint: .top,
  endPoint: .bottom
)
```
