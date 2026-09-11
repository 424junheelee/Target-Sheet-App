"""Data saved before the target faces were corrected.

Shot positions are stored relative to the face they were plotted on, so a
string recorded on one of the old faces is only meaningful on that face.  Old
strings are kept exactly as recorded - same scores, same MOA scale - and drawn
on a preserved copy of their original face, marked as such.
"""
import json

import pytest

import storage
from targets import (TARGET_CONFIGS, LEGACY_CONFIGS, FACE_REV, build_dist_config,
                     display_name, is_known, migrate_legacy)


def old_string(mkshot, dist):
    return {"shots": [mkshot(0, 0, "A"), mkshot(10, 10, "sc")],
            "cv": "none", "dist": dist, "mu": 21.4, "shoot_len": 10,
            "target_number": "", "saved_at": "2026-06-01T10:00:00"}


# -- the legacy table ---------------------------------------------------------

OLD_KEYS = ([f"{d}-nra" for d in ("300y", "500y", "600y", "700y", "800y", "900y", "1000y")]
            + [f"{d}-dcra" for d in ("300y", "500y", "600y", "700y", "800y", "900y", "1000y")]
            + [f"{d}-dcra" for d in ("300m", "500m", "600m", "700m", "800m", "900m", "1000m")])


@pytest.mark.parametrize("old", OLD_KEYS)
def test_every_pre_update_face_is_preserved(old):
    new = migrate_legacy(old)
    assert new in LEGACY_CONFIGS
    rings, mu = build_dist_config(new)
    assert len(rings) == 5 and mu > 0


def test_legacy_faces_are_not_offered_for_new_strings():
    assert not set(LEGACY_CONFIGS) & set(TARGET_CONFIGS)


def test_migration_is_idempotent():
    once = migrate_legacy("300y-dcra")
    assert migrate_legacy(once) == once


def test_legacy_faces_are_labelled_as_such():
    assert display_name("300y-nra") == "300y-nra"
    assert "old" in display_name(migrate_legacy("300y-nra")).lower()


def test_old_300y_nra_face_is_reproduced_exactly():
    """The pre-update table had radii of 1/3/6/12/22 inches at 300 yd."""
    mm = LEGACY_CONFIGS[migrate_legacy("300y-nra")]["rings_mm"]
    assert mm == pytest.approx([2 * r * 25.4 for r in (1, 3, 6, 12, 22)])


# -- loading old scorecards ---------------------------------------------------

def test_old_scorecards_are_kept_on_their_original_face(app, data_dir, mkshot):
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "scorecards.json").write_text(json.dumps([
        old_string(mkshot, "300y-dcra"),
        old_string(mkshot, "700y-nra"),        # distance since removed
        old_string(mkshot, "1000m-dcra"),      # distance since removed
    ]), encoding="utf-8")
    app._load_persisted_state()
    assert [s["dist"] for s in app.strings] == [
        migrate_legacy("300y-dcra"), migrate_legacy("700y-nra"),
        migrate_legacy("1000m-dcra")]


def test_old_scorecards_keep_their_recorded_scores(app, data_dir, mkshot):
    data_dir.mkdir(parents=True, exist_ok=True)
    sd = old_string(mkshot, "600y-nra")
    before = [(s["sc"], s["lb"]) for s in sd["shots"]]
    (data_dir / "scorecards.json").write_text(json.dumps([sd]), encoding="utf-8")
    app._load_persisted_state()
    assert [(s["sc"], s["lb"]) for s in app.strings[0]["shots"]] == before
    assert app.strings[0]["mu"] == 21.4


def test_old_scorecards_render_in_scorecard_and_analysis(app, data_dir, mkshot):
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "scorecards.json").write_text(json.dumps([
        old_string(mkshot, "1000m-dcra")]), encoding="utf-8")
    app._load_persisted_state()
    app.show_screen("scorecard")
    app.set_analysis(0)
    app.root.update_idletasks()
    assert app.current_screen == "analysis"


def test_new_strings_are_stamped_with_the_face_revision(app):
    import types
    app.show_screen("target")
    px, py = app._to_canvas(0, 0)
    app._on_shot_release(types.SimpleNamespace(x=px, y=py))
    app.commit_string()
    assert app.strings[-1]["face_rev"] == FACE_REV
    assert is_known(app.strings[-1]["dist"])


def test_stamped_strings_are_not_migrated_again(app, data_dir, mkshot):
    data_dir.mkdir(parents=True, exist_ok=True)
    sd = old_string(mkshot, "300y-dcra")
    sd["face_rev"] = FACE_REV                  # saved after the update
    (data_dir / "scorecards.json").write_text(json.dumps([sd]), encoding="utf-8")
    app._load_persisted_state()
    assert app.strings[0]["dist"] == "300y-dcra"


# -- resuming a string started before the update -------------------------------

def old_session(mkshot, dist):
    return {"shots": [mkshot(0, 0, "A"), mkshot(10, 10, "B")],
            "conv": "none", "conv_chosen": False, "active_dist": dist,
            "wind_val": 1.5, "elev_val": 0.0, "target_number": "3"}


def test_an_old_session_resumes_on_its_original_face(app, data_dir, mkshot):
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "session.json").write_text(
        json.dumps(old_session(mkshot, "500y-dcra")), encoding="utf-8")
    app._load_persisted_state()
    assert app.active_dist == migrate_legacy("500y-dcra")
    assert len(app.shots) == 2


def test_an_old_session_can_move_onto_a_corrected_face(app, data_dir, mkshot, monkeypatch):
    monkeypatch.setattr("tkinter.messagebox.askyesno", lambda *a, **k: True)
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "session.json").write_text(
        json.dumps(old_session(mkshot, "500y-dcra")), encoding="utf-8")
    app._load_persisted_state()
    app.show_screen("target")
    app._select_distance("500y-dcra")
    assert app.active_dist == "500y-dcra"


def test_settings_pointing_at_a_removed_face_fall_back(app, data_dir):
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "settings.json").write_text(json.dumps({
        "show_rec": True, "show_graphs": True, "shoot_len": 10,
        "active_dist": "700y-nra"}), encoding="utf-8")
    app._load_persisted_state()
    assert app.active_dist == "300y-nra"


# -- presets --------------------------------------------------------------------

def test_presets_for_removed_faces_are_not_thrown_away(data_dir):
    storage.save_presets({"700y-nra": {"aperture": "3.8", "elevation": "14"},
                          "300y-nra": {"aperture": "4.0", "elevation": "9"}})
    p = storage.load_presets(["300y-nra", "300y-icfra"])
    assert p["700y-nra"] == {"aperture": "3.8", "elevation": "14"}
    assert p["300y-icfra"] == {"aperture": "", "elevation": ""}
    storage.save_presets(p)
    assert storage.load_presets(["300y-nra"])["700y-nra"]["aperture"] == "3.8"
