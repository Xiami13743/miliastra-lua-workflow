# Event submission — v0.1.0 (WIP)

Category: Miliastra Lua Third-Party Tool, Libraries, API or Webpage Tutorials

Name / Title:
Miliastra Lua Workflow Companion — 千星奇域 Lua 创作工作流配套包

Brief Description:
A small, open-source companion package for developing Miliastra Wonderland stages with client-side Lua. It combines modular starter code, configurable UI template bindings, a plain-Lua source packager with syntax validation, SHA256-based build checks and executable regression examples for a complete success/failure/restart loop.

The project credits 1475505/miliastra-beyond-simulator as an external simulator and the source of its staged workflow method. It does not claim the simulator, Lua interpreter or official APIs as original work. Fengari is an MIT-licensed npm dependency; this companion is GPL-3.0-only.

The submitted distribution contains the companion modules, packaging/check scripts and workflow/native-handoff guidance. It does not include the GIL/GIA codecs, native binaries or documentation caches present in the author's broader local environment. Native template IDs must be configured for the user's own project. Six local regression tests pass; native editor 7.1+ and device compatibility remain to be verified. This is a WIP submission.

Project Link:
https://github.com/Xiami13743/miliastra-lua-workflow

Setup Instructions:
Install Node.js 22+, extract the source archive, then run npm ci --ignore-scripts, npm test, npm run build and npm run check. Before native integration, configure the four nativeTemplates IDs in src/config.lua using your own project. Rebuild, then use the official editor's script mounting workflow with dist/main.lua. The simulator is an external dependency installed from its upstream repository, not bundled here. See README.md and docs/NATIVE_HANDOFF.md.

Video Showcase: left blank (no verified walkthrough video provided).
