# Notes 代码架构

本项目使用 SwiftUI，采用按功能组织、功能内部轻量分层的单一应用模块。界面以 Figma 为参考，应用文案使用英文。

## 当前目录

下方目录树由 `Scripts/update_architecture.py` 生成；资源目录和 Xcode 工程内部文件折叠展示。本地密钥 `Config/Secrets.xcconfig` 已忽略，不在目录树中列出。

<!-- directory-tree:start -->
```text
Notes/ (repository root)
├── Config/
│   ├── Base.xcconfig
│   └── Secrets.xcconfig.example
├── Docs/
│   └── Architecture.md
├── Notes/
│   ├── App/
│   │   ├── Navigation/
│   │   │   ├── AppRoutes.swift
│   │   │   └── BottomTabBar.swift
│   │   ├── Presentation/
│   │   │   └── ToastPresenter.swift
│   │   ├── Workflows/
│   │   │   └── NoteCaptureCoordinator.swift
│   │   ├── AppDependencies.swift
│   │   ├── NotesApp.swift
│   │   └── RootView.swift
│   ├── DesignSystem/
│   │   ├── Components/
│   │   │   └── SuccessToastView.swift
│   │   └── AppTheme.swift
│   ├── Features/
│   │   ├── Home/
│   │   │   ├── Components/
│   │   │   │   └── ListeningPulse.swift
│   │   │   └── Views/
│   │   │       └── HomeView.swift
│   │   ├── Notes/
│   │   │   ├── Components/
│   │   │   │   └── NoteCard.swift
│   │   │   ├── Models/
│   │   │   │   └── Note.swift
│   │   │   ├── Presentation/
│   │   │   │   └── NoteEditorModel.swift
│   │   │   ├── Stores/
│   │   │   │   └── NotesStore.swift
│   │   │   └── Views/
│   │   │       ├── NoteEditorView.swift
│   │   │       └── NotesListView.swift
│   │   └── Schedule/
│   │       ├── Components/
│   │       │   ├── ScheduleDateHeader.swift
│   │       │   ├── ScheduleDayCard.swift
│   │       │   ├── ScheduleOverviewCard.swift
│   │       │   └── SwipeableScheduleRow.swift
│   │       ├── Layouts/
│   │       │   ├── ScheduleExpandedDayLayout.swift
│   │       │   ├── ScheduleOverviewLayout.swift
│   │       │   └── ScheduleSingleDayLayout.swift
│   │       ├── Models/
│   │       │   ├── ScheduleDayGroup.swift
│   │       │   └── ScheduleItem.swift
│   │       ├── Presentation/
│   │       │   ├── ScheduleEditorModel.swift
│   │       │   └── ScheduleFormatting.swift
│   │       ├── Stores/
│   │       │   └── ScheduleStore.swift
│   │       └── Views/
│   │           ├── ScheduleEditorView.swift
│   │           └── ScheduleView.swift
│   ├── Resources/
│   │   └── Assets.xcassets/
│   └── Services/
│       ├── Persistence/
│       │   └── JSONFileStorage.swift
│       ├── ScheduleExtraction/
│       │   ├── DeepSeek/
│       │   │   ├── DeepSeekConfiguration.swift
│       │   │   ├── DeepSeekModels.swift
│       │   │   ├── DeepSeekScheduleExtractor.swift
│       │   │   └── ScheduleExtractionPrompt.swift
│       │   ├── ExtractedSchedule.swift
│       │   ├── ScheduleExtracting.swift
│       │   └── ScheduleIntentDetector.swift
│       └── Speech/
│           ├── AudioBufferConverter.swift
│           ├── SpeechInputController.swift
│           └── SpeechInputError.swift
├── Notes.xcodeproj/
├── Scripts/
│   └── update_architecture.py
├── Tests/
│   ├── ArchitectureRegression.swift
│   └── run.sh
├── AGENTS.md
└── Info.plist
```
<!-- directory-tree:end -->

## 职责与依赖

