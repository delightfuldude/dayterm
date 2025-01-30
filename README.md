# DayTerm

A terminal-based day planner and task management tool built in Bash. DayTerm integrates with `khal` for calendar management and provides an interactive terminal interface for managing your daily schedule.

## Features

- Calendar integration with khal
- Interactive event management
- Real-time display updates
- Terminal-based user interface
- Configurable settings

## Prerequisites

- Bash 4.0 or higher
- khal (Calendar manager)
- vdirsyncer (Calendar synchronization)

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

3. Ensure khal is properly configured:
   - Install khal: `pip install khal`
   - Configure khal in `~/.config/khal/config`
   - Set up vdirsyncer if you want calendar synchronization

## Usage

Start DayTerm by running:
```bash
./dayterm.sh
```

### Key Commands

- `e` - Show event details (e to edit)
- `t` - Show todo details (e to edit)
- `n` - New event
- `a` - Add todo
- `s` - Server sync
- `c` - Calendar (ikhal)
- `i` - Settings
- `h` - Show help
- `q` - Quit

## Configuration

DayTerm's settings are stored in `~/.config/dayterm/settings.conf`. You can modify:

- Update interval
- Display preferences
- Other customizable options

## License

MIT License
