# GRAVNet AI（GRAVNetAI）汉化移除清单

> **背景**：`GRAVNet AI and Infrastructure`（模组作者 germany7496）的作者已将「官方翻译」列入下一步开发计划。
> 待其原生翻译发布后，本汉化补丁 `ModLocalizePatch`
> （本地化补丁）中针对该模组的全部定向汉化内容即可移除，避免与作者官方翻译重复 / 冲突。
> 本文档汇总 **所有与 GRAVNetAI 相关的代码、翻译库、配置、文档与脚本**，供后续按图索骥地清理。
>
> **模组标识**：
> - 翻译文件夹名：`GRAVNetAI`（依 `mod.yaml` 的 `title`（模组标题）命名）
> - `staticID`（静态标识符）：`germany7496.MEEPNetAI`
> - Steam（游戏平台）创意工坊 ID（模组文件夹名）：`3778736902`
> - 主体 DLL（动态链接库）：`MeepNetAI.dll`

---

## 一、待移除清单（按类别）

### 1. 源代码（C#）

| # | 文件 / 位置                                                | 操作                          | 说明                                                                                                                                                                     |
|---|------------------------------------------------------------|-------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 | `ModLocalizePatch/ModLocalizePatch/MeepNetPatches.cs`      | **整个文件删除**（共 188 行） | GRAVNetAI 专用定向补丁。含 `MeepNetPatches`（补丁类）与 `InlinePatchTextData`（内联文本数据类）。已确认 `InlinePatchTextData` 仅在本文件内定义与使用，删除后无残留引用。 |
| 2 | `ModLocalizePatch/ModLocalizePatch/ModMain.cs` 第 37–38 行 | **删除**                      | 注释「针对 MeepNetAI（GRAVNet AI）内联硬编码 UI 文本注册定向汉化补丁」+ 调用 `MeepNetPatches.Apply(harmony);`（位于 `OnLoad`（加载时回调）内）。                         |
| 3 | `ModLocalizePatch/ModLocalizePatch/ModMain.cs` 第 62 行    | **删除**                      | 调用 `MeepNetPatches.Apply(harmony);`（位于 `OnAllModsLoaded`（全部模组加载后回调）内）。                                                                                |

> **注**：`ModLocalizePatch.csproj`（项目文件）为 SDK 风格，自动包含目录下全部 `.cs` 文件，删除 `MeepNetPatches.cs` 后
> **无需**手动修改 `.csproj`。
> **注**：`Patches.cs`（通用 `Strings.Get`（获取字符串方法）补丁）与 `LocalizationManager.cs`（本地化管理类）为 **通用逻辑**
> ，不含任何 GRAVNetAI 硬编码， **无需改动**。GRAVNetAI 的主体键翻译是通过通用的「读取 `localizations/<文件夹>/zh.json` 的
> `translations`（翻译）段」机制生效的，删除该 JSON 即自动失效。

### 2. 翻译库文件

| # | 文件 / 目录                                             | 操作                          | 说明                                                                                               |
|---|---------------------------------------------------------|-------------------------------|----------------------------------------------------------------------------------------------------|
| 4 | `ModLocalizePatch/localizations/GRAVNetAI/zh.json`      | **整个文件删除**（共 380 行） | 含 `translations`（266 条 STRINGS 键）+ `exact`（45 条整串精确替换）+ `replace`（40 条碎片替换）。 |
| 5 | `ModLocalizePatch/localizations/GRAVNetAI/`（整个目录） | **整个目录删除**              | 删除 `zh.json` 后该目录为空，一并移除。                                                            |

### 3. 配置文件

| # | 文件 / 位置                                           | 操作     | 说明                                                                    |
|---|-------------------------------------------------------|----------|-------------------------------------------------------------------------|
| 6 | `ModLocalizePatch/localizations/config.json` 第 17 行 | **删除** | `"3778736902": "GRAVNetAI",`（Steam ID → 翻译文件夹名映射）。           |
| 7 | `ModLocalizePatch/localizations/config.json` 第 18 行 | **删除** | `"germany7496.MEEPNetAI": "GRAVNetAI"`（staticID → 翻译文件夹名映射）。 |

> **注（JSON 语法）**：删除第 17–18 行后，原第 16 行 `"BionicBoostersPlus": "BionicsExpanded",` 将成为 `steamIdMapping`
> （映射表）的 **最后一项**，必须去掉其行尾逗号，否则 JSON（数据交换格式）非法。

### 4. 文档

