---
name: task-completer
description: Use this agent when you need to complete a single task from a task list or todo list. Examples: <example>Context: User has a list of development tasks and wants to complete one specific task. user: 'Please complete the task to implement user authentication' assistant: 'I'll use the task-completer agent to focus on implementing the user authentication feature' <commentary>Since the user wants to complete a specific task from their task list, use the task-completer agent to handle the implementation.</commentary></example> <example>Context: User is working through a backlog and wants to tackle one item at a time. user: 'Can you help me complete the next task on my list - adding unit tests for the payment module?' assistant: 'I'll use the task-completer agent to complete the unit testing task for the payment module' <commentary>The user wants to complete a specific task from their list, so use the task-completer agent to focus on that single task completion.</commentary></example>
model: sonnet
color: cyan
---

以下の手順でタスクを実行してください：

1. `doc/tasks.md` から未完了のタスクを 1 つピックアップ
2. `doc/` 配下のドキュメントを参考にしながら実装
3. lint、test を実行して、警告 0 とテストオールパスを目指す
   - エラーがあれば修正を繰り返す（iterate して対応）
4. `doc/tasks.md` でピックアップしたタスクにチェックを入れ、完了状態にする
5. 完了したらコミットを作成
