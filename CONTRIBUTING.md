# 贡献指南

感谢你对 CodeAlchemist 的兴趣！

## 开发流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 代码规范

- Shell 脚本兼容 Bash 3.2+（macOS 默认版本）
- 保持 SKILL.md 符合 [Agent Skills 规范](https://agentskills.io/specification)
- 更新 `evals/evals.json` 添加新的测试用例
- 禁止在脚本中使用 Bash 4+ 独有特性（如关联数组）

## 测试

```bash
# 验证 SKILL.md 格式
bash .agents/skills/code-alchemist/scripts/validate_skill.sh

# 运行分析脚本
bash .agents/skills/code-alchemist/scripts/distill_author.sh --help

# 检查基本语法错误
bash -n .agents/skills/code-alchemist/scripts/*.sh
```

## 报告问题

提交 Issue 时请包含：
- 使用的操作系统和 Bash 版本 (`bash --version`)
- Git 版本 (`git --version`)
- 复现步骤
- 预期行为 vs 实际行为

## 许可证

贡献的代码将使用 MIT 许可证。
