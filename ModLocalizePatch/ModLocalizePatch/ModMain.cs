using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using HarmonyLib;
using KMod;

namespace ModLocalizePatch
{
    public class ModMain : UserMod2
    {
        public const string MOD_ID = "ModLocalizePatch";
        public const string MOD_VERSION = "1.1.0";

        internal static string ModDirectory { get; private set; }
        internal static LocalizationManager LocalizeMgr { get; private set; }

        public override void OnLoad(Harmony harmony)
        {
            base.OnLoad(harmony);
            ModDirectory = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

            Debug.Log($"[{MOD_ID}] v{MOD_VERSION} 正在加载...");

            try
            {
                LocalizeMgr = new LocalizationManager(ModDirectory);
                LocalizeMgr.LoadConfig();
                LocalizeMgr.LoadWhitelist();

                // 注册 Harmony 补丁（用于运行时注入翻译 + 重启提示）
                RegisterAllPatches(harmony);

                // 针对不走 STRINGS 键的模组（如 Critter Overlay）注册定向汉化补丁
                CritterOverlayPatches.Apply(harmony);

                // 针对 MeepNetAI（GRAVNet AI）内联硬编码 UI 文本注册定向汉化补丁
                MeepNetPatches.Apply(harmony);

                Debug.Log($"[{MOD_ID}] 加载完成。汉化库包含 {LocalizeMgr.GetAvailableModCount()} 个模组的翻译数据。");
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{MOD_ID}] 加载失败: {e.Message}\n{e.StackTrace}");
            }
        }

        public override void OnAllModsLoaded(Harmony harmony, IReadOnlyList<KMod.Mod> mods)
        {
            base.OnAllModsLoaded(harmony, mods);
            if (LocalizeMgr == null) return;

            try
            {
                LocalizeMgr.DetectAndCopy(mods);
                // 为使用 .po 原生翻译机制的模组生成并部署 zh.po
                LocalizeMgr.CopyPoTranslations(mods);
                // 白名单更新后清除翻译缓存，以便下次注入时按新白名单重新加载
                Patches.ClearCache();
                // 全部模组加载完成后再次尝试注册定向补丁（若早期目标程序集尚未加载）
                CritterOverlayPatches.Apply(harmony);
                MeepNetPatches.Apply(harmony);
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{MOD_ID}] 检测与复制过程出错: {e.Message}\n{e.StackTrace}");
            }
        }

        /// <summary>注册所有 Harmony 补丁，失败时记录警告而不中断模组加载</summary>
        private static void RegisterAllPatches(Harmony harmony)
        {
            try
            {
                harmony.PatchAll();
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[{MOD_ID}] Harmony 补丁注册失败: {e.Message}\n{e.StackTrace}");
            }
        }
    }
}
