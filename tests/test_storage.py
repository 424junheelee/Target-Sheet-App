"""Persistence: round-trips, validation, corruption tolerance, atomicity."""
import json

import pytest

import storage


# ── settings ──────────────────────────────────────────────────────────────────

def test_settings_defaults_on_first_launch(data_dir):
    assert storage.load_settings() == {
        "show_rec": True, "show_graphs": True,
        "shoot_len": 10, "active_dist": "300y-nra",
    }


def test_settings_round_trip(data_dir):
    opts = {"show_rec": False, "show_graphs": False,
            "shoot_len": 15, "active_dist": "600m-dcra"}
    storage.save_settings(opts)
    assert storage.load_settings() == opts


def test_settings_rejects_wrong_types_and_falls_back(data_dir):
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "settings.json").write_text(json.dumps({
        "show_rec": "yes", "show_graphs": 1,
        "shoot_len": 12, "active_dist": 700,
    }), encoding="utf-8")
    s = storage.load_settings()
    assert s["show_rec"] is True          # "yes" rejected
    assert s["show_graphs"] is True       # 1 is not a bool
    assert s["shoot_len"] == 10           # 12 is not an allowed match length
    assert s["active_dist"] == "300y-nra"  # 700 is not a str


def test_corrupt_settings_file_does_not_crash(data_dir):
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "settings.json").write_text("{not json", encoding="utf-8")
    assert storage.load_settings()["shoot_len"] == 10


# ── presets ───────────────────────────────────────────────────────────────────

def test_presets_seeded_for_every_key(data_dir):
    keys = ["300y-nra", "600m-dcra"]
    p = storage.load_presets(keys)
    assert set(p) == set(keys)
    assert p["300y-nra"] == {"aperture": "", "elevation": ""}


def test_presets_round_trip_and_backfill_missing_keys(data_dir):
    storage.save_presets({"300y-nra": {"aperture": "4.2", "elevation": "12.5"}})
    p = storage.load_presets(["300y-nra", "900y-nra"])
    assert p["300y-nra"]["aperture"] == "4.2"
    assert p["900y-nra"] == {"aperture": "", "elevation": ""}


def test_preset_values_coerced_to_strings(data_dir):
    storage.save_presets({"300y-nra": {"aperture": 4.2, "elevation": 12}})
    p = storage.load_presets(["300y-nra"])
    assert p["300y-nra"] == {"aperture": "4.2", "elevation": "12"}


# ── scorecards ────────────────────────────────────────────────────────────────

def test_scorecards_round_trip(data_dir, mkshot):
    strings = [{"shots": [mkshot(1, 2, "A"), mkshot(0, 0, "sc")],
                "cv": "b", "dist": "600y-nra", "mu": 12.5,
                "shoot_len": 15, "target_number": "7", "saved_at": "2026-01-01"}]
    storage.save_scorecards(strings)
    out = storage.load_scorecards()
    assert len(out) == 1
    assert out[0]["cv"] == "b"
    assert out[0]["shoot_len"] == 15
    assert len(out[0]["shots"]) == 2


def test_scorecards_drop_structurally_invalid_entries(data_dir, mkshot):
    data_dir.mkdir(parents=True, exist_ok=True)
    good = {"shots": [mkshot(0, 0, "sc")], "cv": "none",
            "dist": "300y-nra", "mu": 21.4}
    (data_dir / "scorecards.json").write_text(json.dumps([
        good,
        {"cv": "none", "dist": "300y-nra", "mu": 1},        # no 'shots'
        {"shots": "nope", "cv": "none", "dist": "x", "mu": 1},  # shots not a list
        {"shots": [{"x": 1}], "cv": "none", "dist": "x", "mu": 1},  # bad shot
        "garbage",
    ]), encoding="utf-8")
    assert len(storage.load_scorecards()) == 1


def test_scorecards_backfill_legacy_fields(data_dir):
    data_dir.mkdir(parents=True, exist_ok=True)
    legacy_shot = {"x": 0, "y": 0, "sc": 5, "iv": True, "lb": "V",
                   "tp": "sc", "w": 0, "e": 0}          # no 'cl'
    (data_dir / "scorecards.json").write_text(json.dumps([
        {"shots": [legacy_shot], "cv": "none", "dist": "300y-nra", "mu": 21.4}
    ]), encoding="utf-8")
    out = storage.load_scorecards()[0]
    assert out["shots"][0]["cl"] is None
    assert out["shoot_len"] == 10
    assert out["target_number"] == ""
    assert out["saved_at"] == ""


def test_non_list_scorecards_file_yields_empty(data_dir):
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "scorecards.json").write_text('{"a": 1}', encoding="utf-8")
    assert storage.load_scorecards() == []


# ── session ───────────────────────────────────────────────────────────────────

def test_no_session_on_first_launch(data_dir):
    assert storage.load_session() is None


def test_session_round_trip(data_dir, mkshot):
    state = {"shots": [mkshot(3, -4, "A", w=2.5, e=-1.5)],
             "conv": "ab", "conv_chosen": True, "active_dist": "800y-dcra",
             "wind_val": 2.5, "elev_val": -1.5, "target_number": "12"}
    storage.save_session(state)
    out = storage.load_session()
    assert out["conv"] == "ab"
    assert out["wind_val"] == 2.5
    assert out["target_number"] == "12"


def test_saving_none_clears_the_session(data_dir, mkshot):
    storage.save_session({"shots": [mkshot(0, 0, "A")], "conv": "none",
                          "conv_chosen": False, "active_dist": "300y-nra",
                          "wind_val": 0, "elev_val": 0})
    assert storage.load_session() is not None
    storage.save_session(None)
    assert storage.load_session() is None


def test_session_missing_required_keys_is_rejected(data_dir):
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "session.json").write_text(
        json.dumps({"shots": [], "conv": "none"}), encoding="utf-8")
    assert storage.load_session() is None


# ── write behaviour ───────────────────────────────────────────────────────────

def test_writes_are_atomic_no_tmp_file_left_behind(data_dir):
    storage.save_settings({"show_rec": True, "show_graphs": True,
                           "shoot_len": 10, "active_dist": "300y-nra"})
    assert not list(data_dir.glob("*.tmp"))


def test_save_failure_raises_ioerror(data_dir, monkeypatch):
    def boom(*a, **k):
        raise OSError("disk full")
    monkeypatch.setattr("pathlib.Path.write_text", boom)
    with pytest.raises(IOError):
        storage.save_settings({"show_rec": True, "show_graphs": True,
                               "shoot_len": 10, "active_dist": "300y-nra"})
