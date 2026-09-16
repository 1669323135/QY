using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;

namespace ModLocalizePatch
{
    /// <summary>
    /// 汉化补丁管理器：负责检测已启用的目标模组、复制汉化文件、维护白名单。
    /// </summary>
    public class LocalizationManager
    {
        private readonly string _modDir;
        private readonly string _localizationsDir;
        private readonly string _whitelistPath;
        private readonly HashSet<string> _whitelist = new HashSet<string>();

        /// <summary>常见 Steam 创意工坊模组目录（缺氧 Workshop ID = 457140）</summary>
        internal static readonly string[] SteamWorkshopPaths = {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Steam", "steamapps", "workshop", "content", "457140"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "Steam", "steamapps", "workshop", "content", "457140"),
            @"C:\Program Files (x86)\Steam\steamapps\workshop\content\457140",
            @"C:\Program Files\Steam\steamapps\workshop\content\457140",
            @"D:\Steam\steamapps\workshop\content\457140",
            @"E:\Steam\steamapps\workshop\content\457140"
        };

        private LocalizeConfig _config;

        /// <summary>缓存 staticID → 模组文件夹名 的映射，避免重复扫描</summary>
        private readonly Dictionary<string, string> _modFolderCache = new Dictionary<string, string>();
        private bool _folderCacheBuilt;

        public LocalizationManager(string modDir)
        {
            _modDir = modDir;
            _localizationsDir = Path.Combine(modDir, "localizations");
            _whitelistPath = Path.Combine(modDir, "whitelist.txt");
        }

        // ──────────────────────────── 配置管理 ────────────────────────────

        /// <summary>加载配置文件 localizations/config.json</summary>
        public void LoadConfig()
        {
            string configPath = Path.Combine(_localizationsDir, "config.json");
            if (File.Exists(configPath))
            {
                try
                {
                    string json = File.ReadAllText(configPath);
                    _config = JsonConvert.DeserializeObject<LocalizeConfig>(json) ?? new LocalizeConfig();
                    Debug.Log($"[{ModMain.MOD_ID}] 配置加载成功，映射条目数: {_config.SteamIdMapping?.Count ?? 0}");
                    return;
                }
                catch (Exception e)
                {
                    Debug.LogWarning($"[{ModMain.MOD_ID}] 配置文件读取失败: {e.Message}");
                }
            }

            _config = new LocalizeConfig();
            // 生成默认配置文件方便用户编辑
            try
            {
                Directory.CreateDirectory(_localizationsDir);
                File.WriteAllText(configPath, JsonConvert.SerializeObject(_config, Formatting.Indented));
                Debug.Log($"[{ModMain.MOD_ID}] 已生成默认配置文件: {configPath}");
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 生成默认配置文件失败: {e.Message}");
            }
        }

        // ──────────────────────────── 白名单管理 ────────────────────────────

        /// <summary>从 whitelist.txt 加载已处理模组 ID（禁用模组后此文件会被删除，等效于清空白名单）</summary>
        public void LoadWhitelist()
        {
            _whitelist.Clear();
            if (File.Exists(_whitelistPath))
            {
                foreach (string line in File.ReadAllLines(_whitelistPath))
                {
                    string trimmed = line.Trim();
                    if (!string.IsNullOrEmpty(trimmed))
                        _whitelist.Add(trimmed);
                }
                Debug.Log($"[{ModMain.MOD_ID}] 白名单已加载，共 {_whitelist.Count} 条记录。");
            }
            else
            {
                Debug.Log($"[{ModMain.MOD_ID}] 白名单文件不存在，视为空（首次启动或禁用后重新启用）。");
            }
        }

        private void SaveWhitelist()
        {
            try
            {
                File.WriteAllLines(_whitelistPath, _whitelist);
                Debug.Log($"[{ModMain.MOD_ID}] 白名单已保存，共 {_whitelist.Count} 条记录。");
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 白名单保存失败: {e.Message}");
            }
        }

        // ──────────────────────────── 核心检测与复制 ────────────────────────────

