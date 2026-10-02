# 03 - Cart and Checkout Flow

## Cart — Local First, Server Confirmed

```
Add to cart (offline OK)
   → local cart updated instantly          (03 Offline First)
   → CartMutation queued → synced to server
   → server returns cart with prices, stock, totals → replace local totals
```

- Quantities: local is the source of truth until synced
- **Prices and totals: always from the server**, never calculated for payment on the client
- Money in **minor units (Int)**, never `Double` → no rounding errors

## Guest Cart → Login Merge

```
Guest adds 2 items (local cart, guest id)
   → logs in
   → POST /cart/merge { guestItems }
   → server merges with the user's saved cart (sum quantities, cap by stock)
   → local cart replaced with merged result
```

## Checkout Steps — State Machine

```swift
enum CheckoutStep {
    case address
    case delivery
    case payment
    case review
    case placing
    case success(orderID: String)
    case failed(String)
}
```

```
address → delivery → payment → review → placing → success
                                   │          └─► failed → back to review
                                   └─ price/stock changed → show diff → confirm
```

## Validate Before Paying

```
POST /checkout/validate { cartID }
   ← 200 { total, items }                 → continue
   ← 409 { priceChanged / outOfStock }    → show changes, user confirms
```

Prices change during sales; stock runs out. Validate right before payment.

## Place Order — Idempotent

```swift
let idempotencyKey = UUID()     // created ONCE when entering review

func placeOrder() {
    guard step == .review else { return }   // block double tap
    step = .placing
    api.placeOrder(cartID: cartID, key: idempotencyKey) { result in
        // timeout → retry with the SAME key → server returns the same order
    }
}
```

| Risk | Protection |
|------|------------|
| Double tap | `step` guard, button disabled |
| Timeout, user retries | Same idempotency key → no second order |
| App killed during payment | Order ID saved locally → on launch, `GET /orders/{id}` to check status |

## Payment

```
Create order (status: placed)
   → Payment SDK / Apple Pay sheet → 3-D Secure if needed
   → SDK returns result to app
   → app confirms with server: GET /orders/{id}  (server learned via PSP webhook)
   → paid → success screen, clear cart
```

**Never trust the client's "payment success"**; the server confirms via the payment provider's webhook.

## Senior Point
Client for speed, server for truth: cart quantities are local-first, but prices, stock, totals and payment status always come from the server. One idempotency key per checkout attempt makes every retry safe.

## One-Liner
Local-first cart, server-calculated totals, validate before paying, one idempotency key per order, and the server confirms payment.
