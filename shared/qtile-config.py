from libqtile import bar, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy

mod = "mod4"  # Super/Windows key
terminal = "alacritty"

keys = [
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    
    # Move windows
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    
    # Grow windows
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Move window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Move window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    
    # Toggle between split and unsplit sides of stack
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(), desc="Toggle between split and unsplit sides of stack"),
    
    # Launch applications
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "b", lazy.spawn("google-chrome-stable"), desc="Launch browser"),
    Key([mod], "e", lazy.spawn("dolphin"), desc="Launch file manager"),
    
    # Rofi launcher
    Key([mod], "r", lazy.spawn("rofi -show drun"), desc="Launch rofi"),
    
    # Toggle between different layouts
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    
    # Close window
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    
    # Toggle fullscreen
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen on the focused window"),
    
    # Toggle floating
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    
    # Reload and quit
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    
    # Audio controls
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%")),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%")),
    Key([], "XF86AudioMute", lazy.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")),
    
    # Brightness controls
    Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set +10%")),
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 10%-")),
    
    # Screenshot
    Key([], "Print", lazy.spawn("flameshot gui")),
]

# Workspaces
groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend([
        Key([mod], i.name, lazy.group[i.name].toscreen(), desc=f"Switch to group {i.name}"),
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=True), 
            desc=f"Switch to & move focused window to group {i.name}"),
    ])

# Catppuccin Mocha colors
colors = {
    "rosewater": "#f5e0dc",
    "flamingo": "#f2cdcd",
    "pink": "#f5c2e7",
    "mauve": "#cba6f7",
    "red": "#f38ba8",
    "maroon": "#eba0ac",
    "peach": "#fab387",
    "yellow": "#f9e2af",
    "green": "#a6e3a1",
    "teal": "#94e2d5",
    "sky": "#89dceb",
    "sapphire": "#74c7ec",
    "blue": "#89b4fa",
    "lavender": "#b4befe",
    "text": "#cdd6f4",
    "subtext1": "#bac2de",
    "subtext0": "#a6adc8",
    "overlay2": "#9399b2",
    "overlay1": "#7f849c",
    "overlay0": "#6c7086",
    "surface2": "#585b70",
    "surface1": "#45475a",
    "surface0": "#313244",
    "base": "#1e1e2e",
    "mantle": "#181825",
    "crust": "#11111b",
}

# Layouts
layouts = [
    layout.Columns(
        border_focus=colors["blue"],
        border_normal=colors["surface0"],
        border_width=2,
        margin=8,
    ),
    layout.Max(),
    layout.Floating(
        border_focus=colors["blue"],
        border_normal=colors["surface0"],
        border_width=2,
    ),
]

widget_defaults = dict(
    font="JetBrainsMono Nerd Font",
    fontsize=12,
    padding=3,
    background=colors["base"],
    foreground=colors["text"],
)

extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    active=colors["text"],
                    inactive=colors["surface1"],
                    highlight_method="block",
                    this_current_screen_border=colors["blue"],
                    this_screen_border=colors["surface2"],
                    urgent_alert_method="block",
                    urgent_border=colors["red"],
                    disable_drag=True,
                    fontsize=14,
                ),
                widget.Prompt(
                    foreground=colors["blue"],
                ),
                widget.WindowName(
                    foreground=colors["subtext1"],
                    max_chars=50,
                ),
                widget.Chord(
                    chords_colors={
                        "launch": (colors["red"], colors["text"]),
                    },
                    name_transform=lambda name: name.upper(),
                ),
                widget.Systray(
                    icon_size=18,
                    padding=5,
                ),
                widget.Sep(
                    linewidth=0,
                    padding=10,
                ),
                widget.CPU(
                    format=" {load_percent}%",
                    foreground=colors["green"],
                ),
                widget.Memory(
                    format=" {MemUsed:.0f}{mm}",
                    foreground=colors["yellow"],
                ),
                widget.Net(
                    format="󰈀 {down:.0f}{down_suffix}",
                    foreground=colors["peach"],
                ),
                widget.Volume(
                    fmt=" {}",
                    foreground=colors["mauve"],
                ),
                widget.Battery(
                    format="{char} {percent:2.0%}",
                    charge_char="",
                    discharge_char="",
                    full_char="",
                    foreground=colors["teal"],
                ),
                widget.Clock(
                    format=" %Y-%m-%d %H:%M",
                    foreground=colors["blue"],
                ),
                widget.Sep(
                    linewidth=0,
                    padding=10,
                ),
            ],
            30,
            background=colors["base"],
            border_width=[0, 0, 2, 0],
            border_color=colors["surface0"],
            margin=[8, 8, 0, 8],
        ),
    ),
]

# Drag floating layouts
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False

floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
    ],
    border_focus=colors["blue"],
    border_normal=colors["surface0"],
    border_width=2,
)

auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True
wl_input_rules = None
wmname = "LG3D"
