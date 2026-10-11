# 项目分析 / Project analysis

## 项目定位 / Purpose

这是一个小型 Dart Workspace，展示命令抽象、异步 HTTP 请求和 JSON 模型转换。没有 Flutter 依赖或移动端目录。
This small Dart workspace demonstrates command abstraction, asynchronous HTTP, and JSON model conversion. It has no Flutter dependency or mobile application targets.

## 模块职责 / Modules

| 模块 / Module | 关键源码 / Source | 职责 / Responsibility |
| --- | --- | --- |
| CLI | `cli/bin/cli.dart` | 初始化日志、注册三个命令、配置输出和异常回调 / Initialize logging, register commands, configure callbacks |
| 搜索 / Search | `cli/lib/src/commands/search.dart` | 搜索、可选首条摘要、结果格式化 / Search, optional first summary, formatting |
| 文章 / Article | `cli/lib/src/commands/get_article.dart` | 默认 cat、首条文章、500 片段截取 / Default cat, first article, 500-token truncation |
| 解析器 / Parser | `command_runner/lib/src/command_runner_base.dart` | 一个命令、最多一个位置参数、flag 和带值选项 / One command, up to one positional argument, flags and valued options |
| 帮助 / Help | `command_runner/lib/src/help_command.dart` | 普通、详细与单命令帮助 / Basic, verbose, command-specific help |
| API | `wikipedia/lib/src/api/` | OpenSearch、正文、指定与随机摘要 / OpenSearch, extracts, named and random summaries |
| 模型 / Models | `wikipedia/lib/src/model/` | Article、SearchResults、Summary、TitlesSet |

## 请求与存储 / Requests and storage

| 功能 / Feature | 端点 / Endpoint |
| --- | --- |
| 搜索 / Search | `https://en.wikipedia.org/w/api.php?action=opensearch&format=json&search=...` |
| 正文 / Extract | `https://en.wikipedia.org/w/api.php?action=query&format=json&titles=...&prop=extracts&explaintext=` |
| 摘要 / Summary | `https://en.wikipedia.org/api/rest_v1/page/summary/{title}` |
| 随机摘要 / Random summary | `https://en.wikipedia.org/api/rest_v1/page/random/summary` |

以上为源码配置，未对远端接口可用性进行实时验证。请求没有显式超时或重试。正常结果逐行输出，默认每行延迟 50ms。日志根据 Platform.script 推导目录，源码入口通常写入 cli/logs/YYYY_M_D_errors.txt；编译后路径可能不同。
These are source-configured endpoints, not live availability checks. Requests have no explicit timeout or retry. Normal output is line-based with a default 50ms delay per line. Logging derives its directory from Platform.script; the source entrypoint normally writes cli/logs/YYYY_M_D_errors.txt, while compiled paths may differ.

## 已知问题 / Known issues

1. **依赖声明 / Dependencies**：CLI 导入 wikipedia 但未声明依赖；wikipedia 仅在 dev_dependencies 声明 http，却在 lib 使用。Workspace 当前可解析这些包，但应为复用与发布补齐正式依赖。CLI imports wikipedia without declaring it; wikipedia uses http in library code but declares it only as a development dependency. The workspace currently resolves them, but reusable packages need direct production dependencies.
2. **必填元数据 / Required metadata**：基类为 requiresArguments，SearchCommand 和示例覆写 requiresArgument。搜索内部仍校验参数，但 help 会显示不正确的必填信息。The base getter is requiresArguments while search and the example declare requiresArgument. Search validates its input manually, but help reports incorrect metadata.
3. **空结果 / Empty results**：幸运搜索和文章命令直接使用 first；无结果可抛出 StateError。CommandRunner 只捕获 Exception，不能捕获 Error，因此入口的 Error 回调分支并不会处理这些错误。Lucky search and article retrieval use first without checking emptiness. StateError bypasses the runner's Exception-only catch, so the entrypoint's Error callback branch does not handle it.
4. **退出状态与异步 / Exit status and async**：入口未 await app.run；Runner 未 await onError；已处理异常只打印，没有设置非零 exitCode。The entrypoint does not await app.run, the runner does not await onError, and handled failures do not set a nonzero exitCode.
5. **解析健壮性 / Model robustness**：SearchResults 假设标题与 URL 数组长度一致；Summary 要求若干特定字段；缺失文章可能被 Article 模型跳过并得到空列表。SearchResults assumes aligned title and URL arrays; Summary requires specific fields; missing articles can produce an empty Article list.
6. **测试缺口 / Test gaps**：CLI 测试为空，命令包只有 Awesome.isAwesome 占位测试；缺少解析边界、HTTP 异常、空结果和端到端测试。CLI tests are empty and runner tests only assert a placeholder Awesome.isAwesome property. Parsing boundaries, HTTP errors, empty results, and end-to-end behavior are untested.
7. **版本 / Versioning**：包版本为 1.0.0，入口有未使用的 0.0.1 常量，无 --version 命令。Packages declare 1.0.0 while the entrypoint has an unused 0.0.1 constant; no --version command exists.

## 实测 / Verification (2026-10-11)

| 检查 / Check | 结果 / Result |
| --- | --- |
| `dart analyze` | 退出码 2；3 warning、7 info / Exit 2; 3 warnings, 7 infos |
| wikipedia: `dart test` | 3 个 JSON 模型测试通过 / 3 fixture model tests passed |
| command_runner: `dart test` | 1 个占位测试通过 / 1 placeholder test passed |
| `dart run cli/bin/cli.dart help` | 退出码 0，列出三个命令 / Exit 0, three commands listed |
| 实时搜索与文章 / Live search and article | 未运行 / Not run |

静态分析的 7 个 info 为 5 个依赖声明提示及 2 个重复导入提示；3 个 warning 为 2 个无对应基类的 override 及 1 个未使用导入。本次仅新增或完善文档和交付工具，没有修改业务源码。
The seven informational findings cover five dependency declarations and two unnecessary imports; the three warnings cover two non-overriding getters and one unused import. This delivery updates documentation and packaging only, leaving application source unchanged.

## 建议顺序 / Suggested next steps

先修正依赖和 getter 命名，再处理空结果和非零退出码，随后添加 HTTP 客户端注入、超时、错误测试和 CI。选择许可证后再宣称开源授权。
First fix dependency declarations and getter naming, then empty-result handling and exit codes. Follow with HTTP client injection, timeouts, error tests, and CI. Choose a license before claiming an open-source grant.
