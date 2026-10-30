# 03: 切换主题、语言并保存偏好

**What to build:** 用户可在设置中切换浅色、深色或跟随系统主题，以及中文、英文或跟随系统语言；重新打开后保留选择和最近使用的模式。

**Blocked by:** 01: 运行真实核心驱动的标准计算器。

**Status:** resolved

**Spec:** Windows 11 风格跨平台计算器。

**User stories:** 2, 7, 8, 9。

- [x] 设置界面真实支持浅色、深色和跟随系统主题；显式选择不受系统主题变化覆盖，跟随系统时正确采用可取得的系统偏好。
- [x] 支持简体中文、英文和跟随系统语言；对于未支持的系统语言采用明确、稳定的回退语言。
- [x] 模式名称、操作说明、当前已实现页面和错误提示接入统一翻译机制；显示切换无需用户丢弃正在进行的计算。
- [x] 设置与已实现页面采用 Fluent 风格，焦点、禁用和选中状态在两套主题中均清晰可辨；文案变化和窗口缩放不遮挡必要控件。
- [x] 主题、语言与最近模式保存在本地；普通重启恢复这些偏好，对不可用的模式值安全回退，不恢复计算历史或内存。
- [x] 后续页面能复用既有主题与翻译机制，不需要为每个模式另建一套设置状态。
- [x] 通过用户操作和受控系统偏好验证主题/语言切换、设置持久化、最近模式恢复及无效设置回退，避免依赖测试机固定语言或外观。


## Implementation evidence (ticket 03)

The implementer left closure to integration validation; the completed merge checks are recorded below.

- `AppPreferences` supplies one application-owned Qt translator and local preferences for Light/Dark/System and English/Simplified Chinese/System. `SystemPreferences` uses Qt's native scheme override/reset and system UI languages; unsupported system languages, including Traditional Chinese, fall back to English. The Settings page follows the pinned Fluent appearance/settings layout and leaves the Standard keypad positions intact.
- Current mode captions, Settings, operation descriptions, accessibility labels, and error labels use `qsTr` with the shared context/source catalog. The existing manager refreshes localized engine resources without reinitializing Ratpack or discarding pending operands. The QML test continues `6 × 7 = 42` after a language switch and translates both the active division-by-zero error and a subsequent undefined-result error in both directions.
- Settings use `QSettings`, with stable mode keys resolved through `ModeRegistry.indexForKey`; unknown saved modes open Standard. No history, memory, operands or expression snapshots are persisted. `tests/preferences-restart.cmake` launches three real processes against a unique settings root: UI preference selection and ordinary close; restored choices with a fresh result/expression; invalid external theme/language/mode values falling back safely. Only Standard is available at this integration point; no unimplemented mode was added to manufacture a restoration test.
- `tests/qml/tst_preferences.qml` exercises actual QML controls and the real application/core, substituting only external system preferences and isolated settings roots. It covers system changes versus explicit overrides, unsupported languages, theme selection, translated errors, pending calculation continuity, keyboard focus/scrolling and focus retention after translation, both supported languages, narrow/wide windows, and readable heading/result contrast. Native RadioButtons expose checked state; all current options remain operable. This ticket introduces no disabled feature controls.
- TDD red → green records in `.build-ticket03`: `.build-ticket03-red-theme.log` → `.build-ticket03-green-theme.log` (Settings absent); `.build-ticket03-red-language.log` → `.build-ticket03-green-language.log` (language option absent); `.build-ticket03-red-error-language.log` → `green-error-language.log` (stale English core error); `red-system.log` → `green-system.log` (system input absent); `red-restart.log` → `green-restart.log` (restart lost Chinese choice); `red-settings-focus.log` / `settings-focus.log` → `green-settings-focus.log` (missing accessible label and clipped focused option); `red-contrast.log` → `green-contrast.log` (light-theme heading contrast).
- Final checks after `git merge --no-edit integration/calculator` (already current at `bb491bd9a3b4b250477d8504f437a8cc3bc19745`): `cmake --build .build-ticket03 -j2`; all four CTest entries, run individually to stay within tool time limits; `cmake --build .build-ticket03 --target calculator_ui_qmllint -j2`. All passed. Each main UI configuration reports 23 passed / 0 failed / 0 skipped; the restart entry passes write/restore/invalid processes. Settings/data/cache roots are isolated, including explicit Qt INI user/system settings paths. Logs are `recovered-{build,restart,light,dark,zh-CN,qmllint}.log`.
- Visual review: `settings-{light,dark}-{narrow,wide}.png`, English/light and Simplified-Chinese/dark, 320×460 and 900×700. A failing contrast assertion caught the Fluent/Fusion fallback heading color before the central application palette correction. QML lint has no warnings.
- Qt API facts were checked with the required find-docs Context7 library lookup and Qt docs queries for QTranslator/installTranslator/QQmlEngine::retranslate and QStyleHints::setColorScheme/reset; Context7 succeeded, so no documentation fallback was needed. The UI skill's targeted Fluent desktop-settings search returned Fluent 2 and was applied without introducing a new design direction.
- Limits recorded honestly: Linux/Qt 6.12 only. The attempted native Wayland suite failed window-activation setup (`active` remained false after `requestActivate()`), before calculator interaction, and was not suppressed or counted as passing. The complete offscreen suite supplies functional acceptance; native Wayland keyboard interaction and Windows/macOS remain unverified for this ticket. See `native-wayland.log`. No remote push, PR, deployment, parent-spec edit or other-ticket edit was performed.