        /// <summary>
        /// 检测已启用的目标模组，记录到白名单。
        /// 注意：汉化通过 Harmony 运行时注入实现，不需要复制文件到目标模组目录。
        /// </summary>
        public void DetectAndCopy(IReadOnlyList<KMod.Mod> mods)
        {
            Debug.Log($"[{ModMain.MOD_ID}] ========== 开始检测模组 ==========");
            Debug.Log($"[{ModMain.MOD_ID}] 模组目录: {_modDir}");
            Debug.Log($"[{ModMain.MOD_ID}] 汉化库目录: {_localizationsDir} (存在: {Directory.Exists(_localizationsDir)})");

            if (!Directory.Exists(_localizationsDir))
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 汉化库目录不存在！");
                return;
            }

            // 获取汉化库中所有可用的模组 ID
            string[] availableIds = Directory.GetDirectories(_localizationsDir)
                .Select(d => Path.GetFileName(d))
                .Where(n => !n.Equals("config.json", StringComparison.OrdinalIgnoreCase))
                .ToArray();

            Debug.Log($"[{ModMain.MOD_ID}] 汉化库包含: [{string.Join(", ", availableIds)}]");

            if (availableIds.Length == 0)
            {
                Debug.Log($"[{ModMain.MOD_ID}] 汉化库为空。");
                return;
            }

            var steamMapping = _config?.SteamIdMapping ?? new Dictionary<string, string>();
            int matchedCount = 0;

            Debug.Log($"[{ModMain.MOD_ID}] 共 {mods.Count} 个已加载模组，开始匹配...");

            foreach (KMod.Mod mod in mods)
            {
                if (mod.staticID == ModMain.MOD_ID) continue;
                if (!mod.IsActive())
                {
                    Debug.Log($"[{ModMain.MOD_ID}]   x '{mod.title}' - 未激活");
                    continue;
                }
                if (mod.status != KMod.Mod.Status.Installed)
                {
                    Debug.Log($"[{ModMain.MOD_ID}]   x '{mod.title}' - 状态={mod.status}");
                    continue;
                }

                Debug.Log($"[{ModMain.MOD_ID}]   -> '{mod.title}' (staticID={mod.staticID})");

                string matchId = ResolveModMatchId(mod, steamMapping);
                if (matchId == null)
                {
                    Debug.Log($"[{ModMain.MOD_ID}]     x 未匹配");
                    continue;
                }

                Debug.Log($"[{ModMain.MOD_ID}]     + 匹配: '{matchId}'");

                // 白名单中已记录则静默跳过
                if (_whitelist.Contains(matchId))
                {
                    Debug.Log($"[{ModMain.MOD_ID}]      已在白名单中");
                    continue;
                }

                // 添加到白名单（运行时注入会自动处理翻译）
                _whitelist.Add(matchId);
                matchedCount++;
                Debug.Log($"[{ModMain.MOD_ID}]     * 已记录到白名单");
            }

            Debug.Log($"[{ModMain.MOD_ID}] ========== 检测完成 ==========");
            if (matchedCount > 0)
            {
                SaveWhitelist();
                Debug.Log($"[{ModMain.MOD_ID}] * 本次匹配 {matchedCount} 个模组，翻译已通过运行时注入生效。");
            }
            else
            {
                Debug.Log($"[{ModMain.MOD_ID}]  本次无新匹配的模组。");
            }
        }

        // ──────────────────────────── 辅助方法 ────────────────────────────

