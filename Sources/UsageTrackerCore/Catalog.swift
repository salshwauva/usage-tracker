import Foundation

/// Built-in subscriptions. Families, not dated SKUs.
/// Live time comes from bundle ids (desktop apps) and URL hosts (browser tabs).
/// Add a host or bundle when a vendor ships a new surface. No API required.
public enum Catalog {
    public static let all: [Service] = [
        service(
            id: "claude",
            name: "Claude",
            vendor: "Anthropic",
            models: ["Opus", "Sonnet", "Haiku", "Claude Code"],
            enabled: true,
            bundleIDs: ["com.anthropic.claudefordesktop", "com.anthropic.claude-code-url-handler"],
            urlHosts: ["claude.ai", "console.anthropic.com"]
        ),
        service(
            id: "chatgpt",
            name: "ChatGPT",
            vendor: "OpenAI",
            models: ["GPT", "o-series", "Codex"],
            enabled: true,
            bundleIDs: ["com.openai.chat", "com.openai.codex"],
            urlHosts: ["chatgpt.com", "chat.openai.com", "platform.openai.com"]
        ),
        service(
            id: "gemini",
            name: "Gemini",
            vendor: "Google",
            models: ["Pro", "Flash", "Veo"],
            enabled: true,
            bundleIDs: [],
            urlHosts: ["gemini.google.com", "aistudio.google.com"]
        ),
        service(
            id: "grok",
            name: "Grok",
            vendor: "xAI",
            models: ["Grok", "Imagine"],
            enabled: true,
            bundleIDs: [],
            urlHosts: ["grok.com", "grok.x.ai"]
        ),
        service(
            id: "cursor",
            name: "Cursor",
            vendor: "Anysphere",
            models: ["Auto", "Composer"],
            enabled: true,
            bundleIDs: ["com.todesktop.230313mzl4w4u92"],
            urlHosts: ["cursor.com"]
        ),
        service(
            id: "copilot",
            name: "Copilot",
            vendor: "GitHub / Microsoft",
            models: ["Chat", "Completions"],
            enabled: true,
            bundleIDs: ["com.microsoft.VSCode", "com.microsoft.VSCodeInsiders", "com.microsoft.VSCodeExploration"],
            urlHosts: ["copilot.microsoft.com"]
        ),
        service(
            id: "perplexity",
            name: "Perplexity",
            vendor: "Perplexity",
            models: ["Sonar"],
            enabled: true,
            bundleIDs: ["ai.perplexity.macv3", "ai.perplexity.comet"],
            urlHosts: ["perplexity.ai"]
        ),
        service(
            id: "midjourney",
            name: "Midjourney",
            vendor: "Midjourney",
            models: ["V7", "Niji"],
            enabled: false,
            bundleIDs: [],
            urlHosts: ["midjourney.com"]
        ),
        service(
            id: "mistral",
            name: "Le Chat",
            vendor: "Mistral",
            models: ["Large", "Codestral"],
            enabled: false,
            bundleIDs: [],
            urlHosts: ["chat.mistral.ai", "console.mistral.ai"]
        ),
        service(
            id: "deepseek",
            name: "DeepSeek",
            vendor: "DeepSeek",
            models: ["V3", "R1"],
            enabled: false,
            bundleIDs: [],
            urlHosts: ["chat.deepseek.com", "platform.deepseek.com"]
        ),
    ]

    public static func seededServices() -> [Service] {
        all
    }

    /// Overlay saved readings onto the current built-in list, then append customs.
    /// A new built-in in an app update appears even if the save predates it.
    public static func merge(saved: [Service]) -> [Service] {
        let savedByID = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
        var merged: [Service] = all.map { builtin in
            guard let overlay = savedByID[builtin.id] else { return builtin }
            var next = builtin
            next.enabled = overlay.enabled
            next.displayName = overlay.displayName
            next.models = overlay.models.isEmpty ? builtin.models : overlay.models
            next.meter = overlay.meter
            next.bundleIDs = unique(builtin.bundleIDs + overlay.bundleIDs)
            next.urlHosts = unique(builtin.urlHosts + overlay.urlHosts)
            return next
        }
        let builtinIDs = Set(all.map(\.id))
        let customs = saved.filter { !$0.isBuiltIn && !builtinIDs.contains($0.id) }
        merged.append(contentsOf: customs)
        return merged
    }

    public static func makeCustom(
        name: String,
        vendor: String = "",
        bundleIDs: [String] = [],
        urlHosts: [String] = []
    ) -> Service {
        Service(
            id: "custom-\(UUID().uuidString)",
            displayName: name,
            vendor: vendor,
            models: [],
            enabled: true,
            isBuiltIn: false,
            meter: Meter.blank(kind: .percent),
            bundleIDs: bundleIDs,
            urlHosts: urlHosts
        )
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private static func service(
        id: String,
        name: String,
        vendor: String,
        models: [String],
        enabled: Bool,
        bundleIDs: [String],
        urlHosts: [String],
        meter: Meter = Meter.blank(kind: .percent)
    ) -> Service {
        Service(
            id: id,
            displayName: name,
            vendor: vendor,
            models: models,
            enabled: enabled,
            isBuiltIn: true,
            meter: meter,
            bundleIDs: bundleIDs,
            urlHosts: urlHosts
        )
    }
}
