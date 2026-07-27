# Alfred Gemini

Alfred workflow for quickly opening Google Gemini conversations from a Safari Dock web app.

## Requirements

- macOS with Alfred Powerpack.
- A Safari Dock web app named `Gemini.app`.
- Alfred Accessibility permission enabled in macOS:
  `System Settings -> Privacy & Security -> Accessibility -> Alfred`.

The workflow expects the app name to be `Gemini`. It does not depend on a machine-specific Safari Web App bundle identifier.

## Commands

- `gm `: open a new Gemini conversation.
- `gmt `: open a new temporary Gemini conversation.

Both commands require a trailing space before pressing Return, which avoids accidental triggers while typing similar text.

## Behavior

- `gm` uses Gemini's `Shift + Command + O` shortcut to open a new chat.
- `gmt` opens a new chat with the shortcut, then enables temporary chat.
- The workflow does not paste, type, or send prompts.
- Temporary-chat activation uses a cached window-relative button location for speed, with an Accessibility-based semantic fallback that refreshes the cache if the layout changes.

## Install

Download `alfred-gemini.alfredworkflow` from the latest release and double-click it to install.

## Troubleshooting

If the workflow only switches to Gemini but does not open the expected conversation:

1. Confirm Alfred has Accessibility permission.
2. Confirm the Safari Dock app is named `Gemini.app`.
3. Restart Alfred after importing an updated workflow.
4. Delete the temporary button cache and retry `gmt `:

   ```sh
   rm /tmp/alfred-gemini-temporary-button-cache
   ```

Runtime logs are written to:

```text
~/Library/Logs/alfred-gemini.log
```

## Release

Current version: `0.0.1`.
