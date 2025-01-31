# DayTerm
## Interactive day planner for the command line

DayTerm is an interactive command line tool that displays your appointments and todos in a clear view. It is based on `khal`, `todoman` and `vdirsyncer`.

## Features

- Clear display of appointments and todos
- Automatic update at adjustable intervals
- Dynamic adjustment to window size changes
- Interactive commands for detailed views
- Colored output for better readability

## Requirements
- Bash 4.0 or higher
- [`khal`](https://github.com/pimutils/khal) (calendar management)
- [`todoman`](https://github.com/pimutils/todoman) (todo management)
- [`vdirsyncer`](https://github.com/pimutils/vdirsyncer) (synchronization)

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

## Automatic update

The script updates the display:
- Configurable update interval
- When the terminal window size changes
- When using the interactive commands

## License

MIT License