using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using HarmonyLib;
using Newtonsoft.Json;

namespace ModLocalizePatch
{
    /// <summary>
    /// 针对 MeepNetAI（GRAVNet AI and Infrastructure）的定向汉化补丁。
    ///
    /// 该模组主体文本经 MeepNetStrings.Register() 的 Strings.Add 注册裸 STRINGS.* 键，已由
    /// localizations/GRAVNetAI/zh.json 的 translations 段经 Strings.Get 补丁覆盖（见 Patches.cs）。
    ///
    /// 但仍有约 27 处内联硬编码 UI 文本（侧屏标题 GetTitle、下拉/专长侧屏的列头与标签、
    /// HUD 训练提示、船员头像职业、图层悬浮、通知、火箭模块限建提示、轨道无人机建造按钮、
    /// PLib 选项标题/描述等），以裸字面量直接写入控件，不经 Strings.Get，JSON 键匹配无法覆盖。
    /// 这些文本最终都渲染进 LocText，故沿用 CritterOverlayPatches 的成熟做法：
    /// 对游戏 LocText.set_text 加 Prefix，命中精确表则整串替换、命中特征表则碎片替换。
    ///
    /// 侧屏/下拉/按钮等模组自建 UI 使用基类 TMP_Text（非 LocText，LocText 重写了 set_text），
    /// 需额外挂钩基类 set_text 才能覆盖。性能守卫：首字符为 CJK 时立即返回。
    ///
    /// 该补丁仅在检测到 MeepNetAI 程序集类型时才注册，未安装时零开销、静默跳过。
    /// 译文存放于 localizations/GRAVNetAI/zh.json 的 exact / replace 两段，运行时从库加载，不在代码内硬编码。
    /// 深度插值的数值行（模型详情、图层容量、HUD 进度百分比等）不在本方案覆盖范围内，保留英文。
    /// </summary>
    public static class MeepNetPatches
    {
        private const string GATE_TYPE = "MeepNetAI.MeepNetStrings";
        private const string LOCTEXT_TYPE = "LocText";
        private const string TMPTEXT_TYPE = "TMPro.TMP_Text";
        private const string LIB_FOLDER = "GRAVNetAI";

        private static bool _locTextPatched;
        private static bool _tmpTextPatched;

        /// <summary>整串精确替换表（侧屏标题/列头/标签/提示/按钮/选项等），从库中加载</summary>
        private static Dictionary<string, string> _exact = new Dictionary<string, string>();
        /// <summary>碎片替换表（含轻微插值的高价值文本），从库中加载</summary>
        private static Dictionary<string, string> _replace = new Dictionary<string, string>();
        private static bool _textLoaded;

        /// <summary>从汉化库加载 MeepNetAI 内联译文（exact/replace），缺失时静默保持空表</summary>
        private static void EnsureTextLoaded()
        {
            if (_textLoaded) return;
            _textLoaded = true;
            try
            {
                string asmDir = Path.GetDirectoryName(typeof(MeepNetPatches).Assembly.Location);
                string path = Path.Combine(asmDir, "localizations", LIB_FOLDER, "zh.json");
                if (!File.Exists(path))
                {
                    Debug.LogWarning($"[{ModMain.MOD_ID}] 未找到 MeepNetAI 汉化库文件: {path}");
                    return;
                }
                var data = JsonConvert.DeserializeObject<InlinePatchTextData>(File.ReadAllText(path));
                if (data?.exact != null) _exact = data.exact;
                if (data?.replace != null) _replace = data.replace;
                Debug.Log($"[{ModMain.MOD_ID}] 已从库加载 MeepNetAI 内联译文：exact {_exact.Count} 条、replace {_replace.Count} 条。");
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 加载 MeepNetAI 内联汉化库失败: {e.Message}");
            }
        }

