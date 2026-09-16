using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using HarmonyLib;
using Newtonsoft.Json;

namespace ModLocalizePatch
{
    /// <summary>
    /// 针对 Critter Overlay（guybrush.CritterOverlay / OverlayKit）的定向汉化补丁。
    ///
    /// 该模组的用户文本不走标准 STRINGS 键查询，无法用 JSON 键匹配注入覆盖。
    /// 其中工具按钮提示（名称/描述）经由 OverlayKit.Overlay.OverlayFilters.Define(name, label, tooltip) 注册，
    /// 故对 Define 加 Prefix 按值替换 label / tooltip 为中文（签名全为 string，安全）。
    ///
    /// 注意：图例分类标签（Wild/Domesticated/Eggs）是目标模组的 const 常量字段，编译期已内联进消费方 IL，
    /// 反射无法改写（运行时报 "Cannot set a constant field"）；图例提示/顶栏标题同样为裸字面量。
    /// 因此改为在文本最终写入 UI 组件处拦截：对游戏 LocText.set_text 加 Prefix，
    /// 仅当值精确等于已知英文图例文本时替换为中文（单字典查找，开销极低）。
    /// 该 LocText 补丁仅在检测到 Critter Overlay 程序集时才注册，未安装时零开销、静默跳过。
    /// 译文文本存放于汉化库 localizations/guybrush.CritterOverlay/zh.json（exact/replace 两段），
    /// 本类运行时从库中加载，不在代码内硬编码译文。
    /// </summary>
    public static class CritterOverlayPatches
    {
        private const string FILTERS_TYPE = "OverlayKit.Overlay.OverlayFilters";
        private const string CATEGORY_TYPE = "CritterOverlay.Overlay.CritterCategory";
        private const string LOCTEXT_TYPE = "LocText";
        private const string LIB_FOLDER = "guybrush.CritterOverlay";

        private static bool _definePatched;
        private static bool _locTextPatched;

        /// <summary>整串精确替换表（图例标签/顶栏），从库中加载</summary>
        private static Dictionary<string, string> _exact = new Dictionary<string, string>();
        /// <summary>碎片替换表（提示句），从库中加载</summary>
        private static Dictionary<string, string> _replace = new Dictionary<string, string>();
        private static bool _textLoaded;

        /// <summary>从汉化库加载 Critter Overlay 译文（exact/replace），缺失时静默保持空表</summary>
        private static void EnsureTextLoaded()
        {
            if (_textLoaded) return;
            _textLoaded = true;
            try
            {
                string asmDir = Path.GetDirectoryName(typeof(CritterOverlayPatches).Assembly.Location);
                string path = Path.Combine(asmDir, "localizations", LIB_FOLDER, "zh.json");
                if (!File.Exists(path))
                {
                    Debug.LogWarning($"[{ModMain.MOD_ID}] 未找到 Critter Overlay 汉化库文件: {path}");
                    return;
                }
                var data = JsonConvert.DeserializeObject<CritterOverlayTextData>(File.ReadAllText(path));
                if (data?.exact != null) _exact = data.exact;
                if (data?.replace != null) _replace = data.replace;
                Debug.Log($"[{ModMain.MOD_ID}] 已从库加载 Critter Overlay 译文：exact {_exact.Count} 条、replace {_replace.Count} 条。");
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 加载 Critter Overlay 汉化库失败: {e.Message}");
            }
        }

        /// <summary>在模组加载早期与全部模组加载后各调用一次；内部幂等且对缺失目标静默跳过</summary>
        public static void Apply(Harmony harmony)
        {
            if (harmony == null) return;

            try
            {
                if (!_definePatched)
                {
                    Type filters = AccessTools.TypeByName(FILTERS_TYPE);
                    if (filters != null)
                    {
                        MethodInfo define = AccessTools.Method(filters, "Define",
                            new[] { typeof(string), typeof(string), typeof(string) });
                        if (define != null)
                        {
                            harmony.Patch(define,
                                prefix: new HarmonyMethod(typeof(CritterOverlayPatches), nameof(Define_Prefix)));
                            Debug.Log($"[{ModMain.MOD_ID}] 已为 {FILTERS_TYPE}.Define 注册汉化补丁。");
                        }
                        _definePatched = true;
                    }
                }
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 注册 Define 汉化补丁失败: {e.Message}");
            }

            // 仅当 Critter Overlay 存在时才注册 LocText 拦截（避免无谓全局开销）
            try
            {
                if (!_locTextPatched && AccessTools.TypeByName(CATEGORY_TYPE) != null)
                {
                    Type locText = AccessTools.TypeByName(LOCTEXT_TYPE);
                    if (locText != null)
                    {
                        MethodInfo setText = AccessTools.Method(locText, "set_text", new[] { typeof(string) });
                        if (setText != null)
                        {
                            harmony.Patch(setText,
                                prefix: new HarmonyMethod(typeof(CritterOverlayPatches), nameof(LocText_SetText_Prefix)));
                            Debug.Log($"[{ModMain.MOD_ID}] 已为 {LOCTEXT_TYPE}.set_text 注册图例汉化拦截。");
                        }
                        _locTextPatched = true;
                    }
                }
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 注册 LocText 汉化拦截失败: {e.Message}");
            }
        }

        /// <summary>拦截 OverlayFilters.Define，把英文 label / tooltip 替换为中文</summary>
        public static void Define_Prefix(ref string label, ref string tooltip)
        {
            try
            {
                EnsureTextLoaded();
                if (!string.IsNullOrEmpty(label) && _exact.TryGetValue(label, out string zhLabel))
                    label = zhLabel;

                if (!string.IsNullOrEmpty(tooltip))
                    tooltip = ApplyReplace(tooltip);
            }
            catch
            {
                // 汉化失败不应影响目标模组运行
            }
        }

        /// <summary>
        /// 拦截 LocText.set_text：当写入值精确等于已知英文图例文本时替换为中文。
        /// 用于覆盖 const 内联的图例分类标签、顶栏标题与分类提示。
        /// </summary>
        public static void LocText_SetText_Prefix(ref string value)
        {
            if (string.IsNullOrEmpty(value)) return;
            EnsureTextLoaded();
            // 1) 标签/顶栏：精确匹配整串替换
            if (_exact.TryGetValue(value, out string zh))
            {
                value = zh;
                return;
            }
            // 2) 提示句/碎片：特征 Replace
            value = ApplyReplace(value);
        }

        /// <summary>对值应用所有 replace 碎片规则（状态句与镜头句可能同时出现）</summary>
        private static string ApplyReplace(string value)
        {
            foreach (var rule in _replace)
            {
                if (value.IndexOf(rule.Key, StringComparison.Ordinal) >= 0)
                    value = value.Replace(rule.Key, rule.Value);
            }
            return value;
        }
    }

    /// <summary>Critter Overlay 汉化库 JSON 结构（exact 整串替换 / replace 碎片替换）</summary>
    public class CritterOverlayTextData
    {
        [JsonProperty("modId")]
        public string modId { get; set; }

        [JsonProperty("modName")]
        public string modName { get; set; }

        [JsonProperty("exact")]
        public Dictionary<string, string> exact { get; set; }

        [JsonProperty("replace")]
        public Dictionary<string, string> replace { get; set; }
    }
}
