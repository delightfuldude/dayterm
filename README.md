# DayTerm
## Interactive day planner for the command line

DayTerm is an interactive command line tool that displays your appointments and todos in a clear view. It is based on `khal`, `todoman` and `vdirsyncer`.

## Features

- Clear display of appointments and todos
- Automatic update at adjustable intervals
- Dynamic adjustment to window size changes
- Interactive commands for detailed views
- Colored output for better readability
- Low-idle main loop with cached calendar/todo data
- Desktop notifications via `notify-send`

## Requirements
- Bash 4.0 or higher
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
3. Optional: Move it to your PATH:
   ```bash
   sudo mv dayterm.sh /usr/local/bin/dayterm
   ```

## Usage

Start DayTerm by running:
   ```bash
   ./dayterm.sh
   ```
or if you moved it to your PATH:
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

- `e`: Shows detailed appointment information
- `t`: Shows detailed todo information
- `n`: Creates a new appointment
- `a`: Adds a new todo
- `s`: Synchronizes with the server
- `c`: Opens the calendar
- `i`: Opens the settings
- `h`: Shows the help menu
- `q`: Exits the program

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
- `AGENDA_START` / `AGENDA_END`: date range passed to `khal list`
- `TODOS_ENABLED`: `auto`, `1`, or `0`
- `NOTIFICATIONS_ENABLED`: `1` or `0`
- `NOTIFICATION_OFFSETS`: reminder offsets in minutes before an event
- `NOTIFICATION_CHECK_INTERVAL`: notification scan interval in seconds
- `MISSED_NOTIFICATIONS_ENABLED`: send a bounded notification for recently missed events
- `MAX_MISSED_NOTIFICATION_TIME`: missed-event window in minutes
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

## Roadmap

- Better notification policy for all-day events and recurring events
- iTIP/iMIP invitation support for REQUEST, REPLY and CANCEL messages
- Interoperability tests with Thunderbird, Outlook, Google Calendar and Nextcloud

## License

MIT License