## Integration completion evidence

- Merged source commit `d2233161f1c77377729375e5ea351cb05bb8618c` into the clean `integration/calculator` checkout with `git merge --no-ff`; merge commit `eb1124475f7f5b1232c95ccb2f878b4344b616f8` preserves ticket 02's complete Standard keypad, error recovery, Copy, and all existing tests. Resolved README, shortcut, and test conflicts by combining both tickets' behavior. The parent spec and other tickets were not changed.
- Integration regressions were verified before their fixes: the Chinese operation-label test observed `Percent` instead of `百分比`; the Settings keyboard test observed clipboard text `6` instead of the previously copied `1`. Added the eight missing Standard operation/Copy translations and disabled hidden Standard shortcuts, while retaining the per-key error-state guard. Both tests then passed. Logs: `.build-integration/merge03-{red,green}-operation-translations.log` and `merge03-{red,green}-hidden-copy.log`.
- `cmake -S . -B .build-integration -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=Debug` and `cmake --build .build-integration -j2` passed. All four CTest entries passed on the merged tree: `calculator-ui-light`, `calculator-ui-dark`, `calculator-ui-zh-CN`, and `calculator-preferences-restart`. Dark and Chinese verbose logs each report **133 passed, 0 failed, 0 skipped**; the restart entry reports **3 passed, 0 failed, 0 skipped** in each write/restore/invalid process. Evidence: `.build-integration/merge03-{configure,build,light,dark,zh-CN,restart}.log`.
- `cmake --build .build-integration --target calculator_ui_qmllint -j2` passed without warnings; `git diff --check` passed. Reviewed merged Settings images at 320×460 and 900×700 in English/light and Chinese/dark, plus both Standard error-state images: readable captions, visible checked/focus states, preserved disabled controls, and no hidden necessary controls when focused. Automated checks also cover contrast and keyboard scrolling.
- All seven criteria above are fulfilled for the currently implemented Standard mode and Settings. Shared preferences/catalog/registry remain reusable by later modes. Only Standard is registered, so recent-mode restoration covers its stable key and the unavailable-key fallback. Preferences write no history/memory snapshots; the process restart test verifies fresh result/expression. Native Wayland interaction is not newly verified (the implementer's activation failure remains a recorded limitation); Windows/macOS remain untested. Final application-wide independent review remains part of the overall implement-spec workflow.
