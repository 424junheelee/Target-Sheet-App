#!/usr/bin/env python3
"""
TargetSheet — DCRA / NRA Fullbore Marksmanship App
==================================================
A Tkinter app for recording and analysing fullbore target-rifle strings
across all standard Bisley distances (300–1000 y) and DCRA metric distances,
with regulation NRA and ICFRA ring sizes per distance.

Package layout:
    constants.py   – geometry, scale, colour palette
    scoring.py     – pure scoring/formatting helpers + shot-call glyphs
    targets.py     – ring specs, TARGET_CONFIGS, build_dist_config()
    graphs.py      – shared ballistic-graph drawing (wind / elevation), used by
                     both the live target and the scorecard analysis
    app.py         – TargetSheetApp: state, navigation, scoring logic, and
                     user options (match length, recommendation/graph toggles)
    views/         – per-screen UI mixins:
                       menu.py      – main menu + distance/match-length select
                       target.py    – live target face, controls, ballistic graphs
                       scorecard.py – saved series, discard/delete
                       analysis.py  – per-series target + finished ballistic graphs
                       settings.py  – options + saved presets

Requirements:
    Python 3.8+ with the standard library only (tkinter ships with Python).

Run:
    python target_sheet.py
"""

from app import TargetSheetApp


if __name__ == "__main__":
    TargetSheetApp()
