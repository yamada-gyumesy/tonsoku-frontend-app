#!/usr/bin/env python3
"""同梱されないパッケージの一覧を作る。

**ライセンス表記に載せてよいのは、アプリに同梱されるものだけ。** Flutter が生成
する `NOTICES` は `.dart_tool/package_config.json` を元にしていて、**生成器
（build_runner・freezed・json_serializable など）まで含む**。それらはビルド時に
しか動かず配布物に入らないので、載せると事実と違う。

`flutter pub deps --json` の直接依存から辿った閉包に入らないものを「同梱されない」
として書き出す。

**完全には絞り込めない。** pub の解決結果では `test` や `analyzer` が riverpod の
通常依存として出るので、この方法では残る（実際に AOT に載るかはツリーシェイキング
次第で、列挙する手段が無い）。**載せ漏らすより多めに載せる**ほうを採っている
——足りないと表示義務を満たさないが、多いぶんは害が無い。

使い方:
    python3 tool/build_licenses.py
"""

import json
import shutil
import subprocess
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / 'lib' / 'core' / 'licenses' / 'dev_only_packages.dart'


def main() -> None:
    # **`flutter` は PATH に無いことがある**（手元は mise で管理している）。
    # 見つからなければ `mise exec -- flutter` に落として、手順どおりに叩ける
    # ようにする（CI は PATH に入っているのでそのまま通る）
    command = ['flutter', 'pub', 'deps', '--json']
    if shutil.which('flutter') is None:
        command = ['mise', 'exec', '--', *command]

    raw = subprocess.run(
        command, capture_output=True, text=True, check=True,
    ).stdout
    data = json.loads(raw)

    packages = {p['name']: p for p in data['packages']}
    kinds = {p['name']: p['kind'] for p in data['packages']}

    seen: set[str] = set()
    stack = [name for name, kind in kinds.items() if kind == 'direct']
    while stack:
        name = stack.pop()
        if name in seen or name not in packages:
            continue
        seen.add(name)
        stack.extend(packages[name]['dependencies'])

    everything = {name for name, kind in kinds.items() if kind != 'root'}
    dev_only = sorted(everything - seen)

    lines = '\n'.join(f"  '{name}'," for name in dev_only)
    OUT.write_text(f'''// GENERATED — tool/build_licenses.py が作る。手で編集しない。
//
// **アプリに同梱されないパッケージ。** 生成器やリンタなど、ビルド時にしか動かず
// 配布物に入らないもの。Flutter が集める `NOTICES` はこれらも含んでしまうので、
// ライセンス表記から外すために持っている（理由は tool/build_licenses.py）。

const devOnlyPackages = <String>{{
{lines}
}};
''', encoding='utf-8')
    print(f'{OUT.name} に {len(dev_only)} 件書いた')


if __name__ == '__main__':
    main()
