# Godex

<p align="center"><a href="README.md">English</a> | <a href="README.zh-CN.md">简体中文</a></p>

> [!WARNING]
> Godex 目前处在非常非常早期的 `0.0.0` 归档状态。核心 Agent 功能仍然不能作为真实产品使用。

> [!NOTE]
> 后续版本计划在新仓库发布，并使用 Codex runtime / app-server 架构替换当前纯 GDScript 后端。

Godex 是一个实验性的 Godot 4.x 编辑器插件。它主要记录一次把 Codex 风格 AI 工作台嵌入 Godot 编辑器的开发过程，也作为真实项目案例，展示 Godot .NET MCP 可以支撑大型、长期运行的编辑器自动化开发。

> [!TIP]
> Fun fact：为了构建这个半成品中的半成品项目骨架，已经消耗了作者 2000M 以上的 Token。

这个仓库主要用于：

- 记录一个 Godot 原生 AI 助手实验的开发过程；
- 作为 Godot .NET MCP 的项目级压力测试和实例展示；
- 持续发现 Godot .NET MCP 的能力缺口、粗糙边界和后续改进点。

![Godex workbench inside Godot](resources/godex-workbench.png)

![Godex settings inside Godot](resources/godex-settings.png)

## 这是什么

Godex 尝试在 Godot 中实现接近 Codex 的工作流：左侧会话栏、中间 transcript、底部 composer、设置页、审批、MCP 上下文、工具调用折叠行，以及长期开发记录。它还不是可用产品，很多部分仍然是原型。

## 架构

Godex 是一个独立的 Godot 编辑器插件。当前后端完全由 GDScript 自主实现，没有独立 native server，也不是 WebView 应用。

整体结构可以简单理解为：

1. `addons/godex/plugin.gd` 负责 Godot 插件生命周期，并注册顶部的 `Godex` 主屏幕入口。
2. `addons/godex/ui/godex_main.tscn`、`godex_dock_controller.gd` 和 `godex_theme.gd` 使用 Godot 原生 `Control` / `Container` 节点实现 UI。
3. `addons/godex/core/godex_state.gd`、`session_store.gd` 和 `settings_store.gd` 负责会话、消息、model events、工具调用、审批、目标、设置，以及 `user://godex` 下的本地 JSON 持久化。
4. `agent_service.gd`、`openai_request_builder.gd`、`openai_execution_service.gd`、`mcp_client.gd`、`command_capability.gd` 和 `approval_policy.gd` 建模当前 Agent 循环、OpenAI 兼容请求、MCP 工具调用、命令权限和审批规则。

大致数据流是：

`composer 输入 -> state -> agent service -> OpenAI 请求 -> 响应/工具调用 -> MCP 或命令边界 -> 工具结果 -> continuation`

设计目标是复刻 Codex 的核心语义：工具调用应当原地更新，一个 turn 应通过工具结果持续 follow-up，而不是固定小步数脚本；未来的子智能体也应是真正的 child Agent/thread，而不是普通聊天段落。

## 验证

Godex 一直是在一个更大的 Godot 项目中安装、运行，并通过 Godot .NET MCP 反复验证的。这个大项目反馈循环正是本仓库存在的主要原因。

基础本地 smoke 验证：

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate-godex.ps1 -GodotPath "E:/Program Files/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64_console.exe"
```

## 许可证

Godex 使用 PolyForm Noncommercial License 1.0.0 授权。详见 [LICENSE](LICENSE)。
