# DayTerm

## Interactive day planner for the command line

DayTerm is an interactive command line tool that displays your appointments and todos in a clear view. It is based on `khal`, `todoman` and `vdirsyncer`.

## Features

- Switchable agenda, week, month, and task views
- Responsive weekly time grid with calendar blocks and a compact narrow-terminal fallback
- Responsive monthly grid with event counts and titles inside each day
- Vim-style calendar cursor for selecting, editing, and creating events
- Date navigation without reloading unchanged calendar ranges
- Automatic update at adjustable intervals
- Dynamic adjustment to window size changes
- Interactive commands for detailed views
- Colored output for better readability
- Low-idle main loop with cached calendar/todo data
- Persistent, deduplicated desktop notifications via `notify-send`

## Requirements

- Bash 4.0 or higher
- Python 3.8 or higher (fast buffered TUI renderer)
- [`jq`](https://jqlang.github.io/jq/) (stable JSON parsing)
- [`khal`](https://github.com/pimutils/khal) (calendar management)
- [`todoman`](https://github.com/pimutils/todoman), usually installed as `todo` (optional todo management)
- [`vdirsyncer`](https://github.com/pimutils/vdirsyncer) (optional synchronization)
- `notify-send` (optional desktop notifications)
- Python `wcwidth` module (optional, recommended for correct emoji alignment in boxes)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/delightfuldude/dayterm.git
   cd dayterm
   ```

2. Make the main script executable:
   ```bash
   chmod +x dayterm.sh
   ```
3. Optional: Link it into your user PATH while keeping the repository intact:
   ```bash
   mkdir -p ~/.local/bin
   ln -s "$PWD/dayterm.sh" ~/.local/bin/dayterm
   ```

## Usage

Start DayTerm by running:
   ```bash
   ./dayterm.sh
   ```
or if you linked it into your PATH:
   ```bash
   dayterm
   ```

Useful checks:
   ```bash
   ./dayterm.sh --check
   ./dayterm.sh --once
   ./dayterm.sh --notify-test
   ```

### Keyboard shortcuts

- `a` / `w` / `m` / `t`: agenda, week, month, and task views
- Week: `h` / `l` select a day, `j` / `k` move the time cursor, and `J` / `K` move by week
- Month: `h` / `l` select a day and `j` / `k` move by week
- Agenda: `h` / `k` move back and `j` / `l` move forward
- `g`: return to today
- `e` or `Enter`: edit the event under the calendar cursor, or create one in an empty slot
- `n` / `N`: create an event at the selected date/time, or create a todo
- `s`: synchronize with vdirsyncer and show its progress and result
- `c`: open ikhal or khal interactive
- `i`: edit DayTerm settings
- `?`: help
- `q`: quit

## Configuration

The script uses the default configurations from khal and todoman. Make sure these tools are set up correctly.

Typical configuration files:
- khal: `~/.config/khal/config`
- todoman: `~/.config/todoman/config.py`
- vdirsyncer: `~/.config/vdirsyncer/config`

DayTerm's settings are stored in `~/.config/dayterm/settings.conf` and can be accessed directly from the main screen using the `i` key.

Important DayTerm settings:
- `UPDATE_INTERVAL`: expensive calendar refresh interval in seconds
- `TODO_UPDATE_INTERVAL`: todo refresh interval in seconds
- `DEFAULT_VIEW`: `agenda`, `week`, `month`, or `tasks`
- `WEEK_START_HOUR` / `WEEK_END_HOUR`: visible hours in the weekly time grid
- `WEEK_CURSOR_STEP_MINUTES`: vertical cursor step in the weekly time grid
- `TODOS_ENABLED`: `auto`, `1`, or `0`
- `NOTIFICATIONS_ENABLED`: `1` or `0`
- `NOTIFICATION_OFFSETS`: reminder offsets in minutes before an event
- `NOTIFICATION_CHECK_INTERVAL`: notification scan interval in seconds
- `NOTIFICATION_DATA_REFRESH_INTERVAL`: refresh interval for the independent reminder feed
- `NOTIFICATION_SEND_TIMEOUT_SECONDS`: maximum wait for the desktop notification service
- `MISSED_NOTIFICATIONS_ENABLED`: send a bounded notification for recently missed events
- `MAX_MISSED_NOTIFICATION_TIME`: missed-event window in minutes
- `NOTIFICATION_STATE_RETENTION_DAYS`: retention for delivered-notification IDs
- `TUI_BOXES`: `1` or `0`
- `TUI_BOX_STYLE`: `unicode` or `ascii`
- `COLOR_THEME`: `auto`, `dark`, `light`, or `none`

`COLOR_THEME=auto` respects the global `NO_COLOR` convention. Set `COLOR_THEME=dark` or `COLOR_THEME=light` to explicitly enable DayTerm's palette.

## Automatic update

The script updates the display:
- Configurable update interval
- When the terminal window size changes
- When using the interactive commands

Calendar and todo tools are not polled every second. The main loop only checks keyboard input, refresh deadlines, and notification deadlines, which keeps idle CPU usage low on older hardware.

Navigation inside the currently loaded week or month only redraws the buffered screen. Both grids use the available terminal height and are redrawn as one buffered frame. A new `khal` process is started when the visible date range actually changes. Notifications use their own small today-oriented event cache, so browsing another month cannot suppress current reminders.

## Architecture

- `vdirsyncer` synchronizes local VDIR collections with CalDAV/CardDAV servers.
- `khal` reads and edits calendar data; `todoman` reads and edits VTODO data.
- `khard` remains the contact provider for future attendee selection.
- DayTerm owns view state, rendering, caching, keyboard interaction, and notification delivery.

calcurse and Taskwarrior are UX references only; they are not DayTerm backends.

## Roadmap

- Cursor-based event and task selection in the agenda and task views
- Configurable handling of all-day reminders
- iTIP/iMIP invitation support for REQUEST, REPLY and CANCEL messages
- Interoperability tests with Thunderbird, Outlook, Google Calendar and Nextcloud

## License

MIT License
