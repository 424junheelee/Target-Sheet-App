import tkinter as tk
from tkinter import ttk, simpledialog

from constants import COL, R, VB, CANVAS_PX, MAXV
from scoring import score_shot, wind_label, elev_label, snap, clamp, CALL_GLYPHS
import graphs

# Ballistic-graph strip sizes (the short axis stays fixed; the long axis scales)
ELEV_GRAPH_W = 128   # width of the vertical elevation graph (right of target)
WIND_GRAPH_H = 116   # height of the horizontal wind graph (below target)


class TargetMixin:
    """
    Builds and drives the target screen:
      - canvas with MOA grid, rings, shot markers
      - right-panel controls (wind/elev, call buttons, shot table)
      - zoom/pan interaction
      - render / update helpers
    """

    # ── UI construction ────────────────────────────────────────────────────────

    def _build_target_view(self):
        self._vt = tk.Frame(self._content, bg=COL["bg"])

        nav = tk.Frame(self._vt, bg=COL["nav_bg"])
        nav.pack(fill="x", side="top")
        tk.Button(nav, text="← Menu", bg=COL["nav_bg"], fg=COL["accent"],
                  font=("Helvetica", 11), relief="flat", bd=0,
                  padx=14, pady=8, cursor="hand2",
                  command=self._back_to_menu).pack(side="left")
        self._dist_label_var = tk.StringVar(value=self.active_dist)
        tk.Label(nav, textvariable=self._dist_label_var,
                 bg=COL["nav_bg"], fg=COL["text"],
                 font=("Helvetica", 12, "bold")).pack(side="left", padx=4)
        tk.Button(nav, text="Change distance", bg=COL["nav_bg"], fg=COL["text2"],
                  font=("Helvetica", 9), relief="flat", bd=0,
                  padx=8, pady=8, cursor="hand2",
                  command=lambda: self.show_screen("dist_select")).pack(
                      side="left", padx=(0, 8))
        tk.Frame(self._vt, bg=COL["border"], height=1).pack(fill="x", side="top")

        body = tk.Frame(self._vt, bg=COL["bg"])
        body.pack(fill="both", expand=True)
        # Target area expands more than the controls so it scales on fullscreen
        body.columnconfigure(0, weight=3)
        body.columnconfigure(2, weight=2)
        body.rowconfigure(0, weight=1)

        # Left: target canvas (grows), elevation graph right, wind graph below,
        # target-number field at the bottom.
        left = tk.Frame(body, bg=COL["bg"])
        left.grid(row=0, column=0, sticky="nsew")
        left.rowconfigure(0, weight=1)      # top row (canvas + elev) grows
        left.columnconfigure(0, weight=1)   # canvas column grows

        top_row = tk.Frame(left, bg=COL["bg"])
        top_row.grid(row=0, column=0, sticky="nsew")
        top_row.rowconfigure(0, weight=1)
        top_row.columnconfigure(0, weight=1)

        self._canvas = tk.Canvas(
            top_row, width=CANVAS_PX, height=CANVAS_PX,
            bg=COL["target_bg"], bd=0, highlightthickness=0, cursor="crosshair",
        )
        self._canvas.grid(row=0, column=0, sticky="nsew")

        self._elev_graph = tk.Canvas(
            top_row, width=ELEV_GRAPH_W,
            bg=COL["target_bg"], bd=0, highlightthickness=1,
            highlightbackground=COL["border"],
        )
        self._elev_graph.grid(row=0, column=1, sticky="ns", padx=(6, 0))

        # Horizontal wind graph below the target face
        self._wind_graph = tk.Canvas(
            left, height=WIND_GRAPH_H,
            bg=COL["target_bg"], bd=0, highlightthickness=1,
            highlightbackground=COL["border"],
        )
        self._wind_graph.grid(row=1, column=0, sticky="ew", pady=(6, 0))

        # Redraw target / graphs whenever their canvas is resized
        self._canvas.bind("<Configure>", lambda _: self._redraw_target())
        self._elev_graph.bind("<Configure>", lambda _: self._draw_ballistic_graphs())
        self._wind_graph.bind("<Configure>", lambda _: self._draw_ballistic_graphs())

        tnum = tk.Frame(left, bg=COL["bg"])
        tnum.grid(row=2, column=0, sticky="ew", pady=10)
        tk.Label(tnum, text="Target no.", bg=COL["bg"], fg=COL["text2"],
                 font=("Helvetica", 12)).pack(side="left", padx=(12, 8))
        self._target_no_var = tk.StringVar(value=self.target_number)
        ent = tk.Entry(tnum, textvariable=self._target_no_var,
                       font=("Courier", 24, "bold"), width=8,
                       relief="solid", bd=2, justify="center")
        ent.pack(side="left", fill="x", expand=True, padx=(0, 12), ipady=10)
        # Pressing Enter or Escape finishes editing and removes the blinking caret
        ent.bind("<Return>", lambda _: self._canvas.focus_set())
        ent.bind("<Escape>", lambda _: self._canvas.focus_set())
        self._target_no_var.trace_add(
            "write", lambda *_: setattr(self, "target_number",
                                        self._target_no_var.get()))

        self._canvas.bind("<Button-1>",        self._on_shot_press)
        self._canvas.bind("<B1-Motion>",       self._on_shot_drag)
        self._canvas.bind("<ButtonRelease-1>", self._on_shot_release)
        self._canvas.bind("<Button-3>",        self._on_pan_start)
        self._canvas.bind("<B3-Motion>",       self._on_pan_drag)
        self._canvas.bind("<MouseWheel>",      self._on_zoom)
        self._canvas.bind("<Double-Button-3>", self._on_reset_view)

        rst = tk.Button(
            self._canvas, text="Reset view", font=("Helvetica", 8),
            bg=COL["bg2"], fg=COL["text2"], relief="solid", bd=1,
            padx=5, pady=2, cursor="hand2", command=self._reset_view,
        )
        self._reset_win = self._canvas.create_window(
            CANVAS_PX - 6, 6, anchor="ne", window=rst)

        tk.Frame(body, bg=COL["border"], width=1).grid(row=0, column=1, sticky="ns")

        ctrl = tk.Frame(body, bg=COL["bg"])
        ctrl.grid(row=0, column=2, sticky="nsew")
        self._ctrl = ctrl

        self._build_score_row(ctrl)
        self._build_windelev_row(ctrl)
        self._build_rec_row(ctrl)
        self._build_call_row(ctrl)
        self._build_conv_row(ctrl)
        self._build_shot_table(ctrl)
        self._build_action_row(ctrl)

    def _build_score_row(self, parent):
        f = tk.Frame(parent, bg=COL["bg"])
        f.pack(fill="x", padx=12, pady=(8, 6))
        self._phase_lbl = tk.Label(f, text="Next: Sighter A",
                                   bg=COL["bg"], fg=COL["text"],
                                   font=("Helvetica", 11, "bold"))
        self._phase_lbl.pack(side="left")
        self._count_lbl = tk.Label(f, text="0/10",
                                   bg=COL["bg"], fg=COL["text2"],
                                   font=("Helvetica", 10))
        self._count_lbl.pack(side="right", padx=(4, 0))
        self._v_lbl = tk.Label(f, text="",
                               bg=COL["bg"], fg=COL["text2"],
                               font=("Courier", 11))
        self._v_lbl.pack(side="right")
        self._score_lbl = tk.Label(f, text="0",
                                   bg=COL["bg"], fg=COL["text"],
                                   font=("Courier", 22, "bold"))
        self._score_lbl.pack(side="right", padx=(0, 4))
        tk.Frame(parent, bg=COL["border"], height=1).pack(fill="x")

    def _build_windelev_row(self, parent):
        f = tk.Frame(parent, bg=COL["bg"])
        f.pack(fill="x", padx=12, pady=8)

        wf = tk.Frame(f, bg=COL["bg"])
        wf.pack(side="left", fill="x", expand=True)
        tk.Label(wf, text="Wind", bg=COL["bg"], fg=COL["text2"],
                 font=("Helvetica", 9)).pack(side="left", padx=(0, 3))
        tk.Button(wf, text="−", bg=COL["bg"], fg=COL["text"],
                  font=("Helvetica", 14), relief="solid", bd=1, width=2,
                  cursor="hand2",
                  command=lambda: self.adj_wind(-1)).pack(side="left", padx=1)
        self._wind_var = tk.StringVar(value="calm")
        wl = tk.Label(wf, textvariable=self._wind_var, bg=COL["bg"],
                      fg=COL["text2"], font=("Courier", 13, "bold"),
                      width=8, cursor="hand2")
        wl.pack(side="left")
        wl.bind("<Button-1>", lambda _: self.edit_value("wind"))
        self._wind_lbl_widget = wl
        tk.Button(wf, text="+", bg=COL["bg"], fg=COL["text"],
                  font=("Helvetica", 14), relief="solid", bd=1, width=2,
                  cursor="hand2",
                  command=lambda: self.adj_wind(1)).pack(side="left", padx=1)

        tk.Frame(f, bg=COL["border"], width=1).pack(side="left", fill="y", padx=8)

        ef = tk.Frame(f, bg=COL["bg"])
        ef.pack(side="left", fill="x", expand=True)
        tk.Label(ef, text="Elev", bg=COL["bg"], fg=COL["text2"],
                 font=("Helvetica", 9)).pack(side="left", padx=(0, 3))
        tk.Button(ef, text="↓", bg=COL["bg"], fg=COL["text"],
                  font=("Helvetica", 14), relief="solid", bd=1, width=2,
                  cursor="hand2",
                  command=lambda: self.adj_elev(-1)).pack(side="left", padx=1)
        self._elev_var = tk.StringVar(value="0")
        el = tk.Label(ef, textvariable=self._elev_var, bg=COL["bg"],
                      fg=COL["text2"], font=("Courier", 13, "bold"),
                      width=8, cursor="hand2")
        el.pack(side="left")
        el.bind("<Button-1>", lambda _: self.edit_value("elev"))
        self._elev_lbl_widget = el
        tk.Button(ef, text="↑", bg=COL["bg"], fg=COL["text"],
                  font=("Helvetica", 14), relief="solid", bd=1, width=2,
                  cursor="hand2",
                  command=lambda: self.adj_elev(1)).pack(side="left", padx=1)

        tk.Frame(parent, bg=COL["border"], height=1).pack(fill="x")

    def _build_rec_row(self, parent):
        self._rec_frame = tk.Frame(parent, bg=COL["rec_bg"])
        inner = tk.Frame(self._rec_frame, bg=COL["rec_bg"])
        inner.pack(fill="x", padx=12, pady=5)
        tk.Label(inner, text="Dial to:", bg=COL["rec_bg"], fg=COL["text2"],
                 font=("Helvetica", 9)).pack(side="left", padx=(0, 4))
        tk.Label(inner, text="W", bg=COL["rec_bg"], fg=COL["text2"],
                 font=("Helvetica", 9)).pack(side="left")
        self._rec_w_var = tk.StringVar()
        tk.Label(inner, textvariable=self._rec_w_var, bg=COL["rec_bg"],
                 fg=COL["accent"], font=("Courier", 12, "bold")).pack(
                     side="left", padx=3)
        tk.Label(inner, text="E", bg=COL["rec_bg"], fg=COL["text2"],
                 font=("Helvetica", 9)).pack(side="left")
        self._rec_e_var = tk.StringVar()
        tk.Label(inner, textvariable=self._rec_e_var, bg=COL["rec_bg"],
                 fg=COL["accent"], font=("Courier", 12, "bold")).pack(
                     side="left", padx=3)
        self._rec_n_var = tk.StringVar()
        tk.Label(inner, textvariable=self._rec_n_var, bg=COL["rec_bg"],
                 fg=COL["text2"], font=("Helvetica", 9)).pack(
                     side="left", padx=4)
        tk.Button(inner, text="Apply", fg=COL["accent"], bg=COL["rec_bg"],
                  font=("Helvetica", 10), relief="solid", bd=1, cursor="hand2",
                  command=self.apply_rec).pack(side="right")
        tk.Frame(self._rec_frame, bg=COL["border"], height=1).pack(fill="x")

    def _build_call_row(self, parent):
        f = tk.Frame(parent, bg=COL["bg"])
        f.pack(fill="x", padx=12, pady=6)
        self._call_btns: dict[str, tk.Button] = {}
        defs = [
            ("pull-high",  "↑"),
            ("pull-left",  "←"),
            ("good",       "✓"),
            ("pull-right", "→"),
            ("pull-low",   "↓"),
            ("bad",        "✕  Unc."),
        ]
        for key, glyph in defs:
            b = tk.Button(
                f, text=glyph, bg=COL["bg2"], fg=COL["text2"],
                font=("Helvetica", 13), relief="flat", bd=0,
                padx=4, pady=3, cursor="hand2", state="disabled",
                command=lambda k=key: self.set_call(k),
            )
            b.pack(side="left", fill="x", expand=True, padx=1)
            self._call_btns[key] = b
        tk.Frame(parent, bg=COL["border"], height=1).pack(fill="x")

    def _build_conv_row(self, parent):
        self._conv_frame = tk.Frame(parent, bg=COL["bg2"])
        tk.Label(self._conv_frame, text="CONVERT SIGHTERS?",
                 bg=COL["bg2"], fg=COL["text2"],
                 font=("Helvetica", 9)).pack(pady=(7, 3), padx=12)
        bf = tk.Frame(self._conv_frame, bg=COL["bg2"])
        bf.pack(fill="x", padx=12, pady=(0, 7))
        self._conv_btns: dict[str, tk.Button] = {}
        for key, label in [("none", "None"),
                            ("b",    "Score 1 = B"),
                            ("ab",   "Score 1=A, 2=B")]:
            b = tk.Button(bf, text=label, bg=COL["bg"], fg=COL["text2"],
                          font=("Helvetica", 10), relief="solid", bd=1,
                          cursor="hand2", command=lambda k=key: self.set_conv(k))
            b.pack(side="left", fill="x", expand=True, padx=2)
            self._conv_btns[key] = b
        tk.Frame(self._conv_frame, bg=COL["border"], height=1).pack(fill="x")

    def _build_shot_table(self, parent):
        f = tk.Frame(parent, bg=COL["bg"])
        f.pack(fill="both", expand=True)

        style = ttk.Style()
        style.configure("TS.Treeview", font=("Courier", 10), rowheight=22)
        style.configure("TS.Treeview.Heading", font=("Helvetica", 9))

        cols = ("#", "Sc", "Wind", "Elev", "Call")
        self._shot_tree = ttk.Treeview(f, columns=cols, show="headings",
                                       style="TS.Treeview")
        for col, w in (("#", 30), ("Sc", 30), ("Wind", 65),
                       ("Elev", 60), ("Call", 40)):
            self._shot_tree.heading(col, text=col)
            self._shot_tree.column(col, width=w, anchor="center", stretch=True)

        vsb = ttk.Scrollbar(f, orient="vertical",
                            command=self._shot_tree.yview)
        self._shot_tree.configure(yscrollcommand=vsb.set)
        self._shot_tree.pack(side="left", fill="both", expand=True)
        vsb.pack(side="right", fill="y")

        self._shot_tree.tag_configure("sighter",   foreground="#9ca3af")
        self._shot_tree.tag_configure("converted", foreground=COL["accent"])
        self._shot_tree.tag_configure("odd",       background=COL["bg2"])
        self._shot_tree.tag_configure("even",      background=COL["bg"])
        tk.Frame(parent, bg=COL["border"], height=1).pack(fill="x")

    def _build_action_row(self, parent):
        f = tk.Frame(parent, bg=COL["bg"])
        f.pack(fill="x", padx=12, pady=8)
        self._undo_btn = tk.Button(
            f, text="Undo", bg=COL["bg"], fg=COL["text"],
            font=("Helvetica", 12), relief="solid", bd=1,
            cursor="hand2", state="disabled", command=self.undo_shot,
        )
        self._undo_btn.pack(side="left", padx=(0, 8))
        self._discard_btn = tk.Button(
            f, text="Discard", bg=COL["bg"], fg="#A32D2D",
            font=("Helvetica", 12), relief="solid", bd=1,
            cursor="hand2", state="disabled", command=self._discard_current,
        )
        self._discard_btn.pack(side="left", padx=(0, 8))
        self._commit_btn = tk.Button(
            f, text="Save to Scorecard →", bg=COL["text"], fg="white",
            font=("Helvetica", 12), relief="flat", bd=0,
            cursor="hand2", state="disabled", command=self.commit_string,
        )
        self._commit_btn.pack(side="left", fill="x", expand=True)

    # ── Canvas drawing ─────────────────────────────────────────────────────────

    def _metrics(self) -> tuple[float, float, float, float, float]:
        """Live canvas geometry: (width, height, scale, centre_x, centre_y).
        Scale is derived from the smaller dimension so the target stays square
        and fits, and grows when the window is enlarged."""
        w = self._canvas.winfo_width()
        h = self._canvas.winfo_height()
        if w < 5:
            w = CANVAS_PX
        if h < 5:
            h = CANVAS_PX
        base = min(w, h) / (VB * 2)
        sc   = base * self._zoom
        cx   = w / 2 + self._pan[0]
        cy   = h / 2 + self._pan[1]
        return w, h, sc, cx, cy

    def _to_canvas(self, x: float, y: float) -> tuple[float, float]:
        _, _, sc, cx, cy = self._metrics()
        return x * sc + cx, y * sc + cy

    def _to_svg(self, px: float, py: float) -> tuple[float, float]:
        _, _, sc, cx, cy = self._metrics()
        return (px - cx) / sc, (py - cy) / sc

    def _draw_target_bg(self):
        c  = self._canvas
        c.delete("bg")
        mu = self.active_mu
        w, h, sc, cx, cy = self._metrics()

        c.create_rectangle(0, 0, w, h, fill=COL["target_bg"], outline="", tags="bg")

        highlight = round(R / mu)
        max_i     = int(VB / mu) + 1
        for i in range(-max_i, max_i + 1):
            gx = i * mu * sc + cx
            gy = i * mu * sc + cy
            if i == 0:
                colour, width = "#555", 0.8
            elif abs(i) == highlight:
                colour, width = "#999", 0.6
            else:
                colour, width = "#ccc", 0.4
            c.create_line(0, gy, w, gy, fill=colour, width=width, tags="bg")
            c.create_line(gx, 0, gx, h, fill=colour, width=width, tags="bg")

        ext = VB * sc
        c.create_line(cx-ext, cy-ext, cx+ext, cy+ext,
                      fill="#bbb", width=1.0, tags="bg")
        c.create_line(cx+ext, cy-ext, cx-ext, cy+ext,
                      fill="#bbb", width=1.0, tags="bg")
        p = 104 * sc
        c.create_line(cx-p, cy-p, cx+p, cy+p,
                      fill="#bbb", width=0.8, dash=(6, 4), tags="bg")
        c.create_line(cx+p, cy-p, cx-p, cy+p,
                      fill="#bbb", width=0.8, dash=(6, 4), tags="bg")

        for ring in reversed(self.active_rings):
            r_px = ring["r"] * sc
            lw   = 1.8 if ring["r"] >= R * 0.14 else 1.2
            c.create_oval(cx-r_px, cy-r_px, cx+r_px, cy+r_px,
                          outline=COL["target_ink"], width=lw, tags="bg")

        c.create_rectangle(0, 0, w, h, outline="#555", width=1, tags="bg")
        c.create_text(6, 5, text=f"1 MOA · {self.active_dist}", anchor="nw",
                      fill="#aaa", font=("Courier", 7), tags="bg")
        # keep the reset-view button anchored to the top-right corner
        self._canvas.coords(self._reset_win, w - 6, 6)

    def _draw_shots(self):
        self._canvas.delete("shot")
        labels = self._compute_labels(self.shots, self.conv)
        _, _, sc, _, _ = self._metrics()

        for shot, lbl in zip(self.shots, labels):
            px, py = self._to_canvas(shot["x"], shot["y"])
            sg  = shot["tp"] in ("A", "B")
            cvt = ((shot["tp"] == "A" and self.conv == "ab") or
                   (shot["tp"] == "B" and self.conv in ("b", "ab")))

            fill_col = COL["gray_shot"] if (sg and not cvt) else COL["red_shot"]
            ring_col = COL["gray_ring"] if (sg and not cvt) else COL["gold_ring"]
            text_col = "#374151"        if (sg and not cvt) else "white"
            r_px     = 6.5 * sc

            if shot["iv"]:
                vr = 9.5 * sc
                self._canvas.create_oval(px-vr, py-vr, px+vr, py+vr,
                                         outline=ring_col, width=2, tags="shot")
            self._canvas.create_oval(px-r_px, py-r_px, px+r_px, py+r_px,
                                     fill=fill_col, outline="", tags="shot")
            font_sz = max(6, int(6 * sc))
            self._canvas.create_text(px, py, text=lbl, fill=text_col,
                                     font=("Courier", font_sz, "bold"), tags="shot")

    def _draw_shot_preview(self, px: float, py: float):
        _, _, sc, _, _ = self._metrics()
        r = 6.5 * sc
        self._canvas.create_oval(px-r, py-r, px+r, py+r,
                                 outline=COL["accent"], fill="", width=2,
                                 dash=(4, 3), tags="preview")
        self._canvas.create_line(px-r*1.6, py, px+r*1.6, py,
                                 fill=COL["accent"], width=1, dash=(2, 3),
                                 tags="preview")
        self._canvas.create_line(px, py-r*1.6, px, py+r*1.6,
                                 fill=COL["accent"], width=1, dash=(2, 3),
                                 tags="preview")

    def _redraw_target(self):
        self._draw_target_bg()
        self._draw_shots()

    # ── Event handlers ─────────────────────────────────────────────────────────

    def _on_shot_press(self, event):
        self._canvas.focus_set()   # leaving the target-no. field stops its caret blink
        self._canvas.delete("preview")
        self._draw_shot_preview(event.x, event.y)

    def _on_shot_drag(self, event):
        self._canvas.delete("preview")
        self._draw_shot_preview(event.x, event.y)

    def _on_shot_release(self, event):
        self._canvas.delete("preview")
        ph = self._get_phase()
        if ph["tp"] == "done":
            return
        if ph["tp"] == "sc" and not self.conv_chosen:
            self.conv_chosen = True
        svgx, svgy = self._to_svg(event.x, event.y)
        result = score_shot(svgx, svgy, self.active_rings)
        self.shots.append({
            "x": svgx, "y": svgy,
            "sc": result["sc"], "iv": result["iv"], "lb": result["lb"],
            "tp": ph["tp"],
            "w":  self.wind_val, "e": self.elev_val,
            "cl": None,
        })
        self.render()
        self._save_session()

    def _on_zoom(self, event):
        w, h, _, _, _ = self._metrics()
        cx0, cy0 = w / 2, h / 2
        factor   = 1.15 if event.delta > 0 else 1 / 1.15
        new_zoom = max(0.5, min(8.0, self._zoom * factor))
        actual   = new_zoom / self._zoom
        self._pan[0] = event.x - cx0 - (event.x - cx0 - self._pan[0]) * actual
        self._pan[1] = event.y - cy0 - (event.y - cy0 - self._pan[1]) * actual
        self._zoom   = new_zoom
        self._redraw_target()

    def _on_pan_start(self, event):
        self._drag_anchor = (event.x, event.y, self._pan[0], self._pan[1])

    def _on_pan_drag(self, event):
        if self._drag_anchor is None:
            return
        ax, ay, p0, p1 = self._drag_anchor
        self._pan[0] = p0 + event.x - ax
        self._pan[1] = p1 + event.y - ay
        self._redraw_target()

    def _reset_view(self):
        self._zoom = 1.0
        self._pan  = [0.0, 0.0]
        self._redraw_target()

    def _on_reset_view(self, _):
        self._reset_view()

    # ── Dial / call controls ───────────────────────────────────────────────────

    def adj_wind(self, direction: int):
        self.wind_val = clamp(snap(self.wind_val + direction * 0.25))
        self._update_controls()
        if self.shots:
            self._save_session()

    def adj_elev(self, direction: int):
        self.elev_val = clamp(snap(self.elev_val + direction * 0.25))
        self._update_controls()
        if self.shots:
            self._save_session()

    def edit_value(self, which: str):
        current = self.wind_val if which == "wind" else self.elev_val
        prompt  = (f"Wind (negative = Left, positive = Right, ±{int(MAXV)})"
                   if which == "wind"
                   else f"Elevation (negative = Down, positive = Up, ±{int(MAXV)})")
        result = simpledialog.askfloat(
            title=which.capitalize(), prompt=prompt,
            initialvalue=current, minvalue=-MAXV, maxvalue=MAXV,
            parent=self.root,
        )
        if result is not None:
            v = clamp(snap(result))
            if which == "wind":
                self.wind_val = v
            else:
                self.elev_val = v
            self._update_controls()
            if self.shots:
                self._save_session()

    def set_call(self, key: str):
        if not self.shots:
            return
        s = self.shots[-1]
        s["cl"] = None if s["cl"] == key else key
        self._update_call_buttons()
        self._refresh_shot_table()
        self._save_session()

    def set_conv(self, key: str):
        self.conv = key
        self.conv_chosen = True
        for k, b in self._conv_btns.items():
            b.config(bg=COL["text"] if k == key else COL["bg"],
                     fg="white"     if k == key else COL["text2"])
        self.render()
        self._save_session()

    def undo_shot(self):
        if self.shots:
            self.shots.pop()
            if len(self.shots) < 2:
                self.conv_chosen = False
                self.conv = "none"
            self.render()
            self._save_session()

    # ── Render / update ────────────────────────────────────────────────────────

    def render(self):
        ph  = self._get_phase()
        tot = self._calc_total(self.shots, self.conv)

        self._phase_lbl.config(text=f"Next: {ph['lb']}")
        self._score_lbl.config(text=str(tot["tot"]))
        self._v_lbl.config(text=f"  v{tot['v']}" if tot["v"] else "")
        self._count_lbl.config(text=f"{tot['n']}/{self.shoot_len}")

        if len(self.shots) >= 2 and not self.conv_chosen:
            self._conv_frame.pack(fill="x",
                                  after=self._call_btns["bad"].master)
        else:
            self._conv_frame.pack_forget()

        self._draw_shots()
        self._canvas.config(
            cursor="crosshair" if ph["tp"] != "done" else "arrow")

        has = bool(self.shots)
        self._undo_btn.config(state="normal" if has else "disabled")
        self._discard_btn.config(state="normal" if has else "disabled")
        self._commit_btn.config(state="normal" if has else "disabled")

        self._update_call_buttons()
        self._refresh_shot_table()
        self._update_rec_row()
        self._draw_ballistic_graphs()

    # ── Ballistic graphs (suggested wind / elevation per shot) ──────────────────

    def _draw_ballistic_graphs(self):
        # Toggled off → hide the graph strips so the target uses the space
        if not self.show_graphs:
            self._elev_graph.grid_remove()
            self._wind_graph.grid_remove()
            return
        self._elev_graph.grid()
        self._wind_graph.grid()
        max_shots = self.shoot_len + 2   # scored shots + the two sighters
        graphs.draw_elev_graph(self._elev_graph, self.shots, self.active_mu,
                               max_shots, ELEV_GRAPH_W, CANVAS_PX)
        graphs.draw_wind_graph(self._wind_graph, self.shots, self.active_mu,
                               max_shots, CANVAS_PX, WIND_GRAPH_H)

    def _update_controls(self):
        self._wind_var.set(wind_label(self.wind_val))
        self._wind_lbl_widget.config(
            fg=COL["text"] if self.wind_val != 0 else COL["text2"])
        self._elev_var.set(elev_label(self.elev_val))
        self._elev_lbl_widget.config(
            fg=COL["text"] if self.elev_val != 0 else COL["text2"])
        self._update_rec_row()

    def _update_rec_row(self):
        r = self._compute_recommendation() if self.show_rec else None
        if r:
            if not self._rec_frame.winfo_ismapped():
                self._rec_frame.pack(
                    fill="x", before=self._call_btns["pull-high"].master)
            self._rec_w_var.set(wind_label(r["w"]))
            self._rec_e_var.set(elev_label(r["e"]))
            self._rec_n_var.set(f"({r['n']} shot{'s' if r['n'] > 1 else ''})")
        else:
            self._rec_frame.pack_forget()

    def _update_call_buttons(self):
        cur = self.shots[-1]["cl"] if self.shots else None
        has = bool(self.shots)
        for key, btn in self._call_btns.items():
            btn.config(state="normal" if has else "disabled")
            if cur == key:
                btn.config(
                    bg="#eaf3de" if key == "good" else
                       "#fcebeb" if key == "bad"  else COL["bg"],
                    fg="#3B6D11" if key == "good" else
                       "#A32D2D" if key == "bad"  else COL["text"],
                )
            else:
                btn.config(bg=COL["bg2"], fg=COL["text2"])

    def _refresh_shot_table(self):
        for row in self._shot_tree.get_children():
            self._shot_tree.delete(row)
        labels = self._compute_labels(self.shots, self.conv)
        for i, (shot, lbl) in enumerate(zip(self.shots, labels)):
            is_sg  = lbl in ("A", "B")
            is_cvt = ((self.conv == "b"  and lbl == "1") or
                      (self.conv == "ab" and lbl in ("1", "2")))
            tag     = "converted" if is_cvt else "sighter" if is_sg else "normal"
            row_tag = "odd" if i % 2 else "even"
            self._shot_tree.insert("", "end", values=(
                lbl, shot["lb"],
                wind_label(shot["w"]), elev_label(shot["e"]),
                CALL_GLYPHS.get(shot["cl"], "") if shot["cl"] else "",
            ), tags=(tag, row_tag))
