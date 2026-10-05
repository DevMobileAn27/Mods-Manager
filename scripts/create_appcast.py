"""Create the WinSparkle feed for a signed GitHub Release installer."""

import argparse
from datetime import datetime, timezone
from email.utils import format_datetime
from pathlib import Path
from xml.etree import ElementTree as ET


SPARKLE = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--signature", required=True)
    parser.add_argument("--installer", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    rss = ET.Element("rss", version="2.0")
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = "Visual Mods Manager updates"
    item = ET.SubElement(channel, "item")
    ET.SubElement(item, "title").text = f"Version {args.version}"
    ET.SubElement(item, "pubDate").text = format_datetime(datetime.now(timezone.utc))
    ET.SubElement(
        item,
        "enclosure",
        {
            "url": (
                f"https://github.com/{args.repository}/releases/download/"
                f"{args.tag}/XXMI-Manager-Setup.exe"
            ),
            f"{{{SPARKLE}}}dsaSignature": args.signature,
            f"{{{SPARKLE}}}version": args.version,
            f"{{{SPARKLE}}}os": "windows",
            "length": str(args.installer.stat().st_size),
            "type": "application/octet-stream",
        },
    )
    ET.indent(rss)
    ET.ElementTree(rss).write(args.output, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    main()
