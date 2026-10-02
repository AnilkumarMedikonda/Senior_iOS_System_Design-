# 05 - Decode and Downsampling

## The Problem
A JPEG on disk is compressed. To draw it, iOS **decodes** it into raw pixels:

```
Memory = width × height × 4 bytes

4000 × 3000 photo  → 48 MB decoded
Shown at 110×110 pt (330×330 px @3x) → only ~0.4 MB needed
```

`UIImage(data:)` keeps the full size, and decoding happens lazily on the **main thread** at first draw, which causes scroll jank and memory spikes.

## The Fix — ImageIO Downsampling
- Creates a thumbnail at the target size **without decoding the full image**
- Runs on the loader's background queue
- `ShouldCacheImmediately` decodes now, so drawing on the main thread is free

```swift
enum ImageDownsampler {
    static func downsample(_ data: Data, maxPixel: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
```

## Target Size

```swift
maxPixel = size × displayScale      // 110 × 3 = 330 px
```

| SwiftUI | UIKit |
|---------|-------|
| `@Environment(\.displayScale)` | `traitCollection.displayScale` |

## Where It Fits

```
Network / Disk data  →  downsample (background)  →  memory cache  →  main thread  →  view
```

## Options Explained

| Option | Why |
|--------|-----|
| `ShouldCache: false` | Don't decode the full image when creating the source |
| `ThumbnailFromImageAlways` | Always build the thumbnail from the full image |
|