| 位置 | 职责 | 放置原则 |
| --- | --- | --- |
| `Notes/App` | 应用入口、依赖组装、导航、全局展示状态、跨功能工作流 | `AppDependencies` 创建长期使用的对象；`RootView` 负责导航、应用生命周期响应和提示展示 |
| `App/Workflows` | 文字或语音保存笔记，再异步提取和更新日程 | 新的笔记输入入口调用 `NoteCaptureCoordinator`；工作流不依赖 SwiftUI，不直接控制页面 |
| `Features/Home` | 输入入口、话筒按钮、监听动画 | 页面调用语音服务，录音和识别实现留在 `Services/Speech` |
| `Features/Notes` | 笔记模型、存储规则、编辑模型、列表和卡片 | Store 负责增删改查和排序；编辑模型负责表单验证与保存；View 绑定状态和触发操作 |
| `Features/Schedule` | 日程模型、存储规则、编辑模型、页面、布局和卡片 | Store 负责分组、排序和来源关联；编辑模型组合日期与时间；布局负责切换动画和手势 |
| `DesignSystem` | 共享主题和跨功能视觉组件 | 业务卡片保留在其功能目录；共享的颜色、圆角及成功提示放在此处 |
| `Services/Persistence` | JSON 编解码、文件路径与原子写入 | 由 Store 调用，可注入临时目录测试；不包含笔记或日程业务规则 |
| `Services/Speech` | 权限、语言模型、音频输入、转写和资源清理 | 控制器管理识别生命周期，音频转换和错误定义各自独立 |
| `Services/ScheduleExtraction` | 本地日期时间筛选、提取接口与结果 | 工作流依赖 `ScheduleExtracting`，具体 DeepSeek 配置、提示词、传输模型和请求实现放在 `DeepSeek/` |
| `Resources` | 图片、图标、颜色等资源 | 保留已有资源名称，以免影响页面引用 |
| `Config` | 构建参数和本地密钥配置入口 | 只跟踪公共配置和密钥示例，真实密钥不提交 |
| `Tests` | 离线业务与服务回归检查 | 使用临时存储、替代提取器和本地 HTTP 响应，不访问真实用户数据或云端 API |

展示层包含 `Views`、`Layouts`、`Components`，以及负责表单状态和展示格式的 `Presentation`。页面不自行发起 AI 请求、读写文件或实现日程判定。简单页面保留局部 SwiftUI 状态，复杂表单通过编辑模型调用业务入口。

业务层由 `Stores` 和 `App/Workflows` 组成。Store 维护单个功能的数据；同时涉及笔记与日程的流程在工作流中编排，避免两个 Store 互相依赖。基础能力由 `Services` 提供，应用启动时组装依赖。

## 核心数据流

1. 文字编辑通过 `NoteEditorModel` 调用 `NoteCaptureCoordinator.saveNote`。
2. `AppDependencies` 将语音转写结果连接至同一个工作流的 `saveVoiceNote`。
3. 工作流先通过 `NotesStore` 保存笔记，再进行本地筛选和异步日程提取。
4. 结果有效且原笔记仍是当前版本时，通过 `ScheduleStore` 创建或更新关联日程。
5. 工作流发布业务事件，应用层将事件转换为成功提示；保存和 AI 联动不依赖页面是否正在显示。

`ScheduleSingleDayLayout` 和 `ScheduleExpandedDayLayout` 共同使用 `ScheduleDayCard`；完整卡与总览卡共同使用 `ScheduleDateHeader` 和 `ScheduleFormatting`，保持日期、Today 和 TBD 的展示一致。

## 保持兼容的约定

- 笔记和日程文件名继续使用 `notes.json`、`schedules.json`，位置仍为 Application Support 下的应用 bundle identifier 目录；数据字段与日期编码方式保持兼容。
- 笔记按更新时间倒序；同日 TBD 日程在具体时间之前；单日滑动始终包含今天，总览只包含有日程的日期。
- 语音只支持英文，结束后自动保存并停留在 Home；笔记删除二次确认，日程左滑删除直接生效。
- 同一笔记通过 `sourceNoteID` 更新关联日程；删除笔记保留既有日程；网络失败不影响笔记保存。
- AI 提示词和参数集中在 `Services/ScheduleExtraction/DeepSeek`，调整规则时同时检查无具体时间、模糊时间和明确时间的结果。

## 检查与维护

在项目根目录运行：

```sh
python3 Scripts/update_architecture.py --check
bash Tests/run.sh
xcodebuild -project Notes.xcodeproj -scheme Notes -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

新增、删除或移动文件后，运行 `python3 Scripts/update_architecture.py` 并将目录树更新包含在同一次改动中。如果职责或数据流改变，手动同步本文对应说明；生成脚本只更新目录树。长期协作要求维护在根目录 `AGENTS.md`，具体结构和职责以本文为准。
