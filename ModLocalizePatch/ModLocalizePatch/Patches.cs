using System.Collections.Generic;
using System.IO;
using HarmonyLib;
using Newtonsoft.Json;

namespace ModLocalizePatch
{
    /// <summary>
    /// Harmony 补丁集合：
    /// 1. 运行时注入翻译文本（使翻译在文件复制后立即生效，无需重启）
    /// 2. 在主菜单显示重启提示
    /// </summary>
    public static class Patches
    {
        // ──────────────── 运行时翻译注入 ────────────────

        /// <summary>
        /// 拦截 OverloadStrings，在其他模组注册字符串时注入汉化。
        /// 这确保翻译在文件复制后的当前会话中即可生效。
        /// </summary>
        [HarmonyPatch(typeof(Localization), nameof(Localization.OverloadStrings),
            new[] { typeof(Dictionary<string, string>) })]
        public static class OverloadStrings_Patch
        {
            public static void Prefix(Dictionary<string, string> translated_strings)
            {
                // 加载所有已匹配模组的翻译数据并注入
                var translations = LoadAllMatchedTranslations();
                if (translations == null || translations.Count == 0) return;

                foreach (var kvp in translations)
                {
                    // 如果模组自带汉化（原值已含中文），则保留模组自身的翻译
                    if (translated_strings.TryGetValue(kvp.Key, out string existing)
                        && ContainsChinese(existing))
                        continue;

                    translated_strings[kvp.Key] = kvp.Value;
                }
            }
        }

        /// <summary>
        /// 拦截 Strings.Get(string)，始终检查是否有中文翻译并覆盖。
        /// 这是最通用的翻译注入方式，覆盖所有字符串查找场景。
        /// </summary>
        [HarmonyPatch(typeof(Strings), nameof(Strings.Get), new[] { typeof(string) })]
        public static class Strings_Get_Patch
        {
            public static void Postfix(string key, ref StringEntry __result)
            {
                var translations = LoadAllMatchedTranslations();
                if (translations != null && translations.TryGetValue(key, out string translated)
                    && !string.IsNullOrEmpty(translated))
                {
                    __result = new StringEntry(translated);
                }
            }
        }


        /// <summary>
        /// 拦截 Strings.Get(StringKey)，覆盖通过 StringKey 查找的字符串。
        /// 游戏内部大量使用 StringKey 重载进行字符串查找。
        /// </summary>
        [HarmonyPatch(typeof(Strings), nameof(Strings.Get), new[] { typeof(StringKey) })]
        public static class Strings_GetStringKey_Patch
        {
            public static void Postfix(StringKey key0, ref StringEntry __result)
            {
                var translations = LoadAllMatchedTranslations();
                if (translations != null && !string.IsNullOrEmpty(key0.String)
                    && translations.TryGetValue(key0.String, out string translated)
                    && !string.IsNullOrEmpty(translated))
                {
                    __result = new StringEntry(translated);
                }
            }
        }

        /// <summary>
        /// 建筑注册时注入 STRINGS.BUILDINGS.* 翻译
        /// </summary>
        [HarmonyPatch(typeof(GeneratedBuildings), nameof(GeneratedBuildings.LoadGeneratedBuildings))]
        public static class LoadGeneratedBuildings_Patch
        {
            public static void Prefix()
            {
                InjectByPrefix("STRINGS.BUILDINGS.");
            }
        }

        /// <summary>
        /// 元素加载时注入 STRINGS.ELEMENTS.* 翻译
        /// </summary>
        [HarmonyPatch(typeof(Assets), "SubstanceListHookup")]
        public static class SubstanceListHookup_Patch
        {
            public static void Prefix()
            {
                InjectByPrefix("STRINGS.ELEMENTS.");
            }
        }


        // ──────────────── 辅助方法 ────────────────

        /// <summary>缓存已加载的翻译数据，避免重复读取文件</summary>
        private static Dictionary<string, string> _cachedTranslations;
        private static bool _cacheLoaded;