        /// <summary>
        /// 解析模组的匹配 ID：优先使用 Steam 创意工坊 ID（文件夹名），
        /// 若 config.json 中有映射则使用映射后的文件夹名，
        /// 最终回退到 staticID。
        /// </summary>
        private string ResolveModMatchId(KMod.Mod mod, Dictionary<string, string> steamMapping)
        {
            // 1. 尝试获取 Steam 创意工坊 ID（模组文件夹名）
            string folderName = GetModFolderName(mod);

            if (!string.IsNullOrEmpty(folderName))
            {
                // 检查 config.json 中是否有 Steam ID → 文件夹名 的映射
                if (steamMapping.TryGetValue(folderName, out string mappedFolder))
                {
                    Debug.Log($"[{ModMain.MOD_ID}] 模组 '{mod.title}': Steam ID {folderName} → 映射到本地化文件夹 '{mappedFolder}'");
                    return mappedFolder;
                }

                // 直接检查文件夹名是否在汉化库中存在
                if (Directory.Exists(Path.Combine(_localizationsDir, folderName)))
                    return folderName;
            }

            // 2. 回退到 staticID
            if (!string.IsNullOrEmpty(mod.staticID))
            {
                // 先检查 config.json 中是否有 staticID → 文件夹名 的映射
                if (steamMapping.TryGetValue(mod.staticID, out string mappedByStaticId))
                {
                    Debug.Log($"[{ModMain.MOD_ID}] 模组 '{mod.title}': staticID '{mod.staticID}' → 映射到本地化文件夹 '{mappedByStaticId}'");
                    return mappedByStaticId;
                }

                // 再检查 staticID 是否直接对应汉化库文件夹
                if (Directory.Exists(Path.Combine(_localizationsDir, mod.staticID)))
                {
                    Debug.Log($"[{ModMain.MOD_ID}] 模组 '{mod.title}': 使用 staticID '{mod.staticID}' 匹配汉化库。");
                    return mod.staticID;
                }
            }

            return null;
        }

        /// <summary>
        /// 获取模组的文件夹名称（对于 Steam 创意工坊模组即为 Workshop ID）。
        /// 通过一次性扫描模组目录并缓存结果来提高效率。
        /// </summary>
        private string GetModFolderName(KMod.Mod mod)
        {
            // 如果缓存已构建，直接查询
            if (_folderCacheBuilt)
                return _modFolderCache.TryGetValue(mod.staticID, out string cached) ? cached : null;

            // 首次调用时一次性构建缓存
            BuildFolderCache();
            return _modFolderCache.TryGetValue(mod.staticID, out string result) ? result : null;
        }

        /// <summary>一次性扫描模组目录，构建 staticID → 文件夹名 的映射缓存</summary>
        private void BuildFolderCache()
        {
            _folderCacheBuilt = true;
            try
            {
                // 收集所有可能的模组根目录
                var modDirs = new List<string>();

                // 1. 本地模组目录
                string localModsDir = KMod.Manager.GetDirectory();
                if (!string.IsNullOrEmpty(localModsDir) && Directory.Exists(localModsDir))
                {
                    modDirs.Add(localModsDir);

                    // 游戏将 Steam 创意工坊模组缓存到 mods/Steam/ 子目录
                    string steamCacheDir = Path.Combine(localModsDir, "Steam");
                    if (Directory.Exists(steamCacheDir) && !modDirs.Contains(steamCacheDir))
                        modDirs.Add(steamCacheDir);
                }

                // 2. Steam 创意工坊模组目录（常见路径）
                foreach (string wp in SteamWorkshopPaths)
                {
                    if (Directory.Exists(wp) && !modDirs.Contains(wp))
                        modDirs.Add(wp);
                }

                Debug.Log($"[{ModMain.MOD_ID}] 将扫描以下模组目录: {string.Join(", ", modDirs)}");

                // 遍历所有模组目录
                foreach (string modsDir in modDirs)
                {
                    if (!Directory.Exists(modsDir)) continue;
                    foreach (string subDir in Directory.GetDirectories(modsDir))
                    {
                        // staticID 在 mod.yaml 中（非 mod_info.yaml）
                        string modYamlPath = Path.Combine(subDir, "mod.yaml");
                        if (!File.Exists(modYamlPath)) continue;

                        try
                        {
                            string content = File.ReadAllText(modYamlPath);
                            foreach (string line in content.Split('\n'))
                            {
                                string trimmed = line.Trim();
                                if (trimmed.StartsWith("staticID:"))
                                {
                                    string value = trimmed.Substring("staticID:".Length).Trim().Trim('"', '\'');
                                    if (!string.IsNullOrEmpty(value) && !_modFolderCache.ContainsKey(value))
                                        _modFolderCache[value] = Path.GetFileName(subDir);
                                    break;
                                }
                            }
                        }
                        catch
                        {
                            // 单个文件读取失败不影响整体流程
                        }
                    }
                }

                Debug.Log($"[{ModMain.MOD_ID}] 模组目录缓存已构建，共 {_modFolderCache.Count} 个模组。");
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 构建模组目录缓存失败: {e.Message}");
            }
        }

