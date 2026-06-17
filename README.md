# GaussianLinearGradient

A SwiftUI `LinearGradient` wrapper that approximates Gaussian-blurred color transitions.

<img src="Docs/gaussian-gradient-short-comparison.png" alt="LinearGradient and GaussianLinearGradient comparison with short gradient lengths" width="760">

```swift
import GaussianLinearGradient
import SwiftUI

GaussianLinearGradient(
  colors: [.clear, .blue, .indigo],
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
      colors: [.clear, .blue, .indigo],
      startPoint: .leading,
      endPoint: .trailing
    )
  )
```

The main initializers mirror SwiftUI's `LinearGradient`:

```swift
GaussianLinearGradient(
  gradient: Gradient(colors: [.red, .yellow, .blue]),
  startPoint: .leading,
  endPoint: .trailing
)

GaussianLinearGradient(
  colors: [.red, .yellow, .blue],
  startPoint: .leading,
  endPoint: .trailing
)

GaussianLinearGradient(
  stops: [
    Gradient.Stop(color: .red, location: 0),
    Gradient.Stop(color: .yellow, location: 0.35),
    Gradient.Stop(color: .blue, location: 1),
  ],
  startPoint: .leading,
  endPoint: .trailing
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
