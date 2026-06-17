#if DEBUG
import SwiftUI

#Preview("Short gradients") {
  GaussianLinearGradientComparisonPreview()
}

#Preview("ShapeStyle fill") {
  GaussianLinearGradientShapeStylePreview()
}

private struct GaussianLinearGradientComparisonPreview: View {

  private let ramps: [PreviewRamp] = [
    PreviewRamp(title: "clear -> blue", colors: [.clear, .blue]),
    PreviewRamp(title: "pink -> orange", colors: [.pink, .orange]),
    PreviewRamp(title: "red -> yellow -> blue", colors: [.red, .yellow, .blue]),
    PreviewRamp(title: "mint -> cyan -> indigo", colors: [.mint, .cyan, .indigo]),
    PreviewRamp(title: "black -> clear", colors: [.black, .clear]),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      PreviewHeader(
        title: "LinearGradient vs GaussianLinearGradient",
        subtitle: "Short 220pt length"
      )

      VStack(alignment: .leading, spacing: 18) {
        ForEach(ramps) { ramp in
          ComparisonRow(ramp: ramp)
        }
      }
    }
    .padding(24)
    .frame(width: 560, alignment: .topLeading)
  }
}

private struct GaussianLinearGradientShapeStylePreview: View {

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      PreviewHeader(
        title: "ShapeStyle",
        subtitle: "Use GaussianLinearGradient directly in fill"
      )

      RoundedRectangle(cornerRadius: 18)
        .fill(
          GaussianLinearGradient(
            colors: [.clear, .blue, .indigo],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(width: 320, height: 160)

      Circle()
        .fill(
          GaussianLinearGradient(
            colors: [.pink, .orange, .yellow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 160, height: 160)
    }
    .padding(24)
    .frame(width: 380, alignment: .topLeading)
  }
}

private struct PreviewHeader: View {

  let title: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.headline)
      Text(subtitle)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }
}

private struct ComparisonRow: View {

  let ramp: PreviewRamp

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(ramp.title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      HStack(alignment: .top, spacing: 16) {
        GradientSwatch(title: "LinearGradient") {
          LinearGradient(
            colors: ramp.colors,
            startPoint: .leading,
            endPoint: .trailing
          )
        }

        GradientSwatch(title: "GaussianLinearGradient") {
          GaussianLinearGradient(
            colors: ramp.colors,
            startPoint: .leading,
            endPoint: .trailing
          )
        }
      }
    }
  }
}

private struct GradientSwatch<Content: View>: View {

  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.caption2)
        .foregroundStyle(.secondary)

      content
        .frame(width: 220, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(.quaternary, lineWidth: 1)
        }
    }
  }
}

private struct PreviewRamp: Identifiable {

  let title: String
  let colors: [Color]

  var id: String {
    title
  }
}
#endif
