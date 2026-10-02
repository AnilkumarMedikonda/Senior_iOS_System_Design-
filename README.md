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

## Roadmap — High Priority

| # | System | Must Cover | Priority | Status |
|---|--------|-----------|----------|--------|
| 01 | Networking_Layer | API client, generic request, decoding, retry | 🔴 High | ⬜ |
| 02 | Image_Loading_And_Caching | NSCache + disk cache, cancellation, cell reuse | 🔴 High | ⬜ |
| 03 | Offline_First_And_Sync | Local source of truth, sync queue, conflicts | 🔴 High | ⬜ |
| 04 | Pagination_And_Search | Cursor paging, debounce, cancel old requests | 🔴 High | ⬜ |
| 05 | Deep_Linking_System | Universal Links, router, cold/warm start | 🔴 High | ⬜ |
| 06 | Authentication_System | Keychain, token refresh, session expiry | 🟠 Medium | ⬜ |
| 07 | Feed_Or_ECommerce_App | End-to-end design using 01–06 | 🟠 Medium | ⬜ |
| 08 | Chat_App | WebSocket, message sync, offline queue, delivery status | 🔴 High | ⬜ |
| 09 | System_Design_Mocks | 2 timed 45-min mocks | 🔴 High | ⬜ |

---

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Stable, reviewed content |
| `feature/System_Design` | All system design work |

---

## Status

0 / 9 systems complete