        /// <summary>获取当前白名单集合（只读），用于翻译加载时的过滤</summary>
        public HashSet<string> GetWhitelist() => _whitelist;

        /// <summary>获取汉化库中可用的模组翻译数量</summary>
        public int GetAvailableModCount()
        {
            if (!Directory.Exists(_localizationsDir)) return 0;
            return Directory.GetDirectories(_localizationsDir).Length;
        }

        // ──────────────────────────── .po 原生翻译部署 ────────────────────────────

        /// <summary>
        /// 为白名单中使用 .po 原生翻译机制的模组，运行时生成 zh.po 并部署到模组的 translations/ 目录。
        /// 适用于 PLib 等框架模组：其建筑/物品名称由 LocString 烘焙，OverloadStrings 无法写回，
        /// 必须通过 .po 文件在 Localization.Initialize 阶段由游戏原生加载。
        /// </summary>
        public void CopyPoTranslations(IReadOnlyList<KMod.Mod> mods)
        {
            Debug.Log($"[{ModMain.MOD_ID}] ========== 开始 .po 原生翻译部署 ==========");

            var steamMapping = _config?.SteamIdMapping ?? new Dictionary<string, string>();
            int generatedCount = 0;

            foreach (KMod.Mod mod in mods)
            {
                if (mod.staticID == ModMain.MOD_ID) continue;
                if (!mod.IsActive() || mod.status != KMod.Mod.Status.Installed) continue;

                string matchId = ResolveModMatchId(mod, steamMapping);
                if (matchId == null) continue;
                if (!_whitelist.Contains(matchId)) continue;

                // 检查汉化库中是否有该模组的 zh.json
                string modLocDir = Path.Combine(_localizationsDir, matchId);
                string jsonPath = Path.Combine(modLocDir, "zh.json");
                if (!File.Exists(jsonPath))
                {
                    Debug.Log($"[{ModMain.MOD_ID}] .po 部署: '{matchId}' 无 zh.json，跳过");
                    continue;
                }

                // 定位目标模组在磁盘上的安装路径
                string targetModPath = ResolveTargetModPath(mod, steamMapping);
                if (targetModPath == null)
                {
                    Debug.LogWarning($"[{ModMain.MOD_ID}] .po 部署: '{matchId}' 无法定位模组目录");
                    continue;
                }

                // 查找 .pot 模板文件（优先 translations/ 子目录，回退模组根目录）
                string potPath = FindPotTemplate(targetModPath);
                if (potPath == null)
                {
                    Debug.Log($"[{ModMain.MOD_ID}] .po 部署: '{matchId}' 无 .pot 模板，不支持原生翻译");
                    continue;
                }

                // 加载 zh.json 翻译数据
                Dictionary<string, string> translations;
                try
                {
                    string json = File.ReadAllText(jsonPath);
                    var data = JsonConvert.DeserializeObject<TranslationData>(json);
                    translations = data?.translations;
                    if (translations == null || translations.Count == 0)
                    {
                        Debug.LogWarning($"[{ModMain.MOD_ID}] .po 部署: '{matchId}' zh.json 无翻译条目");
                        continue;
                    }
                }
                catch (Exception e)
                {
                    Debug.LogWarning($"[{ModMain.MOD_ID}] .po 部署: 读取 zh.json 失败: {e.Message}");
                    continue;
                }

                // 从 .pot 模板 + zh.json 生成 .po 内容
                string poContent = GeneratePoFromTemplate(potPath, translations);
                if (string.IsNullOrEmpty(poContent))
                {
                    Debug.LogWarning($"[{ModMain.MOD_ID}] .po 部署: '{matchId}' 生成 .po 内容为空");
                    continue;
                }

                // 确保 translations/ 目录存在并写入 zh.po
                string translationsDir = Path.Combine(targetModPath, "translations");
                try
                {
                    Directory.CreateDirectory(translationsDir);
                    string poPath = Path.Combine(translationsDir, "zh.po");
                    File.WriteAllText(poPath, poContent, new System.Text.UTF8Encoding(false));
                    generatedCount++;
                    Debug.Log($"[{ModMain.MOD_ID}] .po 部署: '{matchId}' -> {poPath} ({translations.Count} 条)");
                }
                catch (Exception e)
                {
                    Debug.LogWarning($"[{ModMain.MOD_ID}] .po 部署: 写入 zh.po 失败: {e.Message}");
                }
            }

            Debug.Log($"[{ModMain.MOD_ID}] ========== .po 部署完成，生成 {generatedCount} 个文件 ==========");
        }