        /// <summary>在模组加载早期与全部模组加载后各调用一次；内部幂等且对缺失目标静默跳过</summary>
        public static void Apply(Harmony harmony)
        {
            if (harmony == null) return;

            // 仅当 MeepNetAI 存在时才注册 LocText 拦截（避免无谓全局开销）
            try
            {
                if (!_locTextPatched && AccessTools.TypeByName(GATE_TYPE) != null)
                {
                    Type locText = AccessTools.TypeByName(LOCTEXT_TYPE);
                    if (locText != null)
                    {
                        MethodInfo setText = AccessTools.Method(locText, "set_text", new[] { typeof(string) });
                        if (setText != null)
                        {
                            harmony.Patch(setText,
                                prefix: new HarmonyMethod(typeof(MeepNetPatches), nameof(LocText_SetText_Prefix)));
                            Debug.Log($"[{ModMain.MOD_ID}] 已为 {LOCTEXT_TYPE}.set_text 注册 MeepNetAI 内联文本汉化拦截。");
                        }
                        _locTextPatched = true;
                    }
                }
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 注册 MeepNetAI 内联汉化拦截失败: {e.Message}");
            }

            // 侧屏/下拉/按钮等模组自建 UI 使用基类 TMP_Text（非 LocText，LocText 重写了 set_text），
            // 需额外挂钩基类 set_text 才能覆盖。性能守卫：首字符为 CJK 时立即返回。
            try
            {
                if (!_tmpTextPatched && AccessTools.TypeByName(GATE_TYPE) != null)
                {
                    Type tmpText = AccessTools.TypeByName(TMPTEXT_TYPE);
                    if (tmpText != null)
                    {
                        MethodInfo setText2 = AccessTools.Method(tmpText, "set_text", new[] { typeof(string) });
                        if (setText2 != null)
                        {
                            harmony.Patch(setText2,
                                prefix: new HarmonyMethod(typeof(MeepNetPatches), nameof(TMPText_SetText_Prefix)));
                            Debug.Log($"[{ModMain.MOD_ID}] 已为 {TMPTEXT_TYPE}.set_text 注册 MeepNetAI 侧屏文本汉化拦截。");
                        }
                        _tmpTextPatched = true;
                    }
                }
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{ModMain.MOD_ID}] 注册 MeepNetAI TMP_Text 汉化拦截失败: {e.Message}");
            }
        }

        /// <summary>
        /// 拦截 LocText.set_text：当写入值精确等于已知英文内联文本时整串替换为中文，
        /// 否则对含轻微插值的文本应用特征碎片替换。
        /// </summary>
        public static void LocText_SetText_Prefix(ref string value)
        {
            if (string.IsNullOrEmpty(value)) return;
            EnsureTextLoaded();
            // 1) 标题/列头/标签/提示/按钮/选项：精确匹配整串替换
            if (_exact.TryGetValue(value, out string zh))
            {
                value = zh;
                return;
            }
            // 2) 含轻微插值的文本：特征碎片替换
            if (_replace.Count > 0)
                value = ApplyReplace(value);
        }

        /// <summary>
        /// 拦截基类 TMP_Text.set_text：覆盖模组自建侧屏/下拉/按钮等不使用 LocText 的控件
        /// （LocText 重写了 set_text，故 LocText 钩子触不到基类组件）。
        /// 性能守卫：首字符为 CJK（≥0x2E80，中文/全角）时直接返回，游戏中文文本热路径仅一次比较。
        /// </summary>
        public static void TMPText_SetText_Prefix(ref string value)
        {
            if (string.IsNullOrEmpty(value)) return;
            if (value[0] >= 0x2E80) return;
            EnsureTextLoaded();
            if (_exact.TryGetValue(value, out string zh))
            {
                value = zh;
                return;
            }
            if (_replace.Count > 0)
                value = ApplyReplace(value);
        }

        /// <summary>对值应用所有 replace 碎片规则</summary>
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

    /// <summary>内联文本汉化库 JSON 结构（exact 整串替换 / replace 碎片替换；translations 段由 Patches.cs 使用，此处忽略）</summary>
    public class InlinePatchTextData
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
