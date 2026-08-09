---
name: develop-zongheng-sihai
description: Develop, repair, test, export, and publish the Godot project “纵横四海：潮汐纪事” in this repository. Use whenever Codex changes this project's gameplay, story, 2D maps, UI, mobile/iOS behavior, web build, art, fonts, music, sound effects, tests, or release files. Every completed material project change includes validation, a commit to main, and deployment to the repository's GitHub Pages branch.
---

# Develop and publish 纵横四海

Read [references/project-map.md](references/project-map.md) before changing the project.

## Preserve project integrity

- Work inside `/Users/jianghu/Desktop/AI/四海` and inspect `git status` before editing.
- Preserve unrelated user changes and existing saves. Never rewrite Git history or use destructive cleanup commands.
- Keep the phone portrait experience, web export, and iOS compatibility working unless the user explicitly narrows the target.
- Treat the user's standing instruction as authorization to publish completed, relevant changes to `https://github.com/976971956/zongheng-sihai.git`. Do not publish unrelated files, credentials, personal data, or changes to any other repository.
- For read-only reviews or explanations with no project modification, do not create a commit or release.

## Implement

1. Trace affected gameplay through scene/UI code, `GameState`, `GameData`, save behavior, and existing regression tests.
2. Make the smallest coherent change that delivers the requested player experience.
3. Add or update a regression test for gameplay, persistence, layout, or release behavior that could break again.
4. Rebuild the runtime font with `tools/build_subset_font.py` after adding or changing player-visible Chinese text.
5. Regenerate derived assets with their checked-in builder when applicable; keep source builders deterministic.

## Validate

Do not publish a failing build.

1. Run `git diff --check` and inspect the final diff for unrelated changes.
2. If assets or imports changed, let the Godot editor complete one headless import scan.
3. Start the project headlessly to catch parse, autoload, and resource errors.
4. Run every `tests/*_test.gd` script. Fix failures rather than weakening valid assertions.
5. Export the Web preset to `build/web/game/index.html` and confirm the package exists.
6. Compare the web PCK size with the previous version. Investigate unexpected growth.
7. For visible, touch, loading, or audio changes, exercise the exported build in a browser and check both the rendered state and browser errors.

Treat the known Godot shutdown leak warnings in short headless tests as non-blocking only when every test exits successfully and no new runtime error appears.

## Publish every completed change

1. Stage only the files belonging to the completed request, including the refreshed `build/web` output.
2. Commit with a concise Chinese message describing the player-facing outcome.
3. Verify `origin` still equals `https://github.com/976971956/zongheng-sihai.git`. Stop if it differs.
4. Push the commit to `origin/main` without asking for a second confirmation.
5. Deploy the checked-in web build with `git subtree push --prefix build/web origin gh-pages`.
6. Verify the remote branch and `https://976971956.github.io/zongheng-sihai/`. Allow for GitHub Pages propagation delay and recheck before reporting failure.
7. Confirm the worktree is clean and local `main` matches `origin/main`.

If network access or platform policy blocks publishing, preserve the local commit and report the exact remaining release step. Do not bypass safeguards or push to an alternate destination.

## Hand off

Lead with what changed for the player. Report the test result, commit identifier, live URL, and any material package-size change. Mention a limitation only when it affects play or release.
