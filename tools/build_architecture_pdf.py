"""Render the assessment architecture note to a four-page PDF."""

from __future__ import annotations

import html
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    HRFlowable,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "architecture.md"
OUTPUT = ROOT / "output" / "pdf" / "architecture-tradeoffs.pdf"
INK = colors.HexColor("#15283C")
ACCENT = colors.HexColor("#008C86")
MUTED = colors.HexColor("#526274")


def markup(line: str) -> str:
    line = html.escape(line).replace("“", '"').replace("”", '"')
    line = line.replace("’", "'").replace("—", "-").replace("–", "-")
    line = re.sub(r"\*\*(.*?)\*\*", r"<b>\1</b>", line)
    line = re.sub(r"`([^`]+)`", r"<font color='#006B66'>\1</font>", line)
    return line


def decorate(canvas, doc):
    canvas.saveState()
    width, height = A4
    canvas.setFillColor(ACCENT)
    canvas.rect(0, height - 5 * mm, width, 5 * mm, fill=1, stroke=0)
    canvas.setStrokeColor(colors.HexColor("#CED7DD"))
    canvas.line(19 * mm, 17 * mm, width - 19 * mm, 17 * mm)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(19 * mm, 12 * mm, "MAL CAREERS  /  LEDGER ASSESSMENT")
    canvas.drawRightString(width - 19 * mm, 12 * mm, f"{doc.page} / 4")
    canvas.restoreState()


def build():
    styles = {
        "title": ParagraphStyle(
            "title", fontName="Helvetica-Bold", fontSize=20, leading=24,
            textColor=INK, spaceAfter=8 * mm,
        ),
        "meta": ParagraphStyle(
            "meta", fontName="Helvetica", fontSize=9, leading=12,
            textColor=MUTED, spaceAfter=8 * mm,
        ),
        "section": ParagraphStyle(
            "section", fontName="Helvetica-Bold", fontSize=14, leading=18,
            textColor=INK, spaceBefore=3 * mm, spaceAfter=5 * mm,
        ),
        "body": ParagraphStyle(
            "body", fontName="Helvetica", fontSize=10.5, leading=15.2,
            textColor=INK, alignment=TA_LEFT, spaceAfter=4 * mm,
            splitLongWords=1,
        ),
        "bullet": ParagraphStyle(
            "bullet", fontName="Helvetica", fontSize=10, leading=14.3,
            textColor=INK, leftIndent=6 * mm, firstLineIndent=-4 * mm,
            spaceAfter=3.3 * mm, splitLongWords=1,
        ),
        "source": ParagraphStyle(
            "source", fontName="Helvetica", fontSize=8.2, leading=11.5,
            textColor=MUTED, spaceBefore=4 * mm, splitLongWords=1,
        ),
    }
    story = []
    for raw in SOURCE.read_text().splitlines():
        line = raw.strip()
        if not line:
            continue
        if line == "<!-- PAGE -->":
            story.append(PageBreak())
        elif line.startswith("# "):
            story.append(Paragraph(markup(line[2:]), styles["title"]))
            story.append(HRFlowable(width="100%", thickness=1.4, color=ACCENT,
                                    spaceAfter=6 * mm))
        elif line.startswith("## "):
            story.append(Paragraph(markup(line[3:]), styles["section"]))
        elif line.startswith("- "):
            story.append(Paragraph("<font color='#008C86'>•</font>  " + markup(line[2:]), styles["bullet"]))
        elif line.startswith("Staff Software Engineer assessment"):
            story.append(Paragraph(markup(line), styles["meta"]))
        elif line.startswith("Source:"):
            story.append(Paragraph(markup(line), styles["source"]))
        else:
            story.append(Paragraph(markup(line), styles["body"]))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUTPUT), pagesize=A4, topMargin=22 * mm, bottomMargin=24 * mm,
        leftMargin=19 * mm, rightMargin=19 * mm,
        title="Architecture tradeoffs | In-memory account ledger core",
        author="Assessment submission",
    )
    doc.build(story, onFirstPage=decorate, onLaterPages=decorate)
    print(OUTPUT)


if __name__ == "__main__":
    build()
