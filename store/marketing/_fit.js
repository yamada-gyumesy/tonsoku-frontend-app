// 組版を、書き出したい画素数ぴったりに合わせる。
//
// **App Store は寸法の完全一致を要求する。** 1px でもズレると受け取られず、
// しかも「アップロードされなかった」としか分からない（three の
// `docs/setup-app.md` の初回提出チェックリストにも同じ注記がある）。
//
// **使い方**: 組版は native なサイズ（iPhone なら 1290×2796）で書いておき、
// 書き出し側は目的の窓サイズで開くだけ。ここが差を吸収する。
//
// **縦横で別々に伸ばす。** 6.9"(1290×2796 = 0.4614) と 6.5"(1284×2778 = 0.4622)
// は比が完全には一致しないので、等倍で合わせると必ず余白か切れが出る。
// 差は 0.18% で、**目で見て分かる歪みにはならない**。余白が出るほうが事故
// （黒帯・端が切れる）なので、こちらを採る。
(function () {
  var stage = document.querySelector('.viewport') || document.querySelector('.stage');
  if (!stage) return;
  var nw = stage.offsetWidth;
  var nh = stage.offsetHeight;
  // **窓の大きさに頼らない。** headless Chrome は `--window-size` で頼んだ
  // 高さより内側が小さい（実測 2796 → 2709 の 87px 少ない）。窓に合わせると
  // 組版がそのぶん縮み、**書き出しの下に白帯が残る**。狙いの寸法は
  // `?w=&h=` で渡してもらい、書き出し側が左上から切り出す。
  var q = location.search;
  var mw = q.match(/[?&]w=(\d+)/);
  var mh = q.match(/[?&]h=(\d+)/);
  var w = mw ? +mw[1] : window.innerWidth;
  var h = mh ? +mh[1] : window.innerHeight;
  if (!nw || !nh || (nw === w && nh === h)) return;
  stage.style.transformOrigin = 'top left';
  stage.style.transform = 'scale(' + w / nw + ',' + h / nh + ')';
  document.documentElement.style.width = w + 'px';
  document.documentElement.style.height = h + 'px';
  document.body.style.width = w + 'px';
  document.body.style.height = h + 'px';
  document.body.style.overflow = 'hidden';
})();
