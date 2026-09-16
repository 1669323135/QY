# 汉化补丁

为未汉化的 Steam 创意工坊模组自动注入简体中文翻译。

## 功能

- **自动检测**：游戏启动时自动扫描已启用的模组，与汉化库中的翻译数据进行匹配
- **运行时注入**：通过 Harmony 补丁实时注入翻译，无需修改目标模组文件
- **白名单机制**：已处理的模组自动记录，避免重复检测
- **静默运行**：未匹配到目标模组时完全静默，不影响游戏体验

### 工作原理

本模组 **不复制文件到目标模组目录**（目标模组的 `translations/` 目录不支持 `.json` 格式）。
而是通过 Harmony 补丁在游戏运行时直接从本模组的 `localizations/` 目录加载翻译数据，
并注入到游戏的字符串系统中（`Localization.OverloadStrings` / `Strings.Add`）。
这与 ModI18n 等成熟汉化模组采用相同的运行时注入方案。

## 兼容性

### 游戏版本

| 项目                  | 值                          |
|-----------------------|-----------------------------|
| 游戏版本号            | U59-744825-SCRPAN (release) |
| Unity 引擎            | 6000.3.5f2                  |
| 模组 API 版本         | 2                           |
| 目标框架              | .NET Framework 4.8 (net48)  |
| supportedContent      | ALL（支持全部内容）         |
| minimumSupportedBuild | 0（无最低构建号限制）       |

### DLC 支持

游戏当前加载的所有 DLC 均已确认兼容：

| DLC ID       | 状态      |
|--------------|-----------|
| COSMETIC1_ID | ✔ 已加载 |
| DLC2_ID      | ✔ 已加载 |
| DLC3_ID      | ✔ 已加载 |
| DLC4_ID      | ✔ 已加载 |
| DLC5_ID      | ✔ 已加载 |

本模组 `supportedContent: ALL`，兼容本体游戏及全部 DLC 内容。目标模组均为 `supportedContent: ALL`，不依赖特定 DLC 独占内容。

### 关键依赖

| 依赖库                       | 版本           | 用途                                       |
|------------------------------|----------------|--------------------------------------------|
| 0Harmony.dll（和谐补丁框架） | 2.4.2.0        | 运行时补丁注入                             |
| Newtonsoft.Json.dll          | 7.0.1.18622    | JSON 配置文件解析                          |
| Assembly-CSharp.dll          | 游戏内置       | 游戏核心程序集（Strings、Localization 等） |
| UnityEngine.dll + CoreModule | Unity 6000.3.5 | Unity 引擎基础模块                         |

以上依赖均为游戏自带 DLL，无需用户额外安装。

### 目标模组兼容性

| Steam ID   | 模组名称                               | supportedContent | minimumSupportedBuild |
|------------|----------------------------------------|------------------|-----------------------|
| 3113986230 | Wall Pumps                             | ALL              | 0                     |
| 3740127708 | Custom Geysers - Ethanol Geyser        | ALL              | 469112                |
| 3591826138 | Custom Geysers - Leaky Caramel Fissure | ALL              | 469112                |
| 3508859197 | Custom Geysers - Nickel Volcano        | ALL              | 469112                |
| 3740131305 | Custom Geysers - Salt Volcano          | ALL              | 469112                |
| 3508873047 | Custom Geysers - Iridium Volcano       | ALL              | 469112                |
| 3508865977 | Custom Geysers - Lead Volcano          | ALL              | 469112                |
| 3508870243 | Custom Geysers - Liquid Mercury Geyser | ALL              | 469112                |
| 3743015529 | Custom Geysers - Zinc Volcano          | ALL              | 469112                |
| 3770134628 | Critter Overlay                        | ALL              | 0                     |
| 3798248283 | Bionics Expanded                       | ALL              | 737790                |

所有目标模组均要求 `supportedContent: ALL`，且最低构建号要求均低于当前游戏版本（744825），兼容性无冲突。

## 支持模组