        /// <summary>
        /// 解析目标模组在磁盘上的实际安装路径。
        /// 通过候选标识符（Steam 文件夹名、staticID、config 映射值）在所有已知模组目录中搜索。
        /// </summary>
        private string ResolveTargetModPath(KMod.Mod mod, Dictionary<string, string> steamMapping)
        {
            // 收集所有可能的候选标识符
            var candidates = new List<string>();

            string folderName = GetModFolderName(mod);
            if (!string.IsNullOrEmpty(folderName))
                candidates.Add(folderName);

            if (!string.IsNullOrEmpty(mod.staticID))
                candidates.Add(mod.staticID);

            // 添加 config.json 映射值（反向查找：值 → 也可能作为文件夹名）
            foreach (var kvp in steamMapping)
            {
                if (kvp.Key == mod.staticID || kvp.Key == folderName)
                {
                    if (!candidates.Contains(kvp.Value))
                        candidates.Add(kvp.Value);
                }
            }

            if (candidates.Count == 0) return null;

            // 在所有已知模组根目录中搜索
            foreach (string rootDir in GetAllModRootDirs())
            {
                if (!Directory.Exists(rootDir)) continue;
                foreach (string candidate in candidates)
                {
                    string modPath = Path.Combine(rootDir, candidate);
                    if (Directory.Exists(modPath))
                        return modPath;
                }
            }

            return null;
        }

        /// <summary>在目标模组目录中查找 .pot 翻译模板文件（优先 translations/ 子目录，回退根目录）</summary>
        private string FindPotTemplate(string modPath)
        {
            // 优先 translations/ 子目录
            string transDir = Path.Combine(modPath, "translations");
            if (Directory.Exists(transDir))
            {
                string[] pots = Directory.GetFiles(transDir, "*.pot");
                if (pots.Length > 0) return pots[0];
            }

            // 回退到模组根目录
            string[] rootPots = Directory.GetFiles(modPath, "*.pot");
            if (rootPots.Length > 0) return rootPots[0];

            return null;
        }

        /// <summary>收集所有可能的模组根目录（本地 + Steam 缓存 + Steam 创意工坊）</summary>
        private List<string> GetAllModRootDirs()
        {
            var dirs = new List<string>();

            string localModsDir = KMod.Manager.GetDirectory();
            if (!string.IsNullOrEmpty(localModsDir) && Directory.Exists(localModsDir))
            {
                dirs.Add(localModsDir);

                // 游戏将 Steam 创意工坊模组缓存到 mods/Steam/ 子目录，
                // 实际加载从此处读取，必须纳入扫描范围
                string steamCacheDir = Path.Combine(localModsDir, "Steam");
                if (Directory.Exists(steamCacheDir))
                    dirs.Add(steamCacheDir);
            }

            foreach (string wp in SteamWorkshopPaths)
            {
                if (Directory.Exists(wp) && !dirs.Contains(wp))
                    dirs.Add(wp);
            }

            return dirs;
        }

