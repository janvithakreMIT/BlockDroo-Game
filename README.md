# BlockDrop — Free Falling-Block Puzzle (Godot 4)

A small, original, offline falling-block puzzle game starter project. It uses only built-in Godot drawing and GDScript—no paid assets or third-party plugins.

## Features
- 10 × 20 playfield with seven familiar tetromino-style pieces
- Move, rotate, soft drop, and hard drop
- Row clearing, score, line counter, increasing speed
- Pause/restart and saved best score
- Keyboard controls and touch-screen controls
- No ads, login, server, or analytics

## Open and run
1. Install the free Godot 4.x editor from https://godotengine.org/download/
2. Extract this ZIP.
3. In Godot, choose **Import** and select `project.godot`.
4. Open the project and press **F6** (run current scene) or **F5** (run project).

## Publish a playable web version on GitHub Pages
This project includes a GitHub Actions workflow that exports the game for the browser and deploys it to GitHub Pages whenever you push to the `main` branch.

1. Create a GitHub repository and push this project to its `main` branch.
2. In the repository, open **Settings → Pages** and set the build and deployment source to **GitHub Actions**.
3. Open the **Actions** tab and wait for **Deploy Godot game to GitHub Pages** to complete.
4. Your game's URL will appear in **Settings → Pages** and in the deployment job.

The workflow downloads a pinned version of [coi-serviceworker](https://github.com/gzuidhof/coi-serviceworker) (MIT license) because Godot web exports need cross-origin isolation headers that GitHub Pages does not provide. The browser may reload once on the first visit while the service worker is installed.

To deploy from a different default branch, update the branch name in `.github/workflows/deploy-pages.yml`. The generated web export is a build artifact and is not committed to the repository.

## Controls
- Desktop: Left/Right arrows move; Down soft-drops; Up or X rotates; Space hard-drops; P pauses; R restarts.
- Touch: Tap the on-screen buttons. You can also swipe horizontally to move, swipe down to drop one row, and swipe up to rotate.

## Android / Play Store next steps
This is the game source project, not yet a signed Play Store release.
1. Install Godot export templates from **Editor → Manage Export Templates**.
2. Install Android Studio / Android SDK and configure the SDK/JDK paths in Godot Editor Settings. Follow the current Godot Android export guide: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
3. In **Project → Export**, add an Android preset and configure a unique package name (for example `com.yourstudio.blockdrop`—replace it with a package name you control).
4. Create and securely store a release signing keystore. Never share your keystore or passwords.
5. Export an Android App Bundle (`.aab`) for Google Play.
6. Create a Google Play Console developer account, complete identity and app-policy forms, test on real devices, and submit for review. Google Play's account fee and testing requirements may apply.

## Before publishing
- Rename the game if desired and check that the name is available.
- Create your own icon, screenshots, privacy policy, and store listing.
- Verify the current Play policy, target API level, content rating, and testing rules.
- Test on multiple Android devices and fix any bugs.
- This prototype is inspired by the general falling-block puzzle genre; do not use another game's trademark, exact artwork, or store assets.
