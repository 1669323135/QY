# 更新日志

本文件记录汉化补丁模组（ModLocalizePatch）的版本变更历史。

---

## v1.1.0

### 新增模组支持

- **GRAVNet AI and Infrastructure**（GRAVNet AI 与基础设施，Steam ID: 3778736902）
    - 新增 `localizations/GRAVNetAI/zh.json` 翻译数据，涵盖建筑、物品、元素、科技、AI 模型、机器人、蓝图、太空目的地、侧屏 UI
      等全量文本
    - 新增 `MeepNetPatches.cs` 定向（和谐补丁框架）Harmony 补丁，处理约 27 处内联硬编码 UI 文本（侧屏标题、下拉列头、HUD
      训练提示、船员职业、图层悬浮、通知、火箭模块限建提示、轨道无人机建造按钮、PLib 选项标题/描述等）
    - 补丁拦截 `LocText.set_text`（精确匹配整串替换 + 特征碎片替换）及 `TMP_Text.set_text`（侧屏/下拉/按钮等模组自建 UI
      使用基类组件），译文从 `zh.json` 的 `exact` / `replace` 段运行时加载，不在代码内硬编码
    - `config.json`（配置文件）新增 `3778736902 → GRAVNetAI` 及 `germany7496.MEEPNetAI → GRAVNetAI` 映射条目

### 代码变更

- `ModMain.cs`：在 `OnLoad` 与 `OnAllModsLoaded` 中新增 `MeepNetPatches.Apply(harmony)` 调用
- `ModMain.cs`：版本号常量 `MOD_VERSION` 由 `1.0.0` 更新至 `1.1.0`
- `mod_info.yaml`（模组元数据文件）：`version` 由 `1.0.0` 更新至 `1.1.0`

### 文档更新

- `README.md`：支持模组表补充 Critter Overlay、GRAVNet AI and Infrastructure 条目
- `README.md`：定向补丁支持表新增 GRAVNet AI and Infrastructure 条目
- `README.md`：文件结构段修正 `BionicBoostersPlus` → `BionicsExpanded`，新增 `GRAVNetAI/` 目录
