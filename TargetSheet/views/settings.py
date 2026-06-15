import tkinter as tk
from tkinter import ttk

from constants import COL
from targets import TARGET_CONFIGS, BISLEY_DISTANCES, DCRA_METRIC_DISTANCES


class SettingsMixin:
    """Builds the options screen and the saved-presets screen."""

    def _build_options_view(self):
        self._vo = tk.Frame(self._content, bg=COL["bg"])
        self._build_nav_bar(self._vo, "← Menu",
                            lambda: self.show_screen("menu"), "Options")

        body = tk.Frame(self._vo, bg=COL["bg"])
        body.pack(fill="x", padx=20, pady=20)

        # ── Suggested wind/elevation toggle ─────────────────────────────────
        row = tk.Frame(body, bg=COL["bg2"])
        row.pack(fill="x", pady=6, ipady=4)
        text = tk.Frame(row, bg=COL["bg2"])
        text.pack(side="left", fill="x", expand=True, padx=14, pady=6)
        tk.Label(text, text="Suggested wind & elevation",
                 bg=COL["bg2"], fg=COL["text"],
                 font=("Helvetica", 13, "bold"), anchor="w").pack(fill="x")
        tk.Label(text,
                 text='Show the "Dial to" recommendation that centres the group.',
                 bg=COL["bg2"], fg=COL["text2"],
                 font=("Helvetica", 9), anchor="w").pack(fill="x")

        self._show_rec_var = tk.BooleanVar(value=self.show_rec)
        tk.Checkbutton(
            row, variable=self._show_rec_var, bg=COL["bg2"],
            activebackground=COL["bg2"], cursor="hand2", bd=0,
            highlightthickness=0, command=self._toggle_show_rec,
        ).pack(side="right", padx=14)

        # ── Ballistic-graphs toggle ─────────────────────────────────────────
        row2 = tk.Frame(body, bg=COL["bg2"])
        row2.pack(fill="x", pady=6, ipady=4)
        text2 = tk.Frame(row2, bg=COL["bg2"])
        text2.pack(side="left", fill="x", expand=True, padx=14, pady=6)
        tk.Label(text2, text="Wind and elevation graphs",
                 bg=COL["bg2"], fg=COL["text"],
                 font=("Helvetica", 13, "bold"), anchor="w").pack(fill="x")
        tk.Label(text2,
                 text="Show the wind & elevation graphs on the live target. "
                      "They always appear in scorecard analysis.",
                 bg=COL["bg2"], fg=COL["text2"],
                 font=("Helvetica", 9), anchor="w").pack(fill="x")

        self._show_graphs_var = tk.BooleanVar(value=self.show_graphs)
        tk.Checkbutton(
            row2, variable=self._show_graphs_var, bg=COL["bg2"],
            activebackground=COL["bg2"], cursor="hand2", bd=0,
            highlightthickness=0, command=self._toggle_show_graphs,
        ).pack(side="right", padx=14)

    def _toggle_show_rec(self):
        self.show_rec = self._show_rec_var.get()
        self._update_rec_row()
        self._save_settings()

    def _toggle_show_graphs(self):
        self.show_graphs = self._show_graphs_var.get()
        self._draw_ballistic_graphs()
        self._save_settings()

    def _build_presets_view(self):
        self._vp = tk.Frame(self._content, bg=COL["bg"])
        self._build_nav_bar(self._vp, "← Menu",
                            lambda: self.show_screen("menu"), "Saved Presets")

        tk.Label(
            self._vp,
            text="Store your aperture and elevation settings "
                 "for each distance and standard.",
            bg=COL["bg"], fg=COL["text2"], font=("Helvetica", 10),
        ).pack(pady=(10, 0))

        # Scrollable container so all groups are reachable
        scroll_wrap = tk.Frame(self._vp, bg=COL["bg"])
        scroll_wrap.pack(fill="both", expand=True)
        sc = tk.Canvas(scroll_wrap, bg=COL["bg"], bd=0, highlightthickness=0)
        vsb = ttk.Scrollbar(scroll_wrap, orient="vertical", command=sc.yview)
        sc.configure(yscrollcommand=vsb.set)
        vsb.pack(side="right", fill="y")
        sc.pack(side="left", fill="both", expand=True)
        body = tk.Frame(sc, bg=COL["bg"])
        win = sc.create_window((0, 0), window=body, anchor="nw")
        body.bind("<Configure>",
                  lambda _: sc.configure(scrollregion=sc.bbox("all")))
        sc.bind("<Configure>", lambda e: sc.itemconfig(win, width=e.width))
        sc.bind("<MouseWheel>",
                lambda e: sc.yview_scroll(int(-e.delta / 120), "units"))

        style = ttk.Style()
        style.configure("TNotebook.Tab", font=("Helvetica", 11), padding=(12, 6))

        groups = [
            ("NRA / Bisley  (yards)",   [f"{d}-nra"  for d in BISLEY_DISTANCES]),
            ("DCRA  (yards)",           [f"{d}-dcra" for d in BISLEY_DISTANCES]),
            ("DCRA domestic  (metres)", [f"{d}-dcra" for d in DCRA_METRIC_DISTANCES]),
        ]
        for group_label, cfg_keys in groups:
            tk.Frame(body, bg=COL["border"], height=1).pack(
                fill="x", padx=20, pady=(14, 0))
            tk.Label(body, text=group_label, bg=COL["bg"], fg=COL["accent"],
                     font=("Helvetica", 10, "bold")).pack(
                         anchor="w", padx=20, pady=(6, 2))

            nb = ttk.Notebook(body)
            nb.pack(fill="x", padx=20, pady=(0, 6))

            for cfg_key in cfg_keys:
                dist_label = TARGET_CONFIGS[cfg_key]["dist"]
                tab  = tk.Frame(nb, bg=COL["bg"])
                nb.add(tab, text=dist_label)
                form = tk.Frame(tab, bg=COL["bg"])
                form.pack(anchor="center", pady=30)
                for field_label, fkey in (("Aperture", "aperture"),
                                          ("Elevation", "elevation")):
                    row = tk.Frame(form, bg=COL["bg"])
                    row.pack(fill="x", pady=8)
                    tk.Label(row, text=f"{field_label}:", bg=COL["bg"],
                             fg=COL["text"], font=("Helvetica", 13),
                             width=10, anchor="e").pack(side="left")
                    var = tk.StringVar(value=self.presets[cfg_key][fkey])
                    tk.Entry(row, textvariable=var, font=("Courier", 14),
                             width=16, relief="solid", bd=1).pack(
                                 side="left", padx=(10, 0))
                    var.trace_add("write",
                                  lambda *_, ck=cfg_key, fk=fkey, v=var:
                                  (self.presets[ck].update({fk: v.get()}),
                                   self._save_presets()))