        /// <summary>
        /// 加载汉化库中已启用模组的翻译数据（通过白名单过滤以减少内存占用）。
        /// 白名单为空时回退到全量加载（首次启动时检测尚未完成）。
        /// 使用程序集位置定位目录，确保在最早阶段也能加载。
        /// </summary>
        private static Dictionary<string, string> LoadAllMatchedTranslations()
        {
            if (_cacheLoaded) return _cachedTranslations;

            _cacheLoaded = true;

            // 使用程序集位置而非 ModMain.ModDirectory，确保早期加载阶段也能工作
            string asmDir = Path.GetDirectoryName(typeof(Patches).Assembly.Location);
            if (string.IsNullOrEmpty(asmDir)) return null;

            string localizationsDir = Path.Combine(asmDir, "localizations");
            if (!Directory.Exists(localizationsDir)) return null;

            _cachedTranslations = new Dictionary<string, string>();

            // 获取白名单用于过滤（白名单为空时回退到全量加载）
            var whitelist = ModMain.LocalizeMgr?.GetWhitelist();
            bool hasWhitelist = whitelist != null && whitelist.Count > 0;

            // 遍历汉化库中模组文件夹，仅加载白名单中的模组翻译
            foreach (string modDir in Directory.GetDirectories(localizationsDir))
            {
                string modFolderName = Path.GetFileName(modDir);
                if (hasWhitelist && !whitelist.Contains(modFolderName))
                    continue;

                foreach (string file in Directory.GetFiles(modDir, "*.json", SearchOption.AllDirectories))
                {
                    try
                    {
                        string json = File.ReadAllText(file);
                        var data = JsonConvert.DeserializeObject<TranslationData>(json);
                        if (data?.translations == null) continue;

                        foreach (var kvp in data.translations)
                            _cachedTranslations[kvp.Key] = kvp.Value;
                    }
                    catch (System.Exception e)
                    {
                        Debug.LogWarning($"[{ModMain.MOD_ID}] 加载翻译文件失败 [{Path.GetFileName(file)}]: {e.Message}");
                    }
                }
            }

            if (_cachedTranslations.Count > 0)
            {
                string scope = hasWhitelist ? "白名单内" : "全量";
                Debug.Log($"[{ModMain.MOD_ID}] 运行时注入：已加载 {_cachedTranslations.Count} 条翻译（{scope}）。");
            }

            return _cachedTranslations;
        }

        /// <summary>按前缀注入翻译到 Strings 表</summary>
        private static void InjectByPrefix(string prefix)
        {
            var translations = LoadAllMatchedTranslations();
            if (translations == null) return;

            // 收集匹配前缀的翻译
            var matched = new Dictionary<string, string>();
            foreach (var kvp in translations)
            {
                if (kvp.Key.StartsWith(prefix))
                    matched[kvp.Key] = kvp.Value;
            }

            if (matched.Count > 0)
            {
                // 使用 OverloadStrings 覆盖已存在的字符串
                Localization.OverloadStrings(matched);
            }
        }

        /// <summary>检测字符串是否包含中文字符</summary>
        private static bool ContainsChinese(string text)
        {
            if (string.IsNullOrEmpty(text)) return false;
            foreach (char c in text)
                if (c >= '\u4e00' && c <= '\u9fff') return true;
            return false;
        }

        /// <summary>清除翻译缓存（当白名单变更时调用）</summary>
        internal static void ClearCache()
        {
            _cachedTranslations = null;
            _cacheLoaded = false;
        }
    }

    /// <summary>翻译文件 JSON 数据结构（与 ModTranslator 格式兼容）</summary>
    public class TranslationData
    {
        [JsonProperty("modId")]
        public string modId { get; set; }

        [JsonProperty("modName")]
        public string modName { get; set; }

        [JsonProperty("translations")]
        public Dictionary<string, string> translations { get; set; }
    }
}
