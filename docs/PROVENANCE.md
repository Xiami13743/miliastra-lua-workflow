# 来源与实际贡献

## 上游，不作为本项目原创申报

- 1475505/miliastra-beyond-simulator：https://github.com/1475505/miliastra-beyond-simulator ，GPL-3.0-only。外部Web/MCP、Lua运行与画布/输入模拟能力属于该项目，本包不含它的引擎源码或安装包。
- 本地启动包中的七步工作流文档有与该上游相同的内容。因此本仓库只提供重新编写并署名来源的配套清单，不把七步流程当作原创发明。
- Fengari 0.1.5：https://github.com/fengari-lua/fengari ，MIT。通过npm安装，用于Lua解析与本地规则执行；不是本项目编写的解释器。

## 本提交提供的配套内容

- 从作者工作区启动示例整理出的Lua规则、UI与输入适配代码，剥离固定工程模板ID，改为必须配置的绑定。
- Node.js纯Lua模块打包脚本、语法检查、相对输入路径与SHA256生成物清单。
- 胜负/超时/重开、模块加载、缺失ID、过期生成物及路径约束的回归示例。
- 面向外部工具配合使用的安装、原生接入和证据分层说明。

这些是工作流配套与整合贡献，不代表上游引擎、官方API或第三方知识库的原创权。

## 本地环境中存在但不随本仓库分发

本地更大的启动环境中曾使用miliastra-ugc资料/编解码工具，以及参考Wu-Yijun/Genshin-Impact-Miliastra-Wonderland-Code-Node-Editor-Pack、script-1024/genshin-miliastra-file-format的格式资料。公开可读不自动授予重新分发权；本配套包不复制这些文件、schema、原生样本或编解码实现。

游戏官方文档、资产和示例版权属于各自权利人；本仓库仅提供指向公开来源的引用，不重新许可这些外部内容。
