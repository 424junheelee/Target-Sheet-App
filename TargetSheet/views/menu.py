import tkinter as tk
from tkinter import ttk

from constants import COL
from targets import TARGET_CONFIGS, BISLEY_DISTANCES, DCRA_METRIC_DISTANCES


class MenuMixin:
    """Builds the main menu and distance-selection screens."""

    def _build_menu_view(self):
        self._vm = tk.Frame(self._content, bg=COL["bg"])

        title_block = tk.Frame(self._vm, bg=COL["bg"])
        title_block.pack(pady=(60, 30))
        tk.Label(title_block, text="TargetSheet", bg=COL["bg"], fg=COL["text"],
                 font=("Helvetica", 36, "bold")).pack()
        tk.Label(title_block, text="DCRA Fullbore Marksmanship", bg=COL["bg"],
                 fg=COL["text2"], font=("Helvetica", 14)).pack(pady=(4, 0))

        btn_area = tk.Frame(self._vm, bg=COL["bg"])
        btn_area.pack()

        # Resume banner — shown only when a string is in progress.
        self._resume_card = tk.Frame(btn_area, bg=COL["accent"], cursor="hand2",
                                     relief="flat", bd=0)
        ri = tk.Frame(self._resume_card, bg=COL["accent"])
        ri.pack(side="left", fill="x", expand=True, padx=20)
        tk.Label(ri, text="Resume session", bg=COL["accent"], fg="white",
                 font=("Helvetica", 15, "bold"), anchor="w").pack(fill="x")
        self._resume_sub = tk.StringVar()
        tk.Label(ri, textvariable=self._resume_sub, bg=COL["accent"],
                 fg="#fdebcf", font=("Helvetica", 10), anchor="w").pack(fill="x")
        tk.Label(self._resume_card, text="▶", bg=COL["accent"], fg="white",
                 font=("Helvetica", 18)).pack(side="right", padx=20)
        for w in ([self._resume_card] + list(ri.winfo_children())
                  + list(self._resume_card.winfo_children())):
            w.bind("<Button-1>", lambda _: self.show_screen("target"))
        self._resume_btn_area = btn_area

        menu_items = [
            ("Target",    "Start a shooting session",        "dist_select"),
            ("Scorecard", "View saved scorecards",           "scorecard"),
            ("Presets",   "Manage distance sight settings",  "presets"),
            ("Options",   "Application settings",           "options"),
        ]
        self._first_menu_card = None
        for label, subtitle, screen in menu_items:
            card = tk.Frame(btn_area, bg=COL["nav_bg"], cursor="hand2",
                            relief="flat", bd=0)
            card.pack(fill="x", pady=6, ipadx=20, ipady=14)
            if self._first_menu_card is None:
                self._first_menu_card = card
            inner = tk.Frame(card, bg=COL["nav_bg"])
            inner.pack(side="left", fill="x", expand=True, padx=20)
            tk.Label(inner, text=label, bg=COL["nav_bg"], fg=COL["text"],
                     font=("Helvetica", 15, "bold"), anchor="w").pack(fill="x")
            tk.Label(inner, text=subtitle, bg=COL["nav_bg"], fg=COL["text2"],
                     font=("Helvetica", 10), anchor="w").pack(fill="x")
            tk.Label(card, text="›", bg=COL["nav_bg"], fg=COL["text2"],
                     font=("Helvetica", 20)).pack(side="right", padx=20)
            # "Target" starts a new session, but only when none is in progress.
            cmd = (self._menu_target if screen == "dist_select"
                   else (lambda s=screen: self.show_screen(s)))
            all_w = [card] + list(inner.winfo_children()) + list(card.winfo_children())
            for widget in all_w:
                widget.bind("<Button-1>", lambda _, c=cmd: c())

    def _menu_target(self):
        """Start a new session, or resume the current one if a series is open."""
        if self.shots:
            self._toast("Finish or discard the current series before starting a new one.")
            self.show_screen("target")
        else:
            self.show_screen("dist_select")

    def _set_shoot_len(self, n: int):
        """Choose the match length (10 or 15 scored shots) for the next session."""
        self.shoot_len = n
        for v, b in self._len_btns.items():
            if v == n:
                b.config(bg=COL["accent"], fg="white")
            else:
                b.config(bg=COL["bg"], fg=COL["text2"])
        self._save_settings()

    def _refresh_resume_button(self):
        """Show the resume banner only while a string is in progress."""
        if self.shots:
            n = len(self.shots)
            self._resume_sub.set(
                f"{self.active_dist} · {n} shot{'s' if n != 1 else ''} placed")
            if not self._resume_card.winfo_ismapped():
                self._resume_card.pack(fill="x", pady=(0, 14), ipadx=20, ipady=12,
                                       before=self._first_menu_card)
        else:
            self._resume_card.pack_forget()

    def _build_dist_select_view(self):
        self._vds = tk.Frame(self._content, bg=COL["bg"])
        self._build_nav_bar(self._vds, "← Menu",
                            lambda: self.show_screen("menu"), "Select Distance")

        scroll_wrap = tk.Frame(self._vds, bg=COL["bg"])
        scroll_wrap.pack(fill="both", expand=True)

        canvas = tk.Canvas(scroll_wrap, bg=COL["bg"], bd=0, highlightthickness=0)
        vsb = ttk.Scrollbar(scroll_wrap, orient="vertical", command=canvas.yview)
        canvas.configure(yscrollcommand=vsb.set)
        vsb.pack(side="right", fill="y")
        canvas.pack(side="left", fill="both", expand=True)

        inner = tk.Frame(canvas, bg=COL["bg"])
        win = canvas.create_window((0, 0), window=inner, anchor="nw")
        inner.bind("<Configure>",
                   lambda _: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.bind("<Configure>",
                    lambda e: canvas.itemconfig(win, width=e.width))

        tk.Label(inner,
                 text="Choose a distance and target standard for this session.",
                 bg=COL["bg"], fg=COL["text2"],
                 font=("Helvetica", 10)).pack(pady=(12, 4), padx=20, anchor="w")

        # Match length selector (10 or 15 scored shots)
        mlf = tk.Frame(inner, bg=COL["bg"])
        mlf.pack(fill="x", padx=20, pady=(0, 4))
        tk.Label(mlf, text="Match length:", bg=COL["bg"], fg=COL["text"],
                 font=("Helvetica", 11, "bold")).pack(side="left", padx=(0, 8))
        self._len_btns = {}
        for n in (10, 15):
            b = tk.Button(
                mlf, text=f"{n} shots", font=("Helvetica", 10),
                relief="solid", bd=1, cursor="hand2", padx=12,
                command=lambda v=n: self._set_shoot_len(v),
            )
            b.pack(side="left", padx=3)
            self._len_btns[n] = b
        self._set_shoot_len(self.shoot_len)

        sections = [
            ("NRA / Bisley  (Figure 12 — 72\" outer)", BISLEY_DISTANCES,       "nra"),
            ("DCRA yards  (ICFRA faces at Bisley distances)", BISLEY_DISTANCES, "dcra"),
            ("DCRA domestic metric  (ICFRA — Connaught ranges)",
             DCRA_METRIC_DISTANCES, "dcra"),
        ]
        for section_title, dist_list, standard in sections:
            tk.Label(inner, text=section_title,
                     bg=COL["bg"], fg=COL["accent"],
                     font=("Helvetica", 11, "bold")).pack(
                         pady=(14, 2), padx=20, anchor="w")

            for base_dist in dist_list:
                cfg_key = f"{base_dist}-{standard}"
                cfg     = TARGET_CONFIGS[cfg_key]
                radii   = cfg["rings_r_in"]
                yards   = (cfg["metres"] * 1.09361
                           if "metres" in cfg else cfg["yards"])
                ipm     = yards * 0.01047
                desc    = (f"Outer {radii[-1]/ipm:.1f} MOA r  ·  "
                           f"Bull {radii[1]/ipm:.2f} MOA r")

                card = tk.Frame(inner, bg=COL["nav_bg"], cursor="hand2",
                                relief="flat", bd=0)
                card.pack(fill="x", padx=20, pady=3, ipadx=16, ipady=8)
                lf = tk.Frame(card, bg=COL["nav_bg"])
                lf.pack(side="left", fill="x", expand=True, padx=12)
                tk.Label(lf, text=cfg["label"], bg=COL["nav_bg"],
                         fg=COL["text"], font=("Helvetica", 12, "bold"),
                         anchor="w").pack(fill="x")
                tk.Label(lf, text=desc, bg=COL["nav_bg"], fg=COL["text2"],
                         font=("Helvetica", 9), anchor="w").pack(fill="x")
                tk.Label(card, text="›", bg=COL["nav_bg"], fg=COL["text2"],
                         font=("Helvetica", 18)).pack(side="right", padx=12)
                all_w = ([card]
                         + list(lf.winfo_children())
                         + list(card.winfo_children()))
                for widget in all_w:
                    widget.bind("<Button-1>",
                                lambda _, k=cfg_key: self._select_distance(k))

        tk.Frame(inner, height=16, bg=COL["bg"]).pack()
