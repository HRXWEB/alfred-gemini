# Alfred Gemini

Alfred workflow for quickly opening Google Gemini conversations from the official Gemini Mac app.

## Requirements

- macOS with Alfred Powerpack.
- The official Gemini Mac app named `Gemini.app`.
- Alfred Accessibility permission enabled in macOS:
  `System Settings -> Privacy & Security -> Accessibility -> Alfred`.

The workflow expects the app name to be `Gemini`.

## Commands

- `gm `: open a new Gemini conversation.
- `gmt `: open a new temporary Gemini conversation.

Both commands require a trailing space before pressing Return, which avoids accidental triggers while typing similar text.

## Behavior

- `gm` opens Gemini and uses `Command + N` to open a new chat.
- `gmt` opens Gemini and uses `Command + Shift + N` to open a new temporary chat.
- The workflow does not paste, type, or send prompts.

## Install

Download `alfred-gemini.alfredworkflow` from the latest release and double-click it to install.

## Troubleshooting

If the workflow only switches to Gemini but does not open the expected conversation:

1. Confirm Alfred has Accessibility permission.
2. Confirm the official Gemini Mac app is installed and named `Gemini.app`.
3. Restart Alfred after importing an updated workflow.

Runtime logs are written to:

```text
~/Library/Logs/alfred-gemini.log
```

## Release

Current version: `0.0.2`.
