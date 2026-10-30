# 复用微软计算核心，以 QML 重建跨平台界面

本项目以微软 Windows Calculator 公开源码提交 `79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128` 为行为与布局参考，用户已选择移植其 MIT 授权的 C++ 算术核心，并以 QML 重建 Windows、macOS、Linux 的应用界面。与独立重写计算核心相比，此方案更有利于保留任意精度基础算术、各模式的求值顺序和连续按键行为；代价是承担 Windows 相关依赖的移植工作并保留适用的版权与第三方声明。

窗口外框使用所在系统的原生样式，应用内部采用 Windows 11 Fluent 风格。公开源码不包含正式绘图引擎和可复用的正式汇率数据：用户已接受首版绘图仅覆盖多条 `y=f(x)` 曲线、平移缩放和坐标查看，货币换算使用独立汇率来源；不得将这些范围描述为与商店发行版完全等价。

参考：[固定源码版本](https://github.com/microsoft/calculator/tree/79e1ac53bba690cdf930e5dcd6ed9dbc4cbfb128)。此版本是源码对照基准，不代表已验证的 Microsoft Store 发行版本。
