# 千星奇域 Lua 创作工作流配套包

Miliastra Lua Workflow Companion · v0.1.1 · GPL-3.0-only · Node.js 22+

这是一套可用于千星奇域项目开发的Lua工作流及通用配套组件。作者已在实际项目中使用这套流程，并确认通过真机测试。公开包提供可复用模块、源码打包、检查和集成说明；使用者将其接入自己的合法原生工程，并配置对应UI绑定。

**上游模拟器属于 [1475505/miliastra-beyond-simulator](https://github.com/1475505/miliastra-beyond-simulator)，不是本项目开发的引擎。** 七步制作流程也参考该项目的工作流；本仓库贡献和边界见 [来源与贡献](docs/PROVENANCE.md)。

## 快速验证（不需要游戏）

安装Node.js 22或以上，在解压后的项目目录执行：

```sh
npm ci --ignore-scripts
npm test
npm run build
npm run check
```

- `npm test`：在Fengari中执行启动、收集成功、超时失败、重开规则，检查打包后的Lua可加载、配置缺项、源码变更及路径约束。
- `npm run build`：语法检查5份Lua输入，将4个模块打成单一 `dist/main.lua`，输出相对路径及SHA256清单。
- `npm run check`：确认生成物与当前模块逐字一致，检测过期或被手改的构建产物。

运行包内示例时，目标为12秒内收集4个目标。它是展示开发流程的最小玩法，实际项目可替换规则和界面。

## 原生接入前必须配置

`src/config.lua` 中的 `nativeTemplates` 四项默认是0。请在**自己的工程**中准备容器、图片、文本和鼠标交互控件模板，并填入它们实际的模板ID。示例不猜测其他工程的GUID；缺少配置时会明确失败。

```lua
nativeTemplates = {container=0, image=0, text=0, cursor=0}
```

配置后重新build，在自己的官方编辑器工程内按官方脚本挂载流程使用生成的单一Lua脚本。根控件/模板、图片资源ID、脚本挂载和生命周期须结合实际工程核对。不要直接使用他人的模板ID。

本配套包**不提供原生GIL/GIA二进制模板或文件编解码功能**，也不自动操作游戏界面。原生接入清单见 [NATIVE_HANDOFF](docs/NATIVE_HANDOFF.md)。

## 与外部模拟器一起使用

使用上游项目公开的Web/MCP安装方式：[上游README](https://github.com/1475505/miliastra-beyond-simulator#readme)。在外部模拟器创建自己的UI工程，准备对应模板与脚本根，加入生成的Lua，再核对点击/触屏/手柄输入。

本仓库不捆绑模拟器或修改其源码。这里的打包、语法和规则测试通过，不表示外部模拟器全部行为或官方原生API已经验收。上游可独立更新，请以其支持矩阵为准。

## 目录

- `src/rules.lua`：纯Lua状态与胜负规则，可独立测试。
- `src/ui.lua`：可配置模板ID的UI构建示例。
- `src/controller.lua`：手柄/光标适配示例；需目标环境验证。
- `src/config.lua`、`src/main.lua`：示例参数和生命周期入口。
- `scripts/build.mjs`：单文件Lua打包、语法及源码一致性检查。
- `tests/`：6项本地回归。
- `docs/WORKFLOW.md`：从设计、用例到原生反馈的工作流。

## 验证状态

- **实际工作流**：作者已确认在其实际千星奇域项目中完成真机测试，可用于关卡制作与迭代。
- **公开配套代码**：6项自动回归通过，覆盖规则执行、模块加载、打包与SHA256一致性。
- **接入其他工程**：使用者配置自己工程的模板/资源绑定，并对目标设备做项目验收。此要求不等于整个工作流仍是未验证原型。

验证范围按作者已测试的项目与环境描述，不笼统保证所有设备、任意版本或每个新关卡。生成物清单分别记录语法检查和作者确认的工作流验证，不把通用库等同于一个完整原生关卡。

## 来源、许可与分发范围

本仓库采用GPL-3.0-only，保留完整LICENSE及第三方说明。主要外部组件：上游模拟器（GPL-3.0-only，单独安装）与Fengari 0.1.5（MIT，通过npm安装）。详见 [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)。

公开范围为通用Lua源码、打包检查脚本、测试和工作流文档。模拟器由上游单独提供，原生工程与资源由使用者自行准备；本仓库不分发原生存档、第三方编解码器、官方文档缓存或美术音乐。

## For reviewers

Category: **Miliastra Lua Third-Party Tool, Libraries, API or Webpage Tutorials**.

This entry publishes reusable Lua workflow components and integration guidance. The creator has used the workflow to build stages and confirmed successful native testing in their actual setup. The public components include modular Lua code, source bundling, syntax checks, fingerprints and regression examples. Users connect them to their own authorized editor projects and configure project-specific UI/resource bindings. The external simulator and workflow method are credited to their upstream author. Six local regression tests pass; native validation applies to the creator's tested projects rather than a blanket all-device certification. See [submission description](docs/SUBMISSION.md).
