#!/usr/bin/env python3
"""Seed assets/content/articles.json from the 8 handoff evidence articles.

Each renders behind the "review pending" badge (clinician sign-off is a
pre-Play gate). Citations are lifted from each article's References block with
their VERIFY caveats stripped from the user-facing line — the verification of
every "what it showed" line against the actual paper is the pending external
task, tracked by reviewState=pending.
"""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
ARTICLES_DIR = ROOT / "sahaj_handoff" / "articles"
OUT = ROOT / "assets" / "content" / "articles.json"

# filename stem → (slug, category)
META = {
    "article_1_pelvic_floor": ("your-pelvic-floor", "Anatomy"),
    "article_2_erections": ("how-erections-work", "Erections"),
    "article_3_performance_anxiety": ("performance-anxiety", "Mind & body"),
    "article_4_premature_ejaculation": ("lasting-longer", "Control"),
    "article_5_delayed_ejaculation": ("delayed-ejaculation", "Control"),
    "article_6_sleep_metabolic": ("sleep-and-metabolic-health", "Health"),
    "article_7_pornography_myths": ("pornography-myths", "Mind & body"),
    "article_8_warning_signs": ("warning-signs", "Health"),
}
ORDER = list(META.keys())


def parse_title(text):
    # The H2 line: "## The muscles holding it all up: your pelvic floor"
    for line in text.splitlines():
        if line.startswith("## "):
            return line[3:].strip()
    raise ValueError("no H2 title")


def parse_body(text):
    # Body = between the first horizontal rule (after the status block) and
    # the References section. Strip a trailing rule.
    after = text.split("\n---\n", 1)[1]
    body = after.split("## References", 1)[0]
    body = re.sub(r"\n---\s*$", "", body.strip()).strip()
    return body


def clean(s):
    s = re.sub(r"\*\*(.+?)\*\*", r"\1", s)  # bold
    s = re.sub(r"\*(.+?)\*", r"\1", s)       # italic
    s = s.replace("*", "")                    # stray unbalanced markers
    return re.sub(r"\s+", " ", s).strip()


def _tidy(s):
    return clean(s).strip(" .;:—-") + "." if clean(s).strip(" .;:—-") else ""


def parse_sources(text):
    if "## References" not in text:
        return []
    ref = text.split("## References", 1)[1]
    ref = re.split(r"\n## ", ref, 1)[0]  # stop at Editorial notes
    sources = []
    # Each numbered item, possibly spanning lines until the next "N. ".
    items = re.split(r"\n(?=\d+\.\s)", ref)
    for item in items:
        item = item.strip()
        if not re.match(r"^\d+\.\s", item):
            continue
        item = re.sub(r"^\d+\.\s", "", item)
        bold = re.search(r"\*\*(.+?)\*\*", item)
        bold_text = bold.group(1) if bold else item.split(".")[0]

        m = re.search(r"Claim used:?\s*(.+)", item, re.S)
        if m:
            # Evidence-study style: name = authors (bold), finding = claim,
            # VERIFY / source-to-be-supplied caveats dropped.
            name = bold_text
            finding = re.split(r"VERIFY|Source to be|Source confirmed",
                               m.group(1))[0]
        else:
            # Topic style (warning-signs): name = the source authority after
            # the bold concept; finding = the concept itself.
            rest = item
            if bold:
                rest = item[bold.end():]
            rest = rest.lstrip(" :")
            source = re.split(r"—|–", rest)[0]  # before the editorial dash
            name, finding = source, bold_text

        name, finding = _tidy(name), _tidy(finding)
        # A bare-source name can over-run; keep its head.
        name = name.split(".")[0].strip() or finding[:40]
        if name and finding:
            sources.append({"name": name, "finding": finding})
    return sources


def words(text):
    return len(re.findall(r"\w+", text))


def main():
    out = []
    for stem in ORDER:
        slug, category = META[stem]
        text = (ARTICLES_DIR / f"{stem}.md").read_text()
        body = parse_body(text)
        out.append({
            "slug": slug,
            "title": parse_title(text),
            "category": category,
            "readMinutes": max(1, round(words(body) / 200)),
            "body": body,
            "register": "evidence",
            "reviewState": "pending",
            "sources": parse_sources(text),
        })
    OUT.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n")
    print(f"wrote {len(out)} articles")
    for a in out:
        print(f"  {a['slug']:30} {a['category']:12} "
              f"{a['readMinutes']}min  {len(a['sources'])} sources")


if __name__ == "__main__":
    main()
