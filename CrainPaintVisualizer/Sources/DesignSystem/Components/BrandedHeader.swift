import SwiftUI

struct HeroHeader<Accessory: View>: View {
    @Environment(Theme.self) private var theme

    let eyebrow: String?
    let title: String
    var subtitle: String? = nil
    var footnote: String? = nil
    let accessory: () -> Accessory

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        footnote: String? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.footnote = footnote
        self.accessory = accessory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space12) {
            HStack(alignment: .center, spacing: theme.space12) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(theme.micro.weight(.bold))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, theme.space12)
                        .padding(.vertical, theme.space8)
                        .background(theme.primary.opacity(0.1))
                        .clipShape(Capsule())
                }

                Spacer(minLength: theme.space8)

                accessory()
            }

            Text(title)
                .font(theme.displayMedium)
                .foregroundStyle(theme.foreground)
                .multilineTextAlignment(.leading)

            if let subtitle {
                Text(subtitle)
                    .font(theme.bodyDefault)
                    .foregroundStyle(theme.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let footnote {
                Text(footnote)
                    .font(theme.captionSmall)
                    .foregroundStyle(theme.mutedForeground)
            }
        }
    }
}

extension HeroHeader where Accessory == EmptyView {
    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        footnote: String? = nil
    ) {
        self.init(eyebrow: eyebrow, title: title, subtitle: subtitle, footnote: footnote) {
            EmptyView()
        }
    }
}

struct CompactScreenHeader<Trailing: View>: View {
    @Environment(Theme.self) private var theme

    let title: String
    var subtitle: String? = nil
    var eyebrow: String? = nil
    var detail: String? = nil
    let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        eyebrow: String? = nil,
        detail: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.eyebrow = eyebrow
        self.detail = detail
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top, spacing: theme.space12) {
            VStack(alignment: .leading, spacing: theme.space8) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(theme.micro.weight(.bold))
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundStyle(theme.primary)
                }

                Text(title)
                    .font(theme.heading1)
                    .foregroundStyle(theme.foreground)

                if let subtitle {
                    Text(subtitle)
                        .font(theme.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: theme.space12)

            VStack(alignment: .trailing, spacing: theme.space8) {
                trailing()

                if let detail {
                    AppBadge(text: detail)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.spacingMD)
        .padding(.top, theme.space16)
    }
}

extension CompactScreenHeader where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        eyebrow: String? = nil,
        detail: String? = nil
    ) {
        self.init(title: title, subtitle: subtitle, eyebrow: eyebrow, detail: detail) {
            EmptyView()
        }
    }
}

struct WizardHeader: View {
    @Environment(Theme.self) private var theme

    let steps: [String]
    let currentStep: Int
    var helper: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space16) {
            StepProgressView(
                steps: steps,
                currentStep: currentStep,
                style: .pill
            )

            if let helper {
                Text(helper)
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .padding(.horizontal, theme.spacingMD)
            }
        }
        .padding(.top, theme.space20)
    }
}

@available(*, deprecated, message: "Use HeroHeader or CompactScreenHeader.")
struct BrandedHeader: View {
    let title: String
    var subtitle: String? = nil
    var eyebrow: String = "Crain Painting"
    var detail: String? = nil

    var body: some View {
        CompactScreenHeader(
            title: title,
            subtitle: subtitle,
            eyebrow: eyebrow,
            detail: detail
        )
    }
}