        /// <summary>
        /// 从 .pot 模板文件 + zh.json 翻译字典生成 .po 文件内容。
        /// 解析策略：逐行状态机扫描 #. 注释提取键名，替换 msgstr 为中文翻译。
        /// </summary>
        private string GeneratePoFromTemplate(string potPath, Dictionary<string, string> translations)
        {
            string[] lines;
            try
            {
                lines = File.ReadAllLines(potPath);
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 读取 .pot 文件失败: {e.Message}");
                return null;
            }

            var sb = new System.Text.StringBuilder();
            string currentKey = null;
            bool lookingForMsgstr = false;
            bool isFirstEntry = true; // 头部条目（无 #. 注释）

            for (int i = 0; i < lines.Length; i++)
            {
                string line = lines[i];
                string trimmed = line.Trim();

                // 检测 #. <KEY> 注释行 → 提取翻译键名
                if (trimmed.StartsWith("#. "))
                {
                    // 遇到新条目，重置上一条目状态
                    lookingForMsgstr = false;
                    currentKey = trimmed.Substring(3).Trim();
                    isFirstEntry = false;
                    sb.AppendLine(line);
                    continue;
                }

                // 头部条目（msgid "" 开头的元数据块）：追加语言字段
                if (isFirstEntry && trimmed == "msgstr \"\"")
                {
                    sb.AppendLine(line);
                    sb.AppendLine("\"Language: zh\"");
                    sb.AppendLine("\"MIME-Version: 1.0\"");
                    sb.AppendLine("\"Content-Type: text/plain; charset=UTF-8\"");
                    sb.AppendLine("\"Content-Transfer-Encoding: 8bit\"");
                    continue;
                }

                // 状态：已找到键名，正在等待 msgstr 行
                if (lookingForMsgstr && trimmed.StartsWith("msgstr "))
                {
                    if (currentKey != null
                        && translations.TryGetValue(currentKey, out string translation)
                        && !string.IsNullOrEmpty(translation))
                    {
                        // 用中文翻译替换空 msgstr
                        sb.AppendLine(FormatPoMsgstr(translation));
                    }
                    else
                    {
                        // 无翻译，保留原始空 msgstr
                        sb.AppendLine(line);
                    }
                    lookingForMsgstr = false;
                    continue;
                }

                // 检测 msgctxt 行 → 标记接下来将遇到 msgstr
                if (currentKey != null && trimmed.StartsWith("msgctxt "))
                {
                    lookingForMsgstr = true;
                }

                sb.AppendLine(line);
            }

            return sb.ToString();
        }

        /// <summary>
        /// 将翻译文本格式化为 .po 文件的 msgstr 块。
        /// 处理转义（反斜杠、双引号）和多行拆分（按 \n 拆为 gettext 多行格式）。
        /// </summary>
        private string FormatPoMsgstr(string text)
        {
            // 转义 .po 特殊字符
            string escaped = text.Replace("\\", "\\\\").Replace("\"", "\\\"");

            // 不含换行符 → 单行 msgstr
            if (!escaped.Contains("\\n"))
                return $"msgstr \"{escaped}\"";

            // 含换行符 → 拆为 gettext 多行格式
            var sb = new System.Text.StringBuilder();
            sb.AppendLine("msgstr \"\"");

            string[] parts = escaped.Split(new[] { "\\n" }, StringSplitOptions.None);
            for (int j = 0; j < parts.Length; j++)
            {
                if (j < parts.Length - 1)
                    sb.AppendLine($"\"{parts[j]}\\n\"");
                else if (parts[j].Length > 0)
                    sb.AppendLine($"\"{parts[j]}\"");
            }

            // 移除最后一行多余的换行（StringBuilder 末尾已有换行）
            return sb.ToString().TrimEnd('\r', '\n');
        }
    }

    // ──────────────────────────── 配置数据类 ────────────────────────────

    /// <summary>汉化补丁配置文件结构</summary>
    public class LocalizeConfig
    {
        /// <summary>
        /// Steam 创意工坊 ID → 本地化文件夹名 的映射。
        /// 键: Steam Workshop ID（即模组文件夹名，如 "3113986230"）
        /// 值: localizations 目录下对应的翻译文件夹名
        /// </summary>
        [JsonProperty("steamIdMapping")]
        public Dictionary<string, string> SteamIdMapping { get; set; } = new Dictionary<string, string>();
    }
}
