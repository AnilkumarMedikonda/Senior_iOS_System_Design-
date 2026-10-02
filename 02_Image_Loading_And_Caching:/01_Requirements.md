# 01 - Requirements

## Functional
- Load an image from a URL into a cell or view
- Show a placeholder while loading and an icon on failure
- Cache images in memory and on disk
- Clear the cache on demand

## Non-Functional
- Smooth scrolling: no decoding on the main thread
- Low memory: downsample to display size
- Cancel loads for views that scroll off-screen
- No duplicate downloads for the same URL
- No wrong image in reused cells
- Disk cache limited by age (7 days) and size (100 MB)

## Out of Scope
- Animated GIFs and video
- Image editing or filters
- Uploading images

## Clarifying Questions to Ask
- How many images per screen? Feed or grid?
- Does the server send thumbnails or only full-size images?
- Should the cache survive app relaunch?
- Any memory or disk budget?
- Do images change on the server for the same URL?

## Scale Assumptions
- 100+ images in a scrolling grid
- Images up to 2–5 MB each from the server
- Displayed at about 110×110 points

## One-Liner
Load fast, use little memory, and never show the wrong image in a reused cell.
