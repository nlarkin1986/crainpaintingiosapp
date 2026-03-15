import SwiftUI
import StripePaymentSheet
import UIKit

struct ConsultationCheckoutView: View {
    @Environment(Theme.self) private var theme
    @Environment(ReportsViewModel.self) private var reportsVM
    @Environment(VisualizerViewModel.self) private var visualizerVM
    @Environment(\.dismiss) private var dismiss

    let flowState: ConsultationFlowState

    @State private var email = ""
    @State private var isPreparingPayment = false
    @State private var showSuccess = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var latestOrderId: String?

    private let checkoutService: ConsultationCheckoutService
    private let consultationService = DefaultConsultationService()

    init(flowState: ConsultationFlowState, checkoutService: ConsultationCheckoutService = RemoteConsultationCheckoutService()) {
        self.flowState = flowState
        self.checkoutService = checkoutService
    }

    private var package: ConsultationPackageDetails {
        consultationService.packageDetails(for: flowState.packageType)
    }

    private var sourceVisualization: Visualization? {
        guard let sourceVisualizationID = flowState.sourceVisualizationID else {
            return visualizerVM.latestVisualization
        }

        return visualizerVM.visualization(
            id: sourceVisualizationID,
            projectID: flowState.sourceProjectID
        ) ?? visualizerVM.savedVisualizations.first(where: { $0.id == sourceVisualizationID })
    }

    private var contextRoomName: String {
        flowState.sourceRoomName ?? sourceVisualization?.roomName ?? "Current project"
    }

    private var contextColor: PaintColor? {
        flowState.sourceColor ?? sourceVisualization?.asPaintColor
    }

