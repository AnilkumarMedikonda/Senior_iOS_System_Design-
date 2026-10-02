//
//  DeepLinkParser.swift
//  DeepLinkSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class DeepLinkParser {
    private let allowedHosts: Set<String> = ["shop.com", "www.shop.com"]
    private let aliases = ["p": "product", "c": "category"]

    func parse(_ url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        var segments = url.path.lowercased().split(separator: "/").map { String($0) }

        // 1. Validate scheme and host
        if url.scheme == "shop" {
            // shop://product/123 → host "product" is the first segment
            if let host = url.host?.lowercased() {
                segments.insert(host, at: 0)
            }
        } else if url.scheme == "https" {
            guard let host = url.host?.lowercased(), allowedHosts.contains(host) else {
                print("PARSER: rejected host \(url.host ?? "nil")")
                return nil
            }
        } else {
            return nil
        }

        // 2. Old aliases → current names
        if let first = segments.first, let real = aliases[first] {
            segments[0] = real
        }

        // 3. Query items
        let query = components.queryItems?.first(where: { $0.name == "q" })?.value
        let campaign = components.queryItems?.first(where: { $0.name == "utm_campaign" })?.value
        if let campaign = campaign {
            print("PARSER: campaign \(campaign)")
        }

        // 4. Match → DeepLink
        let link: DeepLink?
        switch (segments.first, segments.count) {
        case (nil, _):
            link = .home
        case ("product", 2):
            link = .product(id: segments[1])
        case ("category", 2):
            link = .category(slug: segments[1])
        case ("cart", 1):
            link = .cart
        case ("order", 2):
            link = .order(id: segments[1])
        case ("search", 1):
            if let query = query, !query.isEmpty {
                link = .search(query: query)
            } else {
                link = nil
            }
        default:
            link = nil
        }
        print("PARSER: \(url.absoluteString) → \(String(describing: link))")
        return link
    }
}
