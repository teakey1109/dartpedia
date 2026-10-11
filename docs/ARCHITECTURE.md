# 架构与功能流程 / Architecture and functional flows

图按当前源码绘制，包含已知失败路径。GitHub 可直接渲染 Mermaid。
Diagrams reflect current source behavior, including known failure paths. GitHub renders Mermaid directly.

## 整体架构 / Overall architecture

```mermaid
flowchart TB
    U[用户 / User] --> E[cli/bin/cli.dart]
    E --> L[日志初始化 / File logger]
    E --> R[command_runner / Parse and dispatch]
    R --> H[HelpCommand]
    R --> S[SearchCommand]
    R --> A[GetArticleCommand]
    S --> WS[wikipedia.search]
    S --> SUM[getArticleSummaryByTitle]
    A --> WA[getArticleByTitle]
    WS --> HTTP[http.Client / HTTPS]
    SUM --> HTTP
    WA --> HTTP
    HTTP <--> W[en.wikipedia.org]
    WS --> M[SearchResults / Summary / Article]
    SUM --> M
    WA --> M
    H --> O[onOutput / console.write]
    S --> O
    A --> O
    O --> T[终端 / Terminal]
    S -. 异常 / Exceptions .-> L
    A -. 异常 / Exceptions .-> L
    L --> F[cli/logs/*.txt]
```

## 命令分发 / Command dispatch

```mermaid
flowchart TD
    IN[命令参数 / argv] --> INIT[初始化日志并注册三个命令 / Initialize and register]
    INIT --> P[CommandRunner.parse]
    P --> EMPTY{参数为空? / Empty?}
    EMPTY -- Yes --> END[无输出返回 / Return silently]
    EMPTY -- No --> VALID{首项为已注册命令? / Known command?}
    VALID -- No --> ERR[ArgumentException]
    VALID -- Yes --> SCAN[解析一个位置参数和选项 / Parse one argument and options]
    SCAN --> BAD{未知选项或参数不合法? / Invalid input?}
    BAD -- Yes --> ERR
    BAD -- No --> RUN[await command.run]
    RUN --> OUT[await onOutput / 逐行输出]
    ERR --> LOG[onError / 记录并打印 Exception]
```

## 搜索与幸运摘要 / Search and lucky summary

```mermaid
flowchart TD
    S[search term] --> V{搜索词非空? / Nonempty?}
    V -- No --> ARG[ArgumentException]
    V -- Yes --> API[OpenSearch API / action=opensearch]
    API --> MODEL[SearchResults.fromJson]
    MODEL --> L{im-feeling-lucky?}
    L -- No --> LIST[输出标题和链接 / Print titles and URLs]
    L -- Yes --> FIRST[取首个结果 / results.first]
    FIRST --> SUMMARY[REST page summary API]
    SUMMARY --> SM[Summary.fromJson]
    SM --> PRINT[输出摘要 / Print summary]
    PRINT --> LIST
    FIRST -. 空结果 / Empty results .-> STATE[StateError / 当前未处理]
    API -. HTTP or JSON error .-> CATCH[记录 HttpException 或 FormatException / Log and return message]
    SUMMARY -. HTTP or JSON error .-> CATCH
```

## 文章读取 / Article retrieval

```mermaid
flowchart TD
    A[article title] --> DEFAULT[缺省标题 cat / Default cat]
    DEFAULT --> API[MediaWiki query / prop=extracts]
    API --> MODEL[Article.listFromJson]
    MODEL --> FIRST[取首篇文章 / articles.first]
    FIRST --> TEXT[按空格切分取前 500 段 / First 500 space-separated tokens]
    TEXT --> OUT[标题与正文输出 / Print title and extract]
    FIRST -. 空列表 / Empty list .-> ERR[StateError / 当前未处理]
    API -. HTTP or JSON error .-> CATCH[记录异常并返回消息 / Log and return message]
```

## 边界 / Boundaries

- CLI 组织用户操作，命令包不直接访问 Wikipedia；API 包不依赖 CLI。CLI coordinates user actions; the runner does not call Wikipedia, and the API package does not depend on CLI.
- 图表示源码调用关系，实际依赖声明存在遗漏。Diagrams show source-level calls; package dependency declarations have omissions.
- 每个 API 函数创建独立 http.Client，并在 finally 中关闭。Each API function creates its own HTTP client and closes it in finally.
- 无数据库、缓存、Web 服务或 UI；数据来自远端，日志存于本地。There is no database, cache, web server, or graphical UI; data is remote and logs are local.
- 随机摘要示例位于 wikipedia/bin/wikipedia.dart，调用 getRandomSummary，与主 CLI 入口独立。The random-summary example is a separate entrypoint in wikipedia/bin/wikipedia.dart.
