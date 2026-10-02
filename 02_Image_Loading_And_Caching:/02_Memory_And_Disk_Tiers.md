# 02 - Memory and Disk Tiers

## Lookup Order

```
load(url, maxPixel)
   │
   ├─ 1. Memory   hit → return instantly (main thread)
   │
   ├─ 2. Disk     hit → downsample → save to memory → return
   │
   └─ 3. Network  download → save to disk → downsample → save to memory → return
```

## Memory Tier — NSCache

- Thread-safe, auto-evicts on memory warnings
- Stores the **downsampled** UIImage, ready to display
- Key = URL + pixel size, so the same URL at different sizes gets its own entry

```swift
final class MemoryCache {
    private let cache = NSCache<NSString, UIImage>()

    func image(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, for key: String) {
        let pixels = image.size.width * image.scale * image.size.height * image.scale
        cache.setObject(image, forKey: key as NSString, cost: Int(pixels * 4))
    }
}
```

## Disk Tier — Caches Directory

- Stores the **original data**, so it can be downsampled to any size later
- `Caches/ImageCache/` folder; the system may clear it, which is fine
- File name = SHA256 of the URL (stable across launches)
- Read and write on the loader's background queue

```swift
private func fileURL(for url: URL) -> URL {
    let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
    let name = hash.map { String(format: "%02x", $0) }.joined()
    return folder.appendingPathComponent(name)
}
```

## What Each Tier Stores

| Tier | Stores | Key | Survives |
|------|--------|-----|----------|
| Memory | Downsampled `UIImage` | URL + pixel size | App session |
| Disk | Original `Data` | SHA256(URL) | Relaunch |

## Why Different Things in Each Tier
- Memory holds ready-to-draw images, so there's no decode on scroll-back
- Disk holds the original, so one download serves every display size

## Senior Point
NSCache isn't a Dictionary. It's thread-safe and frees memory under pressure without your code doing anything. `hashValue` isn't stable across launches, so disk file names need SHA256.

## One-Liner
Memory keeps decoded images for speed, disk keeps original data for reuse, and the network is the last resort.
