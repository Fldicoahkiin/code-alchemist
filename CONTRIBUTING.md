# 贡献指南

感谢你对 CodeAlchemist 的兴趣！

## 开发流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 代码规范

- Python 代码遵循 PEP 8
- 使用 `black` 格式化 Python 代码
- 保持 SKILL.md 符合 Agent Skills 规范
- 更新 evals.json 添加新的测试用例

## 测试

```bash
# 验证 SKILL.md 格式
bash scripts/validate_skill.sh

# 运行 Python 脚本测试
python scripts/distill_author.py --help
```

## 报告问题

提交 Issue 时请包含：
- 使用的操作系统和版本
- Python 版本 (`python --version`)
- 复现步骤
- 预期行为 vs 实际行为

## 许可证

贡献的代码将使用 MIT 许可证。
