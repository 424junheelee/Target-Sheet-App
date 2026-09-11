import math
import tkinter as tk
from tkinter import ttk

from constants import COL, R, VB
from scoring import wind_label, elev_label, CALL_GLYPHS
from targets import TARGET_CONFIGS, build_dist_config
import graphs
import markers


FACE_MIN = 500   # the face never shrinks below its original fixed size
FACE_MAX = 760   # past this it dwarfs the statistics underneath it


def fit_face_size(room_w: float, room_h: float,
                  lo: int = FACE_MIN, hi: int = FACE_MAX) -> int:
    """Side length for the square target face given the room available.

    Grows with the window, but never below *lo* — the size the face used to be
    pinned at — so a small window is no worse off than before, and never above
    *hi*, so a large one doesn't push the statistics off the screen.
    """
    return int(max(lo, min(room_w, room_h, hi)))


class AnalysisMixin:
    """Builds and renders the analysis screen (interactive target + stats)."""

    def _build_analysis_view(self):
        self._va = tk.Frame(self._content, bg=COL["bg"])
        self._build_nav_bar(self._va, "← Scorecard",
                            lambda: self.show_screen("scorecard"), "Analysis")
        scroll_area = tk.Frame(self._va, bg=COL["bg"])
        scroll_area.pack(fill="both", expand=True)
        canvas = tk.Canvas(scroll_area, bg=COL["bg"], bd=0, highlightthickness=0)
        vsb = ttk.Scrollbar(scroll_area, orient="vertical", command=canvas.yview)
        canvas.configure(yscrollcommand=vsb.set)
        vsb.pack(side="right", fill="y")
        canvas.pack(side="left", fill="both", expand=True)
        self._ac_inner = tk.Frame(canvas, bg=COL["bg"])
        win = canvas.create_window((0, 0), window=self._ac_inner, anchor="nw")
        self._ac_inner.bind(
            "<Configure>",
            lambda _: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.bind("<Configure>",
                    lambda e: canvas.itemconfig(win, width=e.width))

    def _draw_analysis_target(self, parent, shots: list[dict], cv: str,
                              mu: float, dist: str = "", max_shots: int = 12):
        """Render an interactive target with ballistic graphs laid out as on the
        live target: elevation graph to the right, wind graph below.

        The target face grows with the window (staying square, and capped so it
        does not tower over the stats below it); the graph strips keep a fixed
        short axis and stretch along their shot axis.
        """
        EW, WH   = 150, 150   # elevation-graph width, wind-graph height
        MIN_SIZE = FACE_MIN   # also the fallback before layout has settled
        dist_key = dist if dist in TARGET_CONFIGS else "300y-nra"
        rings, _ = build_dist_config(dist_key)

        wrapper = tk.Frame(parent, bg=COL["bg"])
        wrapper.pack(fill="x", padx=16, pady=(10, 4))

        ctrl_row = tk.Frame(wrapper, bg=COL["bg"])
        ctrl_row.pack(fill="x", pady=(0, 3))
        tk.Label(ctrl_row, text="Scroll to zoom · Drag to pan",
                 bg=COL["bg"], fg=COL["text2"],
                 font=("Helvetica", 8)).pack(side="left")
        reset_btn = tk.Button(
            ctrl_row, text="Reset view", font=("Helvetica", 8),
            bg=COL["bg2"], fg=COL["text2"], relief="solid", bd=1,
            padx=5, pady=1, cursor="hand2",
        )
        reset_btn.pack(side="right")

        # Target face + elevation graph to its right
        tgt_row = tk.Frame(wrapper, bg=COL["bg"])
        tgt_row.pack(fill="x")
        canvas = tk.Canvas(tgt_row, width=MIN_SIZE, height=MIN_SIZE,
                           bg=COL["target_bg"], bd=0, highlightthickness=1,
                           highlightbackground=COL["border"], cursor="fleur")
        canvas.pack(side="left")
        elev_c = tk.Canvas(tgt_row, width=EW, height=MIN_SIZE,
                           bg=COL["target_bg"], bd=0, highlightthickness=1,
                           highlightbackground=COL["border"])
        elev_c.pack(side="left", padx=(6, 0))

        # Wind graph below the target face, kept exactly as wide as the face
        # plus the elevation strip so the two line up.
        wind_c = tk.Canvas(wrapper, width=MIN_SIZE + EW + 6, height=WH,
                           bg=COL["target_bg"], bd=0, highlightthickness=1,
                           highlightbackground=COL["border"])
        wind_c.pack(anchor="w", pady=(6, 0))

        def face():
            """Current face size in pixels, before layout has settled too."""
            w, h = canvas.winfo_width(), canvas.winfo_height()
            if w < 5:
                w = MIN_SIZE
            if h < 5:
                h = MIN_SIZE
            return w, h

        def marker_scale():
            """Pixels per SVG unit for shot markers — zoom deliberately left
            out, so zooming in spreads a tight group apart instead of
            magnifying it into the same blob."""
            w, h = face()
            return min(w, h) / (VB * 2)

        def eff():
            w, h = face()
            sc = marker_scale() * self._a_zoom
            return sc, w / 2 + self._a_pan[0], h / 2 + self._a_pan[1]

        def draw():
            canvas.delete("all")
            w, h = face()
            sc, cx, cy = eff()

            canvas.create_rectangle(0, 0, w, h,
                                    fill=COL["target_bg"], outline="")

            highlight = round(R / mu)
            max_i     = int(VB / mu) + 1
            for i in range(-max_i, max_i + 1):
                gx = i * mu * sc + cx
                gy = i * mu * sc + cy
                if i == 0:
                    colour, lw = "#555", 0.8
                elif abs(i) == highlight:
                    colour, lw = "#999", 0.6
                else:
                    colour, lw = "#ccc", 0.4
                canvas.create_line(0, gy, w, gy, fill=colour, width=lw)
                canvas.create_line(gx, 0, gx, h, fill=colour, width=lw)

            ext = VB * sc
            canvas.create_line(cx-ext, cy-ext, cx+ext, cy+ext,
                               fill="#bbb", width=1.0)
            canvas.create_line(cx+ext, cy-ext, cx-ext, cy+ext,
                               fill="#bbb", width=1.0)
            p = 104 * sc
            canvas.create_line(cx-p, cy-p, cx+p, cy+p,
                               fill="#bbb", width=0.8, dash=(6, 4))
            canvas.create_line(cx+p, cy-p, cx-p, cy+p,
                               fill="#bbb", width=0.8, dash=(6, 4))

            for ring in reversed(rings):
                r_px = ring["r"] * sc
                lw   = 1.8 if ring["r"] >= R * 0.14 else 1.2
                canvas.create_oval(cx-r_px, cy-r_px, cx+r_px, cy+r_px,
                                   outline=COL["target_ink"], width=lw)

            canvas.create_rectangle(0, 0, w, h, outline="#555", width=1)
            canvas.create_text(5, 4, text=f"1 MOA · {dist}", anchor="nw",
                               fill="#aaa", font=("Courier", 8))

            selected = self.analysis_selected
            if selected is not None and not (0 <= selected < len(shots)):
                selected = None
            markers.draw_shots(
                canvas, shots, self._compute_labels(shots, cv), cv,
                lambda x, y: (x * sc + cx, y * sc + cy), marker_scale(),
                selected=selected,
            )

        _drag: dict = {}

        def on_zoom(event):
            w, h     = face()
            hx, hy   = w / 2, h / 2
            factor   = 1.15 if event.delta > 0 else 1 / 1.15
            new_zoom = max(0.5, min(8.0, self._a_zoom * factor))
            actual   = new_zoom / self._a_zoom
            self._a_pan[0] = event.x - hx - (event.x - hx - self._a_pan[0]) * actual
            self._a_pan[1] = event.y - hy - (event.y - hy - self._a_pan[1]) * actual
            self._a_zoom   = new_zoom
            draw()

        def on_pan_start(event):
            self.clear_analysis_selection()
            _drag.update(x=event.x, y=event.y,
                         px=self._a_pan[0], py=self._a_pan[1])

        def on_pan_drag(event):
            if "x" not in _drag:
                return
            self._a_pan[0] = _drag["px"] + event.x - _drag["x"]
            self._a_pan[1] = _drag["py"] + event.y - _drag["y"]
            draw()

        def on_reset(_):
            self._a_zoom = 1.0
            self._a_pan  = [0.0, 0.0]
            draw()

        def fit(event):
            """Size the square face to fit the space the view actually has.

            Bounded by width so it never pushes the wind graph off the side,
            and by window height so the face plus its graphs stay visible
            without scrolling before the statistics come into view.
            """
            size = fit_face_size(event.width - EW - 6,
                                 self.root.winfo_height() - WH - 210)
            if size == sized.get("px"):
                return
            sized["px"] = size
            canvas.config(width=size, height=size)
            elev_c.config(height=size)
            wind_c.config(width=size + EW + 6)

        sized: dict = {}
        wrapper.bind("<Configure>", fit)

        # Each canvas redraws itself from its own live size, so a resize needs
        # no bookkeeping beyond re-firing the draw.
        canvas.bind("<Configure>", lambda _: draw())
        elev_c.bind("<Configure>", lambda _: graphs.draw_elev_graph(
            elev_c, shots, mu, max_shots, EW, MIN_SIZE))
        wind_c.bind("<Configure>", lambda _: graphs.draw_wind_graph(
            wind_c, shots, mu, max_shots, MIN_SIZE, WH))

        reset_btn.config(command=lambda: on_reset(None))
        canvas.bind("<MouseWheel>",      on_zoom)
        canvas.bind("<Button-1>",        on_pan_start)
        canvas.bind("<B1-Motion>",       on_pan_drag)
        canvas.bind("<Double-Button-1>", on_reset)

        draw()
        graphs.draw_elev_graph(elev_c, shots, mu, max_shots, EW, MIN_SIZE)
        graphs.draw_wind_graph(wind_c, shots, mu, max_shots, MIN_SIZE, WH)
        return draw

    def _render_analysis(self):
        for w in self._ac_inner.winfo_children():
            w.destroy()

        if self.analysis_idx is None:
            tk.Label(self._ac_inner, text="No series selected", bg=COL["bg"],
                     fg=COL["text2"], font=("Helvetica", 14)).pack(pady=40)
            tk.Label(self._ac_inner, text='Tap "Analyse →" in the Scorecard tab',
                     bg=COL["bg"], fg=COL["text2"], font=("Helvetica", 11)).pack()
            return

        if self.analysis_idx == "current":
            if not self.shots:
                tk.Label(self._ac_inner, text="No shots in current series",
                         bg=COL["bg"], fg=COL["text2"],
                         font=("Helvetica", 14)).pack(pady=40)
                return
            str_shots, cv = self.shots, self.conv
            mu        = self.active_mu
            dist      = self.active_dist
            shoot_len = self.shoot_len
        else:
            idx = self.analysis_idx
            if idx >= len(self.strings):
                self.analysis_idx = None
                self._render_analysis()
                return
            sd        = self.strings[idx]
            str_shots = sd["shots"]
            cv        = sd.get("cv",   "none")
            dist      = sd.get("dist", "300y-nra")
            mu        = sd.get("mu",   build_dist_config(dist)[1])
            shoot_len = sd.get("shoot_len", 10)

        tt  = self._calc_total(str_shots, cv, shoot_len)
        lbl = ("Current series" if self.analysis_idx == "current"
               else f"Series {self.analysis_idx + 1}")

        hdr = tk.Frame(self._ac_inner, bg=COL["bg"])
        hdr.pack(fill="x", padx=16, pady=12)
        tk.Label(hdr, text=lbl, bg=COL["bg"], fg=COL["text"],
                 font=("Helvetica", 15, "bold")).pack(side="left")
        tk.Label(hdr, text=dist, bg=COL["bg"], fg=COL["text2"],
                 font=("Helvetica", 11)).pack(side="left", padx=(8, 0))
        score_str = f"{tt['tot']}" + (f"  v{tt['v']}" if tt["v"] else "")
        tk.Label(hdr, text=score_str, bg=COL["bg"], fg=COL["text"],
                 font=("Courier", 20, "bold")).pack(side="right")
        tk.Frame(self._ac_inner, bg=COL["border"], height=1).pack(fill="x", padx=16)

        self._a_shots = str_shots
        self._a_cv     = cv
        self._a_redraw = self._draw_analysis_target(
            self._ac_inner, str_shots, cv, mu, dist, shoot_len + 2)

        in_target = [s for s in str_shots if s["sc"] > 0]
        mpi = None
        if in_target:
            mpi = (sum(s["x"] for s in in_target) / len(in_target),
                   sum(s["y"] for s in in_target) / len(in_target))

        es_str, mr_str = "—", "—"
        if len(in_target) >= 2:
            max_d = max(
                math.hypot(in_target[i]["x"] - in_target[j]["x"],
                           in_target[i]["y"] - in_target[j]["y"])
                for i in range(len(in_target))
                for j in range(i + 1, len(in_target))
            )
            es_str = f"{max_d / mu:.2f} MOA"
        if mpi and in_target:
            avg_r = (sum(math.hypot(s["x"] - mpi[0], s["y"] - mpi[1])
                         for s in in_target) / len(in_target))
            mr_str = f"{avg_r / mu:.2f} MOA"

        sf = tk.Frame(self._ac_inner, bg=COL["bg"])
        sf.pack(fill="x", padx=16, pady=12)
        for label, value in (("Extreme spread", es_str), ("Mean radius", mr_str)):
            box = tk.Frame(sf, bg=COL["bg2"])
            box.pack(side="left", fill="x", expand=True, padx=5)
            tk.Label(box, text=label, bg=COL["bg2"], fg=COL["text2"],
                     font=("Helvetica", 11)).pack(anchor="w", padx=10, pady=(8, 2))
            tk.Label(box, text=value, bg=COL["bg2"], fg=COL["text"],
                     font=("Courier", 18, "bold")).pack(anchor="w", padx=10, pady=(0, 8))

        good_n = sum(1 for s in str_shots if s["cl"] == "good")
        pull_n = sum(1 for s in str_shots
                     if s["cl"] and s["cl"].startswith("pull"))
        bad_n  = sum(1 for s in str_shots if s["cl"] == "bad")
        if good_n + pull_n + bad_n:
            cf = tk.Frame(self._ac_inner, bg=COL["bg"])
            cf.pack(fill="x", padx=16, pady=(0, 8))
            for text, count, col in (("Good", good_n, "#3B6D11"),
                                     ("Pull", pull_n, COL["text2"]),
                                     ("Bad",  bad_n,  "#A32D2D")):
                b = tk.Frame(cf, bg=COL["bg2"])
                b.pack(side="left", fill="x", expand=True, padx=4)
                tk.Label(b, text=text, bg=COL["bg2"], fg=col,
                         font=("Helvetica", 10)).pack(pady=(6, 2))
                tk.Label(b, text=str(count), bg=COL["bg2"], fg=COL["text"],
                         font=("Courier", 20, "bold")).pack(pady=(0, 6))

        tk.Label(self._ac_inner, text="Shots", bg=COL["bg"], fg=COL["text2"],
                 font=("Helvetica", 11)).pack(anchor="w", padx=16, pady=(8, 2))
        tree = ttk.Treeview(self._ac_inner,
                            columns=("#", "Sc", "Wind", "Elev", "Call"),
                            show="headings", style="TS.Treeview",
                            height=len(str_shots))
        for col, w in (("#", 40), ("Sc", 40), ("Wind", 80),
                       ("Elev", 75), ("Call", 65)):
            tree.heading(col, text=col)
            tree.column(col, width=w, anchor="center", stretch=True)
        labels = self._compute_labels(str_shots, cv)
        for i, (shot, label) in enumerate(zip(str_shots, labels)):
            tree.insert("", "end", values=(
                label, shot["lb"],
                wind_label(shot["w"]), elev_label(shot["e"]),
                CALL_GLYPHS.get(shot["cl"], "") if shot["cl"] else "",
            ), tags=("odd" if i % 2 else "even",))
        tree.tag_configure("odd",  background=COL["bg2"])
        tree.tag_configure("even", background=COL["bg"])
        tree.pack(fill="x", padx=16, pady=(0, 20))

        self._a_tree = tree
        tree.bind("<<TreeviewSelect>>", self._on_analysis_row_selected)
        tree.bind("<Button-1>", self._on_analysis_row_clicked, add="+")
        self._sync_analysis_tree_selection()

    # ── Selecting a shot from the analysis score table ──────────────────────────

    def _analysis_shots(self) -> list:
        return getattr(self, "_a_shots", [])

    def _redraw_analysis_face(self):
        redraw = getattr(self, "_a_redraw", None)
        if redraw is not None:
            redraw()
        self._sync_analysis_tree_selection()

    def _on_analysis_row_selected(self, _=None):
        """Idempotent for the same reason as the live target's handler —
        <<TreeviewSelect>> arrives after our own selection_set has returned."""
        tree = getattr(self, "_a_tree", None)
        if tree is None or not tree.winfo_exists():
            return
        rows = tree.selection()
        if not rows:
            return
        idx = tree.index(rows[0])
        if idx != self.analysis_selected:
            self.select_analysis_shot(idx)

    def _on_analysis_row_clicked(self, event):
        """Clicking the already-selected row toggles the highlight off."""
        tree = getattr(self, "_a_tree", None)
        if tree is None or not tree.winfo_exists():
            return None
        row = tree.identify_row(event.y)
        if row and tree.index(row) == self.analysis_selected:
            self.select_analysis_shot(None)
            return "break"
        return None

    def _sync_analysis_tree_selection(self):
        tree = getattr(self, "_a_tree", None)
        if tree is None or not tree.winfo_exists():
            return
        rows = tree.get_children()
        if self.analysis_selected is not None and self.analysis_selected < len(rows):
            tree.selection_set(rows[self.analysis_selected])
        elif rows:
            tree.selection_remove(*rows)
