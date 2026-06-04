# Contributing

Thanks for your interest in improving **chrome-gemini-button-restore**! This is a
small, focused tool, so contributing is lightweight.

## Ways to help

- **Report a bug** — open a [Bug report](../../issues/new?template=bug_report.yml).
  Include your Chrome version and the output of `--check`.
- **Suggest a feature** — open a [Feature request](../../issues/new?template=feature_request.yml).
- **Send a fix** — open a pull request (see below).

## Development setup

There is no build step. The tool is a single Bash script:

```
scripts/fix-chrome-gemini-region.sh
```

Requirements: `bash`, `python3`, macOS (the `Local State` path and Chrome behavior
are macOS-specific).

## Before opening a pull request

1. **Lint passes.** CI runs [ShellCheck](https://www.shellcheck.net/) on every push
   and PR. Run it locally first:
   ```bash
   shellcheck scripts/*.sh
   ```
   The PR cannot merge with ShellCheck warnings.

2. **Test the safe paths.** At minimum, verify read-only mode still works and never
   mutates state:
   ```bash
   bash scripts/fix-chrome-gemini-region.sh --check
   ```

3. **Respect the safety invariants.** Any change to the fix path MUST keep these:
   - Refuses to edit `Local State` while Chrome is running.
   - Always backs up to `Local State.backup` before editing.
   - Only changes the country code (never the Chrome version number).
   - Re-reads and validates the JSON after editing.
   - `--restore` can always roll back.

4. **Keep it dependency-free.** No third-party tools beyond `bash` + `python3`
   (both ship with macOS). No external network calls.

## Commit and PR style

- Keep commits focused; write a clear, present-tense subject line.
- Describe *what changed and why* in the PR body.
- Do not commit personal data (real emails, absolute home paths, IPs, secrets).

## Reporting security issues

If you find a way the script could corrupt `Local State` or lose data, please open
an issue describing the scenario so it can be fixed quickly.
