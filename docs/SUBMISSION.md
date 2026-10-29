# Event submission — v0.1.1

Category: Miliastra Lua Third-Party Tool, Libraries, API or Webpage Tutorials

Name / Title:
Miliastra Lua Workflow Companion — 千星奇域 Lua 创作工作流配套包

Brief Description:
A reusable Lua game-creation workflow and companion toolkit for Miliastra Wonderland. The creator has used the workflow to build stages and has confirmed successful testing in the native game environment. It supports structured iteration from game design and test cases through Lua implementation, preview/testing and native integration.

This entry publishes reusable Lua UI/controller and game-rule modules, a plain-Lua source packager with syntax validation, SHA256-based build checks, executable regression examples and integration guidance. Six local regression tests cover the success/failure/restart loop, module loading and build consistency. Creators connect these components to their own authorized editor projects and configure the UI template bindings and resources for those projects.

The external simulator and staged workflow method are credited to 1475505/miliastra-beyond-simulator; the simulator is installed separately and is not claimed as original work. Fengari is an MIT-licensed dependency, and this companion package is GPL-3.0-only. The public package contains the reusable source components and documentation, not a complete native stage or a bundled simulator. Native validation refers to the creator's tested projects and setup rather than a claim that every device and project configuration has been tested.

Project Link:
https://github.com/Xiami13743/miliastra-lua-workflow

Setup Instructions:
Install Node.js 22+, extract the source archive, then run npm ci --ignore-scripts, npm test, npm run build and npm run check. Before native integration, configure the four nativeTemplates IDs in src/config.lua using your own project. Rebuild, then use the official editor's script mounting workflow with dist/main.lua. The simulator is an external dependency installed from its upstream repository, not bundled here. See README.md and docs/NATIVE_HANDOFF.md.

Video Showcase: left blank (no verified walkthrough video provided).
