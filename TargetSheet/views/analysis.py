import math
import tkinter as tk
from tkinter import ttk

from constants import COL, R, VB
from scoring import wind_label, elev_label, CALL_GLYPHS
from targets import TARGET_CONFIGS, build_dist_config
import graphs


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
        live target: elevation graph to the right, wind graph below."""
        SIZE    = 500
        EW, WH  = 150, 150        # elevation-graph width, wind-graph height
        BASE_SC = SIZE / (VB * 2)
        half    = SIZE / 2
        dist_key = dist if dist in TARGET_CONFIGS else "300y-nra"
        rings, _ = build_dist_config(dist_key)

        wrapper = tk.Frame(parent, bg=COL["bg"])
        wrapper.pack(pady=(10, 4))

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
        tgt_row.pack(anchor="w")
        canvas = tk.Canvas(tgt_row, width=SIZE, height=SIZE,
                           bg=COL["target_bg"], bd=0, highlightthickness=1,
                           highlightbackground=COL["border"], cursor="fleur")
        canvas.pack(side="left")
        elev_c = tk.Canvas(tgt_row, width=EW, height=SIZE, bg=COL["target_bg"],
                           bd=0, highlightthickness=1,
                           highlightbackground=COL["border"])
        elev_c.pack(side="left", padx=(6, 0))

        # Wind graph below the target face
        wind_c = tk.Canvas(wrapper, width=SIZE, height=WH, bg=COL["target_bg"],
                           bd=0, highlightthickness=1,
                           highlightbackground=COL["border"])
        wind_c.pack(anchor="w", pady=(6, 0))

        graphs.draw_elev_graph(elev_c, shots, mu, max_shots, EW, SIZE)
        graphs.draw_wind_graph(wind_c, shots, mu, max_shots, SIZE, WH)

        def eff():
            sc = BASE_SC * self._a_zoom
            return sc, half + self._a_pan[0], half + self._a_pan[1]

        def draw():
            canvas.delete("all")
            sc, cx, cy = eff()

            canvas.create_rectangle(0, 0, SIZE, SIZE,
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
                canvas.create_line(0, gy, SIZE, gy, fill=colour, width=lw)
                canvas.create_line(gx, 0, gx, SIZE, fill=colour, width=lw)

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

            canvas.create_rectangle(0, 0, SIZE, SIZE, outline="#555", width=1)
            canvas.create_text(4, 3, text=f"1 MOA · {dist}", anchor="nw",
                               fill="#aaa", font=("Courier", 6))

            labels = self._compute_labels(shots, cv)
            r_px   = 6.5 * sc
            for shot, lbl in zip(shots, labels):
                spx = shot["x"] * sc + cx
                spy = shot["y"] * sc + cy
                sg  = shot["tp"] in ("A", "B")
                cvt = ((shot["tp"] == "A" and cv == "ab") or
                       (shot["tp"] == "B" and cv in ("b", "ab")))
                fill_col = COL["gray_shot"] if (sg and not cvt) else COL["red_shot"]
                ring_col = COL["gray_ring"] if (sg and not cvt) else COL["gold_ring"]
                text_col = "#374151"        if (sg and not cvt) else "white"

                if shot["iv"]:
                    vr = 9.5 * sc
                    canvas.create_oval(spx-vr, spy-vr, spx+vr, spy+vr,
                                       outline=ring_col, width=2)
                canvas.create_oval(spx-r_px, spy-r_px, spx+r_px, spy+r_px,
                                   fill=fill_col, outline="")
                font_sz = max(5, int(6 * sc))
                canvas.create_text(spx, spy, text=lbl, fill=text_col,
                                   font=("Courier", font_sz, "bold"))

        _drag: dict = {}

        def on_zoom(event):
            factor   = 1.15 if event.delta > 0 else 1 / 1.15
            new_zoom = max(0.5, min(8.0, self._a_zoom * factor))
            actual   = new_zoom / self._a_zoom
            self._a_pan[0] = event.x - half - (event.x - half - self._a_pan[0]) * actual
            self._a_pan[1] = event.y - half - (event.y - half - self._a_pan[1]) * actual
            self._a_zoom   = new_zoom
            draw()

        def on_pan_start(event):
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

        reset_btn.config(command=lambda: on_reset(None))
        canvas.bind("<MouseWheel>",      on_zoom)
        canvas.bind("<Button-1>",        on_pan_start)
        canvas.bind("<B1-Motion>",       on_pan_drag)
        canvas.bind("<Double-Button-1>", on_reset)

        draw()

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

        self._draw_analysis_target(self._ac_inner, str_shots, cv, mu, dist,
                                   shoot_len + 2)

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