| Steam ID   | 模组名称                               | staticID              |
|------------|----------------------------------------|-----------------------|
| 3113986230 | Wall Pumps                             | WallPumps             |
| 3740127708 | Custom Geysers - Ethanol Geyser        | geysersEthanolGeyser  |
| 3591826138 | Custom Geysers - Leaky Caramel Fissure | geysersLeakyCaramel   |
| 3508859197 | Custom Geysers - Nickel Volcano        | geysersNickelVolcano  |
| 3740131305 | Custom Geysers - Salt Volcano          | geysersSaltVolcano    |
| 3508873047 | Custom Geysers - Iridium Volcano       | geysersIridiumVolcano |
| 3508865977 | Custom Geysers - Lead Volcano          | geysersLeadVolcano    |
| 3508870243 | Custom Geysers - Liquid Mercury Geyser | geysersMercuryGeyser  |
| 3743015529 | Custom Geysers - Zinc Volcano          | geysersZincVolcano    |
| 3798248283 | Bionics Expanded                       | BionicBoostersPlus    |

### 定向补丁支持（非 JSON 键注入）

部分模组的文本不走标准 `STRINGS` 键查询，无法用上述 JSON 库覆盖，改用 **定向 Harmony 补丁**汉化：

| Steam ID   | 模组名称        | 汉化方式                                                                                                                                                                                          |
|------------|-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 3770134628 | Critter Overlay | 译文存于 `localizations/guybrush.CritterOverlay/zh.json`（exact 整串 / replace 碎片）；由补丁 `OverlayFilters.Define` + 拦截 `LocText.set_text` 应用（因标签为 const 内联，只能在写入 UI 时替换） |

## 安装方法

> **重要**：必须将整个 `ModLocalizePatch` 文件夹（包含 `localizations/` 子目录）复制到游戏模组目录，仅复制 DLL 文件无效。

1. 构建项目（DLL 会自动复制到 `ModLocalizePatch/` 根目录）
2. 将整个 `ModLocalizePatch/` 文件夹复制到以下任一位置：
    - **本地模组**：`%USERPROFILE%\Documents\Klei\OxygenNotIncluded\mods\Local\ModLocalizePatch\`
    - **Steam 创意工坊**：`Steam\steamapps\workshop\content\457140\ModLocalizePatch\`
3. 确保部署后的目录结构如下：
   ```
   ModLocalizePatch/
   ├── ModLocalizePatch.dll    ← 必须存在
   ├── mod.yaml
   ├── mod_info.yaml
   ├── preview.png
   └── localizations/          ← 必须存在，包含所有翻译数据
       ├── config.json
       └── ...
   ```
4. 在游戏中启用模组，重启游戏生效

## 如何添加新模组的汉化

1. 在 `localizations/` 目录下创建以目标模组 `staticID` 命名的文件夹
2. 在该文件夹内放置 JSON 格式的翻译文件
3. 若模组的 Steam 创意工坊 ID 与 `staticID` 不同，在 `localizations/config.json` 的 `steamIdMapping` 中添加映射

### 翻译文件格式

```json
{
  "modId": "目标模组staticID",
  "modName": "目标模组显示名称",
  "translations": {
    "STRINGS.XXX.KEY": "中文翻译"
  }
}
```

## 文件结构

```
ModLocalizePatch/
├── ModLocalizePatch.dll
├── mod.yaml
├── mod_info.yaml
├── preview.png
├── localizations/
│   ├── config.json
│   ├── WallPumps/
│   │   └── zh.json
│   ├── geysersEthanolGeyser/
│   │   └── zh.json
│   ├── geysersLeakyCaramel/
│   │   └── zh.json
│   ├── geysersNickelVolcano/
│   │   └── zh.json
│   ├── geysersSaltVolcano/
│   │   └── zh.json
│   ├── geysersIridiumVolcano/
│   │   └── zh.json
│   ├── geysersLeadVolcano/
│   │   └── zh.json
│   ├── geysersMercuryGeyser/
│   │   └── zh.json
│   ├── geysersZincVolcano/
│   │   └── zh.json
│   ├── guybrush.CritterOverlay/
│   │   └── zh.json
│   └── BionicBoostersPlus/
│       └── zh.json
└── whitelist.txt
```