| #  | 文件 / 位置                                            | 操作         | 说明                                                                                                                                                                    |
|----|--------------------------------------------------------|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 8  | `汉化文本校对文档.md` 第 263–712 行                    | **删除整段** | 第六节「GRAVNet AI and Infrastructure（GRAVNetAI）」全部内容，含子节 6.1–6.13 及节末分隔线 `---`。删除后第五节（Bionics Expanded，止于第 261 行 `---`）直接衔接第七节。 |
| 9  | `汉化文本校对文档.md` 第 721 行                        | **删除**     | 第七节「统计概览」表格中的 `GRAVNetAI（GRAVNet AI）｜267｜…` 行。                                                                                                       |
| 10 | `汉化文本校对文档.md` 第 722 行                        | **修改**     | 「合计」由 `343` 改为 `76`（= WallPumps 20 + 8 个 Custom Geysers 16 + BionicBoostersPlus 40）。                                                                         |
| 11 | `问题追踪技术文档.md` 第 43–58 行（1.4 节 A3）         | **删除**     | 「MeepNetAI（GRAVNet AI）深度插值内联文本仍保留英文」整条。                                                                                                             |
| 12 | `问题追踪技术文档.md` 第 60–66 行（1.5 节 A4）         | **删除**     | 「MeepNetAI 5 条 DLC（可下载内容）条件文本采用固定译法」整条。                                                                                                          |
| 13 | `问题追踪技术文档.md` 第 108 行（B18）                 | **删除**     | 2.4 节表格中「MeepNetAI 约 27 处内联硬编码 UI 文本…」行。                                                                                                               |
| 14 | `问题追踪技术文档.md` 第 109 行（B19）                 | **删除**     | 2.4 节表格中「AI 模型侧屏…基类 TMP_Text 钩子」行。                                                                                                                      |
| 15 | `问题追踪技术文档.md` 第 137–140 行（第三节 统计概览） | **修改**     | 🟡 保留：`5 → 3`（移除 A3、A4 及其文字描述）；🟢 已完成：`27 → 25`，说明由「B1 ~ B19」改为「B1 ~ B17」；合计：`32 → 28`。                                               |

> **注**：`ModLocalizePatch简介.md`（创意工坊玩家简介）的「支持模组」表 **未列入** GRAVNetAI，`mod.yaml`（模组元数据）描述为通用文案，二者
> **无需改动**。

### 5. 辅助脚本（GRAVNetAI / MeepNetAI 专用，位于 `scripts/`）

| #  | 脚本文件                                   | 用途                                                                               |
|----|--------------------------------------------|------------------------------------------------------------------------------------|
| 16 | `scripts/scan_meepnet_uistrings.ps1`       | 扫描反编译的 MeepNetAI 源码中 `MeepNetStrings` 表外的 UI 字符串。                  |
| 17 | `scripts/scan_meepnet_inline_literals.ps1` | 扫描内联裸字面量文本。                                                             |
| 18 | `scripts/scan_meepnet_inline2.ps1`         | 内联文本二次扫描。                                                                 |
| 19 | `scripts/verify_meepnet_coverage.ps1`      | 校验译文对 MeepNetAI 字符串的覆盖率。                                              |
| 20 | `scripts/check_gravnet_log.ps1`            | 检查 `Player.log`（游戏日志）中 GRAVNetAI / MeepNetAI / LocText 补丁的运行时证据。 |
| 21 | `scripts/verify_gravnet_result.ps1`        | 验证 GRAVNetAI 汉化运行结果。                                                      |

> 以上 6 个脚本均为 GRAVNetAI 汉化专项调试工具，移除汉化后可一并删除（不影响 `build.ps1`（编译脚本）/ `deploy_mod.ps1`
> （部署脚本）等通用脚本）。

---

## 二、⚠ 不应删除的部分（避免误删）

| 路径                     | 说明                                                                                                                                                                                             |
|--------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `mods/3778736902/`       | 这是 **GRAVNet AI 模组本体**（Steam 创意工坊缓存，含 `MeepNetAI.dll`、`audio/`、`anim/`、`mod.yaml` 等）。属于游戏所装模组，**不是汉化补丁的组成部分**。除非要卸载该模组本身，否则**不得删除**。 |
| `mods/ModLocalizePatch/` | 早期部署副本。经全量检索，**不含任何 GRAVNetAI / MeepNet 引用**（无 `MeepNetPatches.cs`，`localizations/` 下无 `GRAVNetAI` 目录），**无需清理**。                                                |

---

## 三、删除后必做流程

1. **重新编译**：因涉及代码变更（删除 `MeepNetPatches.cs`、修改 `ModMain.cs`），须执行 `scripts/build.ps1`。
    - ⚠ 编译 / 部署前 **确认缺氧游戏已完全关闭**，否则 `ModLocalizePatch.dll` 被进程锁定会导致覆盖失败（见《问题追踪技术文档.md》1.3）。
2. **重新部署**：编译成功后执行 `scripts/deploy_mod.ps1`。
    - 部署目标：`%USERPROFILE%\Documents\Klei\OxygenNotIncluded\mods\Local\ModLocalizePatch\`。
    - 该脚本用 `robocopy /MIR`（镜像同步）复制 `localizations/`，会 **自动清除**游戏目录中残留的 `GRAVNetAI` 翻译文件夹；新编译的
      DLL（不含 MeepNetPatches）会覆盖旧版本。

---

## 四、验证清单（删除并重新部署后）

- [ ] `MeepNetPatches.cs` 已不存在；`ModMain.cs` 中无 `MeepNetPatches` 字样。
- [ ] `localizations/GRAVNetAI/` 目录已不存在；`config.json` 中无 `GRAVNetAI` / `3778736902` / `germany7496.MEEPNetAI` 且
  JSON 合法。
- [ ] `build.ps1` 编译通过（无 `MeepNetPatches` 未定义引用报错）。
- [ ] 启动游戏后 `Player.log` 中不再出现「已为 … 注册 MeepNetAI … 汉化拦截」等日志。
- [ ] 其余模组（WallPumps、Custom Geysers、CritterOverlay、BionicsExpanded）汉化仍正常生效。
- [ ] 两份文档（`汉化文本校对文档.md`、`问题追踪技术文档.md`）的统计数字已同步更新且无 GRAVNetAI 残留条目。

---

*本清单由 GRAVNetAI 汉化相关代码 / 配置 / 文档 / 脚本的全量检索整理生成，用于作者官方翻译发布后的移除作业。*
