import tkinter as tk
from tkinter import ttk, messagebox

from constants import COL
from scoring import wind_label, elev_label, CALL_GLYPHS
from targets import display_name


class ScorecardMixin:
    """Builds and renders the scorecard screen (per-string cards + aggregate)."""

    def _build_scorecard_view(self):
        self._vs = tk.Frame(self._content, bg=COL["bg"])
        self._build_nav_bar(self._vs, "← Menu",
                            lambda: self.show_screen("menu"), "Scorecard")
        scroll_area = tk.Frame(self._vs, bg=COL["bg"])
        scroll_area.pack(fill="both", expand=True)
        canvas = tk.Canvas(scroll_area, bg=COL["bg"], bd=0, highlightthickness=0)
        vsb = ttk.Scrollbar(scroll_area, orient="vertical", command=canvas.yview)
        canvas.configure(yscrollcommand=vsb.set)
        vsb.pack(side="right", fill="y")
        canvas.pack(side="left", fill="both", expand=True)
        self._sc_inner = tk.Frame(canvas, bg=COL["bg"])
        win = canvas.create_window((0, 0), window=self._sc_inner, anchor="nw")
        self._sc_inner.bind(
            "<Configure>",
            lambda _: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.bind("<Configure>",
                    lambda e: canvas.itemconfig(win, width=e.width))

    def _render_scorecard(self):
        for w in self._sc_inner.winfo_children():
            w.destroy()

        all_strs = list(self.strings)
        if self.shots:
            all_strs.append({"shots": self.shots, "cv": self.conv,
                             "dist": self.active_dist, "cur": True})

        if not all_strs:
            tk.Label(self._sc_inner, text="No completed series yet", bg=COL["bg"],
                     fg=COL["text2"], font=("Helvetica", 14)).pack(pady=50)
            return

        for si, sd in enumerate(all_strs):
            is_cur = sd.get("cur", False)
            cv     = sd.get("cv", "none")
            dist   = sd.get("dist", "300y-nra")
            slen   = sd.get("shoot_len", self.shoot_len)
            tt     = self._calc_total(sd["shots"], cv, slen)
            lbl    = "Current series" if is_cur else f"Series {si + 1}"

            card = tk.Frame(self._sc_inner, bg=COL["bg2"])
            card.pack(fill="x", padx=16, pady=(0, 12))

            hdr = tk.Frame(card, bg=COL["bg2"])
            hdr.pack(fill="x", padx=12, pady=8)
            tk.Label(hdr, text=lbl, bg=COL["bg2"], fg=COL["text2"],
                     font=("Helvetica", 12)).pack(side="left")
            tk.Label(hdr, text=display_name(dist), bg=COL["bg2"], fg=COL["text2"],
                     font=("Helvetica", 9)).pack(side="left", padx=(6, 0))

            # Discard (current in-progress) or Delete (saved series)
            if is_cur:
                tk.Button(
                    hdr, text="Discard", bg=COL["bg2"], fg="#A32D2D",
                    font=("Helvetica", 10), relief="solid", bd=1, cursor="hand2",
                    command=self._discard_current,
                ).pack(side="right", padx=(0, 8))
            else:
                tk.Button(
                    hdr, text="Delete", bg=COL["bg2"], fg="#A32D2D",
                    font=("Helvetica", 10), relief="solid", bd=1, cursor="hand2",
                    command=lambda idx=si: self._delete_series(idx),
                ).pack(side="right", padx=(0, 8))

            a_key  = "current" if is_cur else si
            is_sel = self.analysis_idx == a_key
            tk.Button(
                hdr, text="▶ Analysing" if is_sel else "Analyse →",
                bg=COL["bg2"], fg=COL["accent"] if is_sel else COL["text2"],
                font=("Helvetica", 10), relief="solid", bd=1, cursor="hand2",
                command=lambda k=a_key: self.set_analysis(k),
            ).pack(side="right", padx=8)

            score_str = f"{tt['tot']}" + (f"  v{tt['v']}" if tt["v"] else "")
            tk.Label(hdr, text=score_str, bg=COL["bg2"], fg=COL["text"],
                     font=("Courier", 18, "bold")).pack(side="right")

            tree = ttk.Treeview(card, columns=("#", "Sc", "Wind", "Elev", "Call"),
                                show="headings", style="TS.Treeview",
                                height=len(sd["shots"]))
            for col, w in (("#", 30), ("Sc", 30), ("Wind", 70),
                           ("Elev", 65), ("Call", 55)):
                tree.heading(col, text=col)
                tree.column(col, width=w, anchor="center", stretch=True)
            labels = self._compute_labels(sd["shots"], cv)
            for i, (shot, label) in enumerate(zip(sd["shots"], labels)):
                tree.insert("", "end", values=(
                    label, shot["lb"],
                    wind_label(shot["w"]), elev_label(shot["e"]),
                    CALL_GLYPHS.get(shot["cl"], "") if shot["cl"] else "",
                ), tags=("odd" if i % 2 else "even",))
            tree.tag_configure("odd",  background=COL["bg2"])
            tree.tag_configure("even", background=COL["bg"])
            tree.pack(fill="x", padx=12, pady=(0, 10))

        if self.strings:
            gt = sum(self._calc_total(s["shots"], s.get("cv", "none"),
                                      s.get("shoot_len", 10))["tot"]
                     for s in self.strings)
            gv = sum(self._calc_total(s["shots"], s.get("cv", "none"),
                                      s.get("shoot_len", 10))["v"]
                     for s in self.strings)
            agg = tk.Frame(self._sc_inner, bg=COL["bg2"])
            agg.pack(fill="x", padx=16, pady=(0, 16))
            inner = tk.Frame(agg, bg=COL["bg2"])
            inner.pack(fill="x", padx=14, pady=10)
            tk.Label(inner, text="Aggregate", bg=COL["bg2"], fg=COL["text2"],
                     font=("Helvetica", 12)).pack(side="left")
            tk.Label(inner, text=f"{gt}  v{gv}", bg=COL["bg2"], fg=COL["text"],
                     font=("Courier", 20, "bold")).pack(side="right")

    # ── Discard / delete ────────────────────────────────────────────────────────

    def _discard_current(self):
        """Throw away the in-progress series after confirmation."""
        if not messagebox.askyesno(
                "Discard series",
                "Discard the current in-progress series? "
                "All unsaved shots will be lost.",
                parent=self.root):
            return
        self.shots = []
        self.conv = "none"
        self.conv_chosen = False
        self.selected_shot = None
        if self.analysis_idx == "current":
            self.analysis_idx = None
        self._save_session()   # shots is now [] → writes None (clears session file)
        self.render()
        self._render_scorecard()

    def _delete_series(self, idx: int):
        """Delete a saved series after confirmation."""
        if idx >= len(self.strings):
            return
        if not messagebox.askyesno(
                "Delete scorecard",
                f"Delete Series {idx + 1}? This cannot be undone.",
                parent=self.root):
            return
        del self.strings[idx]
        # Keep the analysis selection pointing at the right series
        if self.analysis_idx == idx:
            self.analysis_idx = None
        elif isinstance(self.analysis_idx, int) and self.analysis_idx > idx:
            self.analysis_idx -= 1
        self._save_scorecards()
        self._render_scorecard()