    private var usesMockCheckout: Bool {
        ProcessInfo.processInfo.arguments.contains("UITEST_MOCK_CONSULTATION_CHECKOUT_SUCCESS")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: theme.spacingLG) {
                trustedPaymentCard
                expressCheckoutSection
                paymentFormSection
                quoteCard
                guaranteeBlock
            }
            .padding(.horizontal, theme.spacingMD)
            .padding(.vertical, theme.spacingMD)
            .padding(.bottom, 120)
        }
        .background(theme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            topBar
        }
        .safeAreaInset(edge: .bottom) {
            bottomCheckoutBar
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            }
        }
        .alert("Checkout Failed", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showSuccess) {
            CheckoutSuccessView(orderId: latestOrderId) {
                showSuccess = false
                dismiss()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()

            Text("Expert Consultation")
                .font(theme.headline)
                .foregroundStyle(theme.foreground)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, theme.spacingMD)
        .padding(.vertical, theme.spacingSM)
        .background(theme.background.opacity(0.92))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.borderSubtle)
                .frame(height: 1)
        }
    }

    private var trustedPaymentCard: some View {
        VStack(spacing: theme.spacingMD) {
            HStack(alignment: .center, spacing: theme.spacingSM) {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(theme.primary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trusted Payment")
                        .font(theme.micro)
                        .fontWeight(.bold)
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundStyle(theme.mutedForeground)
                    Text("256-bit SSL Encrypted")
                        .font(theme.subhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.foreground)
                }

                Spacer()

                Text("stripe")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "635BFF"))
            }

            Divider()
                .background(theme.borderSubtle)

            consultationContextPanel

            HStack(alignment: .top, spacing: theme.spacingSM) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 62, height: 62)
                    .overlay(
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(theme.primary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(package.name)
                        .font(theme.headline)
                        .foregroundStyle(theme.foreground)
                    Text(package.subtitle)
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                    Text("One-Time Consultation")
                        .font(theme.micro)
                        .fontWeight(.black)
                        .tracking(1)
                        .foregroundStyle(theme.actionPrimaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(theme.actionPrimary)
                        .clipShape(Capsule())
                }

                Spacer()

                Text(currency(package.price))
                    .font(theme.heading2)
                    .fontWeight(.black)
                    .foregroundStyle(theme.foreground)
            }
        }
        .padding(theme.spacingMD)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.border, lineWidth: 1)
        )
    }

    private var consultationContextPanel: some View {
        VStack(alignment: .leading, spacing: theme.spacingSM) {
            Text("Room Context")
                .font(theme.micro)
                .fontWeight(.black)
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(theme.mutedForeground)

            VStack(alignment: .leading, spacing: theme.space8) {
                Text(contextRoomName)
                    .font(theme.heading3)
                    .foregroundStyle(theme.foreground)

                if let contextColor {
                    HStack(spacing: theme.space8) {
                        Circle()
                            .fill(contextColor.color)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(theme.borderSubtle, lineWidth: 1)
                            )
                        Text("\(contextColor.name) • \(contextColor.brand.displayName)")
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }
                } else {
                    Text("We'll anchor Curt's review to the room and project you already have in motion.")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }

                if let projectID = flowState.sourceProjectID {
                    Label("Linked to project \(projectID.prefix(8).uppercased())", systemImage: "square.stack.3d.up")
                        .font(theme.caption)
                        .foregroundStyle(theme.mutedForeground)
                }
            }
            .padding(theme.spacingSM)
            .background(theme.secondary)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
        }
        .accessibilityIdentifier("consultationCheckout.context")
    }

    private var expressCheckoutSection: some View {
        VStack(spacing: theme.spacingSM) {
            HStack(spacing: theme.spacingSM) {
                Rectangle()
                    .fill(theme.borderSubtle)
                    .frame(height: 1)
                Text("Express Checkout")
                    .font(theme.micro)
                    .fontWeight(.black)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.mutedForeground)
                Rectangle()
                    .fill(theme.borderSubtle)
                    .frame(height: 1)
            }

            Button {
                Task { await beginCheckout() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Apple Pay or Card")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!canLaunchCheckout)
            .opacity(canLaunchCheckout ? 1 : 0.7)
        }
    }

    private var paymentFormSection: some View {
        VStack(alignment: .leading, spacing: theme.spacingMD) {
            VStack(alignment: .leading, spacing: theme.spacingSM) {
                Text("Contact Information")
                    .font(theme.micro)
                    .fontWeight(.black)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.mutedForeground)

                inputField(title: "Email address", text: $email, keyboardType: .emailAddress)
                    .accessibilityIdentifier("consultationCheckout.email")
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            VStack(alignment: .leading, spacing: theme.spacingSM) {
                Text("What You're Booking")
                    .font(theme.micro)
                    .fontWeight(.black)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.mutedForeground)

                VStack(spacing: theme.spacingSM) {
                    ForEach(package.features, id: \.self) { feature in
                        paymentMethodRow(
                            icon: "checkmark.circle.fill",
                            title: feature,
                            subtitle: package.turnaround
                        )
                    }
                }

                Text(checkoutStatusCopy)
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }
        }
    }

    private var quoteCard: some View {
        HStack(alignment: .center, spacing: theme.spacingSM) {
            Circle()
                .fill(theme.primary.opacity(0.12))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundStyle(theme.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("After payment, your order appears in Saved so you can track progress without digging through email.")
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.leading)
                Text("REPORT CONTINUITY")
                    .font(theme.micro)
                    .fontWeight(.black)
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.foreground)
            }
            Spacer(minLength: 0)
        }
        .padding(theme.spacingMD)
        .background(theme.muted.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusLG)
                .stroke(theme.borderSubtle, lineWidth: 1)
        )
    }

    private var guaranteeBlock: some View {
        VStack(spacing: theme.spacingSM) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(theme.primary)
                Text("Secure Checkout")
                    .font(theme.subhead)
                    .fontWeight(.black)
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.foreground)
            }

            Text("Payment happens inside Stripe's secure native sheet. The app only keeps the order status needed to show progress and reopen your report later.")
                .font(theme.caption)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacingSM)
    }

    private var bottomCheckoutBar: some View {
        VStack(spacing: theme.spacingSM) {
            HStack {
                Text("Total Due")
                    .font(theme.subhead)
                    .fontWeight(.black)
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.mutedForeground)
                Spacer()
                Text(currency(package.price))
                    .font(theme.heading1)
                    .fontWeight(.black)
                    .foregroundStyle(theme.foreground)
            }

            Button {
                Task { await beginCheckout() }
            } label: {
                HStack(spacing: theme.spacingSM) {
                    Text(buttonTitle)
                        .font(theme.subhead)
                        .fontWeight(.black)
                        .tracking(2)
                        .textCase(.uppercase)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(theme.actionPrimaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.ctaGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!canLaunchCheckout)
            .opacity(canLaunchCheckout ? 1 : 0.7)
            .accessibilityIdentifier("consultationCheckout.submit")
        }
        .padding(.horizontal, theme.spacingMD)
        .padding(.top, theme.spacingSM)
        .padding(.bottom, theme.spacingMD)
        .background(theme.background.opacity(0.95))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.borderSubtle)
                .frame(height: 1)
        }
    }

    private func inputField(title: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .padding(.horizontal, theme.spacingMD)
            .frame(height: 52)
            .background(theme.input)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.border, lineWidth: 1)
            )
    }

    private func paymentMethodRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: theme.spacingSM) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(theme.subhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.foreground)
                Text(subtitle)
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }

            Spacer(minLength: 0)
        }
        .padding(theme.spacingSM)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radiusMD)
                .stroke(theme.border, lineWidth: 1)
        )
    }

    @MainActor
    private func beginCheckout() async {
        guard !isPreparingPayment else { return }

        guard isCheckoutConfigured else {
            errorMessage = "Secure checkout is unavailable in this build until the Crain API URL is configured."
            showErrorAlert = true
            return
        }

        guard isValidEmail else {
            errorMessage = "Please enter a valid email before continuing to payment."
            showErrorAlert = true
            return
        }

        isPreparingPayment = true
        defer { isPreparingPayment = false }

        if usesMockCheckout {
            latestOrderId = "mock-\(flowState.id)"
            completeCheckout(orderID: latestOrderId)
            return
        }

        do {
            let session = try await checkoutService.createSession(
                packageType: package.type,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                orderId: flowState.id,
                platform: .iosNative,
                displayPackage: nil
            )
            latestOrderId = session.orderId

            StripeAPI.defaultPublishableKey = session.publishableKey

            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Crain Painting"
            configuration.defaultBillingDetails.email = email

            if let customerId = session.customerId, let ephemeralKeySecret = session.ephemeralKeySecret {
                configuration.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKeySecret)
            }

            if let merchantIdentifier {
                configuration.applePay = .init(
                    merchantId: merchantIdentifier,
                    merchantCountryCode: session.merchantCountryCode
                )
            }

            let paymentSheet = PaymentSheet(
                paymentIntentClientSecret: session.paymentIntentClientSecret,
                configuration: configuration
            )

            presentPaymentSheet(paymentSheet)
        } catch {
            errorMessage = userFacingMessage(for: error)
            showErrorAlert = true
        }
    }

    @MainActor
    private func presentPaymentSheet(_ paymentSheet: PaymentSheet) {
        guard let viewController = UIApplication.shared.topViewController() else {
            errorMessage = "Unable to present checkout right now. Please try again."
            showErrorAlert = true
            return
        }

        paymentSheet.present(from: viewController) { result in
            Task { @MainActor in
                switch result {
                case .completed:
                    completeCheckout(orderID: latestOrderId)
                case .canceled:
                    break
                case .failed(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    @MainActor
    private func completeCheckout(orderID: String?) {
        let resolvedOrderID = orderID ?? latestOrderId ?? flowState.id
        latestOrderId = resolvedOrderID
        reportsVM.trackPendingReport(
            orderID: resolvedOrderID,
            consultationFlow: flowState,
            sourceVisualization: sourceVisualization,
            packageType: package.type
        )
        showSuccess = true
    }

    private var merchantIdentifier: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "STRIPE_MERCHANT_IDENTIFIER") as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var isValidEmail: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    private var isCheckoutConfigured: Bool {
        usesMockCheckout || APIEnvironment.baseURL != nil
    }

    private var canLaunchCheckout: Bool {
        isCheckoutConfigured && isValidEmail && !isPreparingPayment
    }

    private var buttonTitle: String {
        if isPreparingPayment {
            return "Preparing..."
        }
        return "Continue to Secure Checkout"
    }

    private var checkoutStatusCopy: String {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !isCheckoutConfigured {
            return "Live checkout is unavailable in this build until API_BASE_URL is configured."
        }
        if trimmed.isEmpty {
            return "Enter your email to continue into Stripe's secure native payment sheet."
        }
        if !isValidEmail {
            return "Enter a valid email to continue to secure payment."
        }
        return "You'll review and confirm this one-time consultation inside Stripe's secure native sheet. Card details are never stored in the app."
    }

    private func userFacingMessage(for error: Error) -> String {
        switch error {
        case APIClientError.notConfigured:
            return "Secure checkout is unavailable in this build until the Crain API URL is configured."
        case APIClientError.invalidResponse, APIClientError.decodingError:
            return "We couldn't start secure checkout right now. Please try again."
        case APIClientError.httpError:
            return "The payment service is temporarily unavailable. Please try again."
        default:
            return error.localizedDescription
        }
    }

    private func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSNumber) ?? "$\(value)"
    }
}

private struct CheckoutSuccessView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let orderId: String?
    let onDismiss: () -> Void

    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: theme.spacingLG) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(theme.primary.opacity(0.2))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(theme.primary)
                    .scaleEffect(showCheckmark ? 1 : 0.3)
                    .opacity(showCheckmark ? 1 : 0)
            }

            Text("Purchase Complete")
                .font(theme.largeTitle)
                .foregroundStyle(theme.foreground)

            Text("Your consultation is confirmed. We'll keep the report status updated in Saved while Curt's team prepares your walkthrough and recommendations.")
                .font(theme.body)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacingXL)

            if let orderId {
                Text("Order \(orderId.prefix(8).uppercased())")
                    .font(theme.micro)
                    .fontWeight(.black)
                    .tracking(1)
                    .foregroundStyle(theme.mutedForeground)
            }

            VStack(alignment: .leading, spacing: theme.spacingMD) {
                timelineStep(icon: "envelope.fill", title: "Confirmation Email", detail: "Check your inbox shortly")
                timelineStep(icon: "clock.fill", title: "Status Tracked In Saved", detail: "Open the app any time to check progress")
                timelineStep(icon: "paintpalette.fill", title: "Expert Recommendations", detail: "Your walkthrough and color strategy arrive next")
            }
            .padding(theme.spacingMD)
            .background(theme.muted)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .padding(.horizontal, theme.spacingLG)

            Spacer()

            AppButton("Done", variant: .cta) {
                onDismiss()
            }
            .accessibilityIdentifier("consultationCheckout.successDone")
            .padding(.horizontal, theme.spacingLG)
            .padding(.bottom, theme.spacingXL)
        }
        .background(theme.background)
        .sensoryFeedback(.success, trigger: showCheckmark)
        .onAppear {
            if reduceMotion {
                showCheckmark = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                    showCheckmark = true
                }
            }
        }
    }

    private func timelineStep(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: theme.spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(theme.primary)
                .frame(width: 32, height: 32)
                .background(theme.primary.opacity(0.1))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.subhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.foreground)
                Text(detail)
                    .font(theme.caption)
                    .foregroundStyle(theme.mutedForeground)
            }
            Spacer()
        }
    }
}

private extension UIApplication {
    func topViewController(
        base: UIViewController? = nil
    ) -> UIViewController? {
        let root = base ?? connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        if let navigationController = root as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }
        if let tabBarController = root as? UITabBarController {
            return topViewController(base: tabBarController.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }

        return root
    }
}
