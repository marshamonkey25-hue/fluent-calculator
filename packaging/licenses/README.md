# Qt runtime license texts

The three texts in this directory are unmodified copies from Qt Base v6.8.3:

- https://github.com/qt/qtbase/blob/v6.8.3/LICENSES/LGPL-3.0-only.txt
- https://github.com/qt/qtbase/blob/v6.8.3/LICENSES/GPL-3.0-only.txt
- https://github.com/qt/qtbase/blob/v6.8.3/LICENSES/Qt-GPL-exception-1.0.txt

These apply to the corresponding Qt material, not as a new license for this
project. Runtime deployment also includes an SDK `licenses` directory when
present. The official Qt source archive and component tags are linked in the
package license-status document. See https://doc.qt.io/qt-6.8/licensing.html and
https://doc.qt.io/qt-6.8/licenses-used-in-qt.html for module/third-party details.

Linux native Arch/Fedora builds use system-owned Qt rather than copying it.
Debian uses a private SDK because its distribution Qt omits FluentWinUI3;
Windows and macOS also deploy the matching Qt SDK runtime.
