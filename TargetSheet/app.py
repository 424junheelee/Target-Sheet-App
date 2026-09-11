import datetime
import tkinter as tk
from tkinter import messagebox

import storage
from constants import COL
from scoring import score_shot, snap, clamp
from targets import (TARGET_CONFIGS, FACE_REV, build_dist_config, display_name,
                     hit_area, is_known, migrate_legacy)
from views.menu import MenuMixin
from views.target import TargetMixin
from views.scorecard import ScorecardMixin
from views.analysis import AnalysisMixin
from views.settings import SettingsMixin


class TargetSheetApp(MenuMixin, TargetMixin, ScorecardMixin,
                     AnalysisMixin, SettingsMixin):
    """
    TargetSheet application root.

    State lives on the instance; the view mixins read from and write to it.
    All screen frames are built once at startup and shown/hidden by name.

    Shot schema:
        x, y : float     – SVG coordinates of the shot
        sc   : int       – score (0–5)
        iv   : bool       – True if V-bull
        lb   : str       – score label ("V"/"5"/"4"/"3"/"2"/"1"/"M");
                           "1" is a hit on the target outside the Outer ring
        tp   : str       – shot type: "A" | "B" | "sc"
        w, e : float     – wind / elevation dialled at time of shot
        cl   : str|None  – shot-call key, or None

    String schema:
        shots : list[shot]
        cv    : str       – conversion setting at commit time
        dist  : str       – distance/standard config key
        mu    : float     – SVG units per MOA for the string's distance
        face_rev : int    – targets.FACE_REV the string was plotted under;
                            strings without it predate the rule-book faces
    """

    def __init__(self):
        # ── State ──────────────────────────────────────────────────────────────
        self.shots:          list[dict] = []
        self.strings:        list[dict] = []
        self.wind_val:       float = 0.0
        self.elev_val:       float = 0.0
        self.conv:           str   = "none"   # "none" | "b" | "ab"
        self.conv_chosen:    bool  = False
        self.analysis_idx              = None  # None | "current" | int
        self.current_screen: str   = "menu"

        # Shot picked out in the score table, as an index into the string being
        # shown.  The two screens show different strings, so they track it
        # separately.  None means every shot draws normally.
        self.selected_shot:    int | None = None   # live target
        self.analysis_selected: int | None = None  # analysis view

        # Target-canvas zoom/pan
        self._zoom:       float = 1.0
        self._pan:        list  = [0.0, 0.0]
        self._drag_anchor       = None
        # Analysis-canvas zoom/pan
        self._a_zoom:     float = 1.0
        self._a_pan:      list  = [0.0, 0.0]

        # Per-config sight presets (keyed by full config key)
        self.presets: dict = {
            k: {"aperture": "", "elevation": ""} for k in TARGET_CONFIGS
        }

        # Current physical target lane/number the shooter is firing on
        self.target_number: str = ""

        # Match length — number of scored shots in the string (10 or 15)
        self.shoot_len: int = 10

        # User options
        self.show_rec: bool = True     # show the "Dial to" wind/elev recommendation
        self.show_graphs: bool = True  # show the wind & elevation graphs while shooting

        # Active distance config (default 300y NRA until the user selects one)
        self._apply_dist("300y-nra")

        # Restore persisted state before building the UI so all view constructors
        # read the correct values (presets, shoot_len, show_rec, etc.).
        self._load_persisted_state()

        # ── Build UI ───────────────────────────────────────────────────────────
        self.root = tk.Tk()
        self.root.title("TargetSheet — DCRA Fullbore")
        self.root.configure(bg=COL["bg"])
        self.root.geometry("1080x720")
        self.root.bind("<Escape>", self._on_escape)
        self.root.minsize(940, 640)

        self._content = tk.Frame(self.root, bg=COL["bg"])
        self._content.pack(fill="both", expand=True)

        self._build_menu_view()
        self._build_dist_select_view()
        self._build_target_view()
        self._build_scorecard_view()
        self._build_analysis_view()
        self._build_options_view()
        self._build_presets_view()

        self._draw_target_bg()
        self.show_screen("menu")

        self.root.mainloop()

    # ── Screen navigation ───────────────────────────────────────────────────────

    def show_screen(self, name: str):
        self.current_screen = name
        frames = {
            "menu":        self._vm,
            "dist_select": self._vds,
            "target":      self._vt,
            "scorecard":   self._vs,
            "analysis":    self._va,
            "options":     self._vo,
            "presets":     self._vp,
        }
        for frame in frames.values():
            frame.pack_forget()
        frames[name].pack(fill="both", expand=True)

        if name == "menu":
            self._refresh_resume_button()
        elif name == "target":
            self.render()
        elif name == "scorecard":
            self._render_scorecard()
        elif name == "analysis":
            self._render_analysis()

    def _select_distance(self, dist_key: str):
        """Set the active distance config and switch to the target screen.

        Shot coordinates are stored relative to the target face, so the same
        point falls in a different ring on a different face.  Changing distance
        mid-string therefore has to re-score the shots already placed, which
        can change the running total — so it is confirmed first.
        """
        rescoring = bool(self.shots) and dist_key != self.active_dist
        if rescoring and not messagebox.askyesno(
                "Change distance",
                f"{len(self.shots)} shot(s) are already on the target.\n\n"
                f"Switching to {dist_key} re-scores them against the new "
                f"target face, which may change the total.\n\nContinue?",
                parent=self.root):
            return

        self._apply_dist(dist_key)
        self._dist_label_var.set(display_name(dist_key))

        if rescoring:
            self._rescore_shots()
            self._save_session()
            self._toast(f"{len(self.shots)} shot(s) re-scored for {dist_key}.")

        self._redraw_target()
        self._save_settings()
        self.show_screen("target")

    def _apply_dist(self, dist_key: str):
        """Make *dist_key* the active face: its rings, MOA scale and Hit area."""
        self.active_dist = dist_key
        self.active_rings, self.active_mu = build_dist_config(dist_key)
        self.active_hit = hit_area(dist_key)

    def _rescore_shots(self):
        """Re-evaluate every placed shot against the active target face."""
        for shot in self.shots:
            result = score_shot(shot["x"], shot["y"], self.active_rings,
                                self.active_hit)
            shot["sc"] = result["sc"]
            shot["iv"] = result["iv"]
            shot["lb"] = result["lb"]

    def _back_to_menu(self):
        if self.shots:
            self._toast("In-progress string paused — tap Target to resume.")
        self.show_screen("menu")

    def _toast(self, msg: str, duration: int = 2800):
        t = tk.Label(self.root, text=msg, bg="#2d2d2d", fg="white",
                     font=("Helvetica", 10), padx=16, pady=9)
        t.place(relx=0.5, rely=1.0, anchor="s", y=-12)
        self.root.after(duration, t.destroy)

    def set_analysis(self, key):
        self.analysis_idx = key
        self.analysis_selected = None   # a different string is on screen now
        self.show_screen("analysis")

    # ── Shot selection ──────────────────────────────────────────────────────────

    def select_shot(self, idx: int | None):
        """Pick out one shot of the live string, or clear with None.

        Selecting the shot that is already selected clears it, so the same row
        toggles the highlight off.
        """
        if idx is not None and not (0 <= idx < len(self.shots)):
            idx = None
        self.selected_shot = None if idx == self.selected_shot else idx
        self._sync_shot_table_selection()
        self._draw_shots()

    def clear_shot_selection(self):
        if self.selected_shot is not None:
            self.selected_shot = None
            self._sync_shot_table_selection()
            self._draw_shots()

    def select_analysis_shot(self, idx: int | None):
        """Pick out one shot of the string being analysed, or clear with None."""
        shots = self._analysis_shots()
        if idx is not None and not (0 <= idx < len(shots)):
            idx = None
        self.analysis_selected = None if idx == self.analysis_selected else idx
        self._redraw_analysis_face()

    def clear_analysis_selection(self):
        if self.analysis_selected is not None:
            self.analysis_selected = None
            self._redraw_analysis_face()

    def _on_escape(self, _=None):
        """Escape drops whichever selection the current screen is showing."""
        if self.current_screen == "target":
            self.clear_shot_selection()
        elif self.current_screen == "analysis":
            self.clear_analysis_selection()

    # ── Shared widgets ──────────────────────────────────────────────────────────

    def _build_nav_bar(self, parent, back_label: str, back_cmd, title: str = ""):
        nav = tk.Frame(parent, bg=COL["nav_bg"])
        nav.pack(fill="x", side="top")
        tk.Button(nav, text=back_label, bg=COL["nav_bg"], fg=COL["accent"],
                  font=("Helvetica", 11), relief="flat", bd=0,
                  padx=14, pady=8, cursor="hand2",
                  command=back_cmd).pack(side="left")
        if title:
            tk.Label(nav, text=title, bg=COL["nav_bg"], fg=COL["text"],
                     font=("Helvetica", 12, "bold")).pack(side="left", padx=4)
        tk.Frame(parent, bg=COL["border"], height=1).pack(fill="x", side="top")

    # ── Scoring / string logic ──────────────────────────────────────────────────

    def commit_string(self):
        if not self.shots:
            return
        if self.analysis_idx == "current":
            self.analysis_idx = len(self.strings)
        self.strings.append({
            "shots":         list(self.shots),
            "cv":            self.conv,
            "dist":          self.active_dist,
            "mu":            self.active_mu,
            "shoot_len":     self.shoot_len,
            "target_number": self.target_number,
            "saved_at":      datetime.datetime.now().isoformat(timespec="seconds"),
            "face_rev":      FACE_REV,
        })
        self.shots         = []
        self.conv          = "none"
        self.conv_chosen   = False
        self.selected_shot = None
        self._save_scorecards()
        self._save_session()   # shots is now [] → writes None (clears session file)
        self.render()
        self.show_screen("scorecard")

    def apply_rec(self):
        r = self._compute_recommendation()
        if r:
            self.wind_val = r["w"]
            self.elev_val = r["e"]
            self._update_controls()
            self._save_session()

    def _compute_labels(self, shots: list[dict], cv: str) -> list[str]:
        """Display labels for each shot, accounting for sighter conversion."""
        out, sc_idx = [], 0
        offset = 1 if cv == "none" else 2 if cv == "b" else 3
        for s in shots:
            if s["tp"] == "A":
                out.append("1" if cv == "ab" else "A")
            elif s["tp"] == "B":
                out.append("1" if cv == "b" else ("2" if cv == "ab" else "B"))
            else:
                out.append(str(sc_idx + offset))
                sc_idx += 1
        return out

    def _get_phase(self) -> dict:
        """Which shot comes next: sighter A, sighter B, scored shot, or done."""
        n = len(self.shots)
        if n == 0:
            return {"tp": "A", "lb": "Sighter A"}
        if n == 1:
            return {"tp": "B", "lb": "Sighter B"}
        sc_count = sum(1 for s in self.shots if s["tp"] == "sc")
        # Converted sighters count toward the total, reducing scored shots needed
        converted = 0 if self.conv == "none" else 1 if self.conv == "b" else 2
        max_sc    = self.shoot_len - converted
        if sc_count >= max_sc:
            return {"tp": "done", "lb": "String complete"}
        off = 1 if self.conv == "none" else 2 if self.conv == "b" else 3
        return {"tp": "sc", "lb": f"Shot {sc_count + off}"}

    def _calc_total(self, shots: list[dict], cv: str,
                    shoot_len: int = None) -> dict:
        """Total score / V count / shot count under a conversion setting."""
        if shoot_len is None:
            shoot_len = self.shoot_len
        converted = 0 if cv == "none" else 1 if cv == "b" else 2
        max_sc    = shoot_len - converted
        scoring = [s for s in shots if s["tp"] == "sc"][:max_sc]

        extra = []
        if cv in ("b", "ab"):
            b = next((s for s in shots if s["tp"] == "B"), None)
            if b:
                extra.append(b)
        if cv == "ab":
            a = next((s for s in shots if s["tp"] == "A"), None)
            if a:
                extra.insert(0, a)

        all_s = extra + scoring
        return {
            "tot": sum(s["sc"] for s in all_s),
            "v":   sum(1 for s in all_s if s["iv"]),
            "n":   len(all_s),
        }

    def _compute_recommendation(self) -> dict | None:
        """
        Wind/elevation that would centre the current group.
        W_rec = W − x / mu  (shot right of centre → reduce rightward wind)
        E_rec = E + y / mu  (SVG +y = physically down → increase elevation)
        """
        if not self.shots:
            return None
        n      = len(self.shots)
        mean_x = sum(s["x"] for s in self.shots) / n
        mean_y = sum(s["y"] for s in self.shots) / n
        mu     = self.active_mu
        return {
            "w": clamp(snap(self.wind_val - mean_x / mu)),
            "e": clamp(snap(self.elev_val + mean_y / mu)),
            "n": n,
        }

    # ── Persistence helpers ─────────────────────────────────────────────────────

    def _load_persisted_state(self):
        """Restore all persisted state from disk before the UI is built."""
        # Settings — apply before presets/scorecards so defaults are sane
        s = storage.load_settings()
        self.show_rec    = s["show_rec"]
        self.show_graphs = s["show_graphs"]
        self.shoot_len   = s["shoot_len"]
        dist = s["active_dist"]
        if dist in TARGET_CONFIGS:
            self._apply_dist(dist)

        # Presets
        self.presets = storage.load_presets(list(TARGET_CONFIGS))

        # Saved scorecards.  Strings saved before FACE_REV was stamped were
        # plotted on the pre-audit faces, and stay on those faces.
        self.strings = storage.load_scorecards()
        for sd in self.strings:
            if "face_rev" not in sd:
                sd["dist"] = migrate_legacy(sd["dist"])
                sd["face_rev"] = FACE_REV

        # In-progress session — overrides active_dist from settings if present
        sess = storage.load_session()
        if sess:
            self.shots       = sess["shots"]
            self.conv        = sess["conv"]
            self.conv_chosen = sess["conv_chosen"]
            sess_dist        = sess["active_dist"]
            if "face_rev" not in sess:        # started on a pre-audit face
                sess_dist = migrate_legacy(sess_dist)
            if is_known(sess_dist):
                self._apply_dist(sess_dist)
            self.wind_val      = float(sess["wind_val"])
            self.elev_val      = float(sess["elev_val"])
            self.target_number = str(sess.get("target_number", ""))

    def _save_settings(self):
        try:
            storage.save_settings({
                "show_rec":    self.show_rec,
                "show_graphs": self.show_graphs,
                "shoot_len":   self.shoot_len,
                "active_dist": self.active_dist,
            })
        except IOError:
            self._toast("Warning: settings could not be saved.")

    def _save_session(self):
        try:
            if self.shots:
                storage.save_session({
                    "shots":         self.shots,
                    "conv":          self.conv,
                    "conv_chosen":   self.conv_chosen,
                    "active_dist":   self.active_dist,
                    "wind_val":      self.wind_val,
                    "elev_val":      self.elev_val,
                    "target_number": self.target_number,
                    "face_rev":      FACE_REV,
                })
            else:
                storage.save_session(None)
        except IOError:
            self._toast("Warning: session could not be saved.")

    def _save_scorecards(self):
        try:
            storage.save_scorecards(self.strings)
        except IOError:
            self._toast("Warning: scorecard could not be saved.")

    def _save_presets(self):
        try:
            storage.save_presets(self.presets)
        except IOError:
            pass  # don't show a toast on every keystroke in the presets form
