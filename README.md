# Senior iOS System Design

Mobile system design prep for Senior iOS interviews at product-based companies. High-priority systems only. Companion repo to `Senior_iOS_Interview_Preparation`.

---

## The 7-Step Framework

Use this order in every design round.

| Step | Focus | Key Question |
|------|-------|--------------|
| 1 | Requirements | What must it do? Scope, scale, offline needs |
| 2 | API Contract | Endpoints, request/response, pagination style |
| 3 | Data Model | Entities, relationships, identifiers |
| 4 | Layers | UI → ViewModel → Repository → Service → Storage |
| 5 | Offline & Caching | Memory vs disk, invalidation, sync |
| 6 | Errors | Retry, backoff, token refresh, error states |
| 7 | Scale | Performance, memory, battery, monitoring |

---

| # | System | Must Cover | Priority | Status | Diagram |
|---|--------|-----------|----------|--------|---------|
| 01 | Networking_Layer | API client, generic request, decoding, retry | 🔴 High | ✅ | `MVVM_Networking_Layer.png` |
| 02 | Image_Loading_And_Caching | NSCache + disk cache, cancellation, cell reuse | 🔴 High | ✅ | `Image_Loading_Caching.png` |
| 03 | Offline_First_And_Sync | Local source of truth, sync queue, conflicts | 🔴 High | ✅ | `Offline_First_Sync.png` |
| 04 | Pagination_And_Search | Offset vs cursor paging, debounce, cancel old requests | 🔴 High | ✅ | `Pagination_Search.png` |
| 05 | Deep_Linking_System | Universal Links, router, cold/warm start | 🔴 High | ✅ | `Deep_Linking.png` |
| 06 | Authentication_System | Keychain, token refresh, session expiry | 🟠 Medium | ✅ | `Authentication.png` |
| 07 | ECommerce_App | Modules, cart and checkout, catalog caching | 🟠 Medium | ✅ | `ECommerce_System_Design.png` · `ECommerce_Class_Design.png` |
| 08 | Chat_App | WebSocket, message sync, offline queue, delivery status | 🔴 High | ✅ | `Chat_App_System_Design.png` |

---

## Revision Diagrams

One-page high-level diagram per system: flow, key components, trade-offs and interview points.

| Common pattern across all systems |
|---|
| View → ViewModel → Repository → Service → Storage / Network |
| Local DB as source of truth when offline matters |
| Protocols + DI for every service, so everything is mockable |
| Typed errors, retry with backoff, token refresh with an actor |

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Stable, reviewed content |
| `feature/System_Design` | All system design work |

---

## Status

8 / 8 systems complete ✅ · Revision ✅ · Diagrams ✅
