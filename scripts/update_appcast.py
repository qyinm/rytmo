#!/usr/bin/env python3
import argparse
import os
import xml.etree.ElementTree as ET
from datetime import datetime
from email.utils import format_datetime

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)


def ensure_feed(path):
    if os.path.exists(path):
        return ET.parse(path)

    rss = ET.Element("rss", {"version": "2.0"})
    channel = ET.SubElement(rss, "channel")
    title = ET.SubElement(channel, "title")
    title.text = "rytmo"
    return ET.ElementTree(rss)


def find_or_create_channel(root):
    channel = root.find("channel")
    if channel is None:
        channel = ET.SubElement(root, "channel")
        title = ET.SubElement(channel, "title")
        title.text = "rytmo"
    return channel


def set_text(parent, tag, value):
    node = parent.find(tag)
    if node is None:
        node = ET.SubElement(parent, tag)
    node.text = value


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Update Sparkle appcast with latest release item"
    )
    parser.add_argument("--appcast", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--short-version", required=True)
    parser.add_argument("--minimum-system-version", default="")
    parser.add_argument("--release-notes-url", required=True)
    parser.add_argument("--enclosure-url", required=True)
    parser.add_argument("--enclosure-length", required=True)
    parser.add_argument("--ed-signature", required=True)
    parser.add_argument("--retain-item-count", type=int, default=1)
    args = parser.parse_args()

    if args.retain_item_count < 1:
        raise ValueError("--retain-item-count must be >= 1")

    tree = ensure_feed(args.appcast)
    root = tree.getroot()
    if root is None:
        raise RuntimeError(
            f"Invalid appcast XML: missing root element ({args.appcast})"
        )
    channel = find_or_create_channel(root)

    sparkle_version_tag = f"{{{SPARKLE_NS}}}version"
    for item in list(channel.findall("item")):
        version = item.find(sparkle_version_tag)
        if version is not None and (version.text or "") == args.version:
            channel.remove(item)

    item = ET.Element("item")
    set_text(item, "title", args.title)
    set_text(item, "pubDate", format_datetime(datetime.now().astimezone()))
    set_text(item, sparkle_version_tag, args.version)
    set_text(item, f"{{{SPARKLE_NS}}}shortVersionString", args.short_version)

    if args.minimum_system_version:
        set_text(
            item, f"{{{SPARKLE_NS}}}minimumSystemVersion", args.minimum_system_version
        )

    set_text(item, f"{{{SPARKLE_NS}}}releaseNotesLink", args.release_notes_url)

    ET.SubElement(
        item,
        "enclosure",
        {
            "url": args.enclosure_url,
            "length": args.enclosure_length,
            "type": "application/octet-stream",
            f"{{{SPARKLE_NS}}}edSignature": args.ed_signature,
        },
    )

    channel.insert(1 if channel.find("title") is not None else 0, item)

    items = list(channel.findall("item"))
    for old_item in items[args.retain_item_count :]:
        channel.remove(old_item)

    ET.indent(tree, space="    ")
    tree.write(args.appcast, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    main()
