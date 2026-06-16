# GaussianLinearGradient

A SwiftUI `LinearGradient` wrapper that approximates the color ramp of a Gaussian-blurred hard edge.

<img src="Docs/gaussian-gradient-short-comparison.png" alt="LinearGradient and GaussianLinearGradient comparison with short gradient lengths" width="760">

```swift
import GaussianLinearGradient
import SwiftUI

GaussianLinearGradient(
  startColor: .clear,
  endColor: .blue,
  startPoint: .bottom,
  endPoint: .top,
  sampleCount: 24,
  standardDeviation: 0.22
)
.frame(height: 72)
```

`GaussianLinearGradient` also conforms to `ShapeStyle`, so you can use it wherever SwiftUI accepts a style:

```swift
RoundedRectangle(cornerRadius: 12)
  .fill(
    GaussianLinearGradient(
      startColor: .clear,
      endColor: .blue,
      startPoint: .leading,
      endPoint: .trailing
    )
  )
```

## Stops

Use `GaussianLinearGradient.stops(...)` when you want to build your own opacity-ramp `LinearGradient` without resolving colors from the environment:

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
