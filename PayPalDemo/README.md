# PayPal Demo (SwiftUI + MVVM)

A simple iOS demo app showing how to integrate **PayPal Checkout** using the
**PayPal iOS SDK v3** with a clean **MVVM** architecture and a small Node.js server.

![System Design](paypal-mvvm.png)

## Features
- Product menu with add-to-cart and live total
- Official PayPal button (`PayPalButton`)
- PayPal login and approval sheet (sandbox)
- Server-side order create and capture (secret key never in the app)
- Success, cancel and failure handling
- Protects against empty-cart and double-tap payments

## Requirements
- Xcode 15+ (iOS 16+)
- Node.js 18+
- PayPal Developer account (sandbox)

## Setup

### 1. PayPal sandbox
1. developer.paypal.com → **Apps & Credentials** → Create App → copy the **Client ID** and **Secret**
2. **Sandbox Accounts** → copy the Business **Account ID** (your Merchant ID)
3. Note the Personal sandbox account's login, which you'll use to pay

### 2. Server
```bash
cd paypal-server
npm install
PAYPAL_CLIENT_ID=your_client_id PAYPAL_CLIENT_SECRET=your_secret node index.js
```
The server runs on `http://localhost:3000`.

### 3. iOS app
1. Open `PayPalDemo.xcodeproj`
2. SPM package `https://github.com/paypal/paypal-ios` (3.1.1), with these products:
   `CorePayments`, `PayPalPayments`, `PaymentButtons`
3. Target → Info:
   - URL Types → scheme `paypaldemo`
   - `LSApplicationQueriesSchemes` → `paypal`
   - App Transport Security → Allow Local Networking = `YES`
4. Set `clientID` and `merchantID` in `Services/PayPalService.swift`
5. Run on a simulator (⌘R)

## Architecture (MVVM)
```
View (CheckoutView)
   │ user actions
   ▼
ViewModel (CheckoutViewModel)   ← @Published state
   │ protocol
   ▼
Service (PayPalService)         ← PayPal SDK: session, start, return URL
   │ protocol
   ▼
PayPalAPI                       ← URLSession → Node server → PayPal Orders v2
```

## Project Structure
```
PayPalDemo/
 ├─ App/         PayPalDemoApp.swift
 ├─ Models/      Product.swift, PaymentResult.swift
 ├─ Services/    PayPalService.swift, PayPalAPI.swift
 ├─ ViewModels/  CheckoutViewModel.swift
 └─ Views/       CheckoutView.swift
paypal-server/
 └─ index.js
```

## Payment Flow
1. The user taps **PayPal**, which calls `CheckoutViewModel.payPalTapped()`
2. `createPayPalSession()` prepares the session (it must run before `start()`)
3. App → server `POST /orders` → PayPal returns an `orderID`
4. `client.start(orderID)` opens the PayPal login sheet; the user approves
5. PayPal returns to the app, and `handleReturnURL(url)` passes the URL back to the SDK
6. App → server `POST /orders/:id/capture` → `COMPLETED`
7. The ViewModel shows the result alert and clears the cart

## Server API
| Method | Endpoint | Returns |
|--------|----------|---------|
| POST | `/orders` `{ "amount": "6.50" }` | `{ "id": "..." }` |
| POST | `/orders/:id/capture` | `{ "status": "COMPLETED" }` |

## Testing
| Case    | How                           | Result                  |
|---------|-------------------------------|-------------------------|
| Success | Log in with sandbox buyer → Pay | "Payment successful!" |
| Cancel  | Close the PayPal sheet        | "Payment cancelled."    |
| Failure | Stop the server, then tap PayPal | "Payment failed"     |

> The Simulator uses the web sheet. App Switch (the PayPal app with Face ID) needs a real device
> and Universal Links (Associated Domains plus an AASA file).

## Next Steps
- [ ] Add Universal Links for production return
- [ ] Read prices from a database on the server (don't trust the app amount)
- [ ] Add `FraudProtection` device data to order creation
- [ ] Unit tests for `CheckoutViewModel` with a fake `PayPalService`

## Tech Stack
Swift · SwiftUI · PayPal iOS SDK v3 · Node.js · Express · MVVM · Protocol-based DI
