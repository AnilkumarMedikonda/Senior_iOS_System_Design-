# Apple Pay Demo (SwiftUI + MVVM)

A simple iOS demo app showing how to integrate **Apple Pay** using **PassKit** with a clean **MVVM** architecture.
Payments are processed by a mock server, so no backend is needed to run it.

![System Design](apple-pay-mvvm.png)

## Features
- Product menu with add-to-cart
- Live cart total
- Official Apple Pay button (`PayWithApplePayButton`)
- Apple Pay sheet with Face ID / Touch ID
- Success, failure and cancel handling
- Protects against empty-cart and double-tap payments
- Mock payment API (easy to swap for a real backend)

## Requirements
- Xcode 15+ (iOS 16+)
- Paid Apple Developer account (needed for the Merchant ID)
- iOS Simulator or a real device with a card in Wallet

## Setup
1. Clone the repo and open `ApplePayDemo.xcodeproj`
2. Create a Merchant ID at developer.apple.com, for example `merchant.com.yourname.applepaydemo`
3. In Xcode: **Target → Signing & Capabilities → + Apple Pay**, then tick your Merchant ID
4. Update `merchantID` in `Services/ApplePayService.swift`
5. Run on a simulator (⌘R)

## Architecture (MVVM)
```
View (CheckoutView)
   │ user actions
   ▼
ViewModel (CheckoutViewModel)   ← @Published state
   │ protocol
   ▼
Service (ApplePayService)       ← PassKit + delegates
   │ protocol
   ▼
PaymentAPI (MockPaymentAPI)     ← later: real server / gateway
```

## Project Structure
```
ApplePayDemo/
 ├─ App/         ApplePayDemoApp.swift
 ├─ Models/      Product.swift, PaymentResult.swift
 ├─ Services/    ApplePayService.swift, PaymentAPI.swift
 ├─ ViewModels/  CheckoutViewModel.swift
 └─ Views/       CheckoutView.swift
```

## Payment Flow
1. The user taps **Apple Pay**, which calls `CheckoutViewModel.payTapped()`
2. `ApplePayService` builds a `PKPaymentRequest` and shows the Apple Pay sheet
3. The user authenticates with Face ID, and `didAuthorizePayment` receives the encrypted token
4. The token is sent to `MockPaymentAPI.charge()`
5. The sheet shows ✓ or ✕, and `paymentAuthorizationControllerDidFinish` dismisses it
6. The ViewModel updates the UI with the result alert

## Testing
| Case    | How                                        | Result                    |
|---------|--------------------------------------------|---------------------------|
| Success | Add items → Pay                            | "Payment successful!"     |
| Failure | Set `shouldSucceed = false` in `MockPaymentAPI` | "Payment failed"     |
| Cancel  | Tap ✕ on the Apple Pay sheet               | "Payment cancelled."      |

> In the Simulator the payment token is fake (0 bytes). That's expected.

## Next Steps
- [ ] Replace `MockPaymentAPI` with a real backend
- [ ] Process tokens with a gateway (Stripe / PayPal Braintree)
- [ ] Add unit tests for `CheckoutViewModel`
- [ ] Add a PayPal payment option

## Tech Stack
Swift · SwiftUI · PassKit · MVVM · Protocol-based Dependency Injection
