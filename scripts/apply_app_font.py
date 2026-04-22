#!/usr/bin/env python3
"""One-off: replace system Font.* with AppFont in undrmnd Swift sources."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "undrmnd"

# (pattern, repl) in order: longest / most specific first
REPLACEMENTS: list[tuple[str, str]] = [
    (r"\.font\(\.title2\.weight\(\.medium\)\)", ".font(AppFont.title2)"),
    (r"\.font\(\.title3\.weight\(\.semibold\)\)", ".font(AppFont.title3)"),
    (r"\.font\(\.title3\.weight\(\.medium\)\)", ".font(AppFont.title3)"),
    (r"\.font\(\.subheadline\.weight\(\.semibold\)\)", ".font(AppFont.subheadlineEmphasis)"),
    (r"\.font\(\.subheadline\.weight\(\.medium\)\)", ".font(AppFont.subheadlineEmphasis)"),
    (r"\.font\(\.caption\.weight\(\.semibold\)\)", ".font(AppFont.captionEmphasis)"),
    (r"\.font\(\.caption\.weight\(\.medium\)\)", ".font(AppFont.captionEmphasis)"),
    (r"\.font\(\.caption2\.weight\(\.semibold\)\)", ".font(AppFont.caption2Emphasis)"),
    (r"\.font\(\.caption2\.weight\(\.medium\)\)", ".font(AppFont.caption2Medium)"),
    (r"\.font\(\.body\.weight\(\.semibold\)\)", ".font(AppFont.bodySemibold)"),
    (r"\.font\(\.body\.weight\(\.medium\)\)", ".font(AppFont.bodyMedium)"),
    (r"\.font\(\.system\(\.largeTitle, design: \.default, weight: \.semibold\)\)", ".font(AppFont.largeIntroTitle)"),
    (r"\.font\(\.system\(size: 20, design: \.serif\)\.weight\(\.medium\)\)", ".font(AppFont.branchPrompt)"),
    (r"\.font\(\.system\(size: 22, design: \.serif\)\.weight\(\.medium\)\)", ".font(AppFont.cardOrBranchTitle)"),
    (r"\.font\(\.system\(size: 10, weight: \.medium\)\)", ".font(AppFont.mapLabel(approxSize: 10, weight: .medium))"),
    (r"\.font\(\.system\(size: 9, weight: \.semibold\)\)", ".font(AppFont.mapLabel(approxSize: 9, weight: .semibold))"),
    (r"\.font\(\.system\(size: 8, weight: \.medium\)\)", ".font(AppFont.mapLabel(approxSize: 8, weight: .medium))"),
    (r"\.font\(\.system\(size: 8\)\)", ".font(AppFont.mapLabel(approxSize: 8, weight: .regular))"),
    (r"\.font\(\.system\(size: 9\)\)", ".font(AppFont.mapLabel(approxSize: 9, weight: .regular))"),
    (r"\.font\(\.system\(size: 7\)\)", ".font(AppFont.mapLabel(approxSize: 7, weight: .regular))"),
    (r"\.font\(\.system\(size: 10\)\)", ".font(AppFont.mapLabel(approxSize: 10, weight: .regular))"),
    (r"\.font\(\.system\(\.caption, design: \.monospaced\)\)", ".font(AppFont.brandWordmark)"),
    (r"\.font\(\.largeTitle\)", ".font(AppFont.largeTitle)"),
    (r"\.font\(\.title\)", ".font(AppFont.title)"),
    (r"\.font\(\.title2\)", ".font(AppFont.title2)"),
    (r"\.font\(\.title3\)", ".font(AppFont.title3)"),
    (r"\.font\(\.headline\)", ".font(AppFont.headline)"),
    (r"\.font\(\.body\)", ".font(AppFont.body)"),
    (r"\.font\(\.callout\)", ".font(AppFont.callout)"),
    (r"\.font\(\.subheadline\)", ".font(AppFont.subheadline)"),
    (r"\.font\(\.footnote\)", ".font(AppFont.footnote)"),
    (r"\.font\(\.caption\)", ".font(AppFont.caption)"),
    (r"\.font\(\.caption2\)", ".font(AppFont.caption2)"),
]


def main() -> None:
    for p in sorted(ROOT.rglob("*.swift")):
        text = p.read_text(encoding="utf-8")
        orig = text
        for pat, repl in REPLACEMENTS:
            text = re.sub(pat, repl, text)
        if text != orig:
            p.write_text(text, encoding="utf-8")
            print("updated", p.relative_to(ROOT.parent))


if __name__ == "__main__":
    main()
