# 03 - Eviction Policy

## Why Evict
Caches grow forever unless something removes old entries. Memory runs out, or disk fills the user's phone.

## Memory — NSCache Limits

```swift
cache.countLimit = 100                       // max images
cache.totalCostLimit = 50 * 1024 * 1024      // 50 MB
cache.setObject(image, forKey: key, cost: pixels * 4)
```

- NSCache evicts automatically when limits are hit or on memory warnings
- Cost = decoded size (pixels × 4 bytes), not file size

## Disk — TTL + LRU

```
cleanUp() on app launch
   │
   ├─ 1. TTL   remove files older than 7 days
   │
   └─ 2. LRU   if total > 100 MB → sort by date → remove oldest until under limit
```

- Each disk **read** updates the file's modification date, so the date means "last used"
- Cleanup runs on the background queue, never while scrolling

```swift
// Touch on read → LRU
try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
```

```swift
// Size limit → remove least recently used
remaining.sort { $0.date < $1.date }
for item in remaining {
    if totalSize <= maxSize { break }
    try? fileManager.removeItem(at: item.url)
    totalSize -= item.size
}
```

## Policies

| Policy | Removes | Good For |
|--------|---------|----------|
| LRU | Least recently used | Feeds, grids |
| TTL | Older than N days | Images that change on the server |
| Size limit | Oldest until under limit | Protecting device storage |

## When to Run Cleanup
- App launch (demo)
- `didEnterBackground`
- Never during scrolling

## Senior Point
NSCache handles memory for you. Disk is your responsibility: combine TTL for freshness with an LRU size limit for storage safety.

## One-Liner
Memory evicts itself; disk needs TTL plus an LRU size limit, cleaned off the main thread.
