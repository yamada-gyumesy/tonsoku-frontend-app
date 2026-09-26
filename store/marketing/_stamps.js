// 背景の飾りを**のや子のスタンプ**にする（ユーザーの指定）。
//
// 前は丸（`.blob`）だった。**色・大きさ・置き場・濃さは丸の時のまま**（各組版の `.blob` の
// 指定）で、中身を web の OGP のスタンプ（`tonsoku-frontend-web/scripts/lib/ogp-template.ts`
// の `STAMP`）と同じ作りにする: 太い輪・細い輪・のや子の絵。比率も OGP のまま。
// 絵は web と同じ CDN の `characters/noyako/*.svg` を `assets/` に写したもの。
//
// **表情と傾きは並び順で決める**（組版ごとに書かない）。同じ表情・同じ向きが隣り合うと
// 模様に見えるので、3 つの表情と傾きをずらして回す。
//
// **丸は正円にする。** Android 判の円は iPhone 判から縦横別の比で写した楕円だが、
// スタンプが楕円だと潰れて見えるので、短い辺に合わせた正円を元の中心に置く。
(function () {
  var src = document.currentScript.src;
  var base = src.slice(0, src.lastIndexOf('/') + 1) + 'assets/';
  var FACES = ['smile', 'normal', 'confused'];
  var TILT = [-14, 11, -7, 17, -19, 8];
  // OGP の STAMP（size 460 に対して ring 14 / inner 7 / innerGap 12 / gap 80）を比で持つ
  var RING = 14 / 460, INNER = 7 / 460, INNER_GAP = 12 / 460, GAP = 80 / 460;
  document.querySelectorAll('.blob').forEach(function (b, i) {
    var cs = getComputedStyle(b);
    var color = cs.backgroundColor;
    var w = parseFloat(cs.width), h = parseFloat(cs.height);
    var d = Math.min(w, h);
    b.style.left = (parseFloat(cs.left) + (w - d) / 2) + 'px';
    b.style.top = (parseFloat(cs.top) + (h - d) / 2) + 'px';
    b.style.width = b.style.height = d + 'px';
    // **下地は敷かない**（輪と線だけ。塗った丸・線を抜いた丸・赤だけ下地、は試して外した）
    b.style.background = 'none';
    b.style.borderRadius = '50%';
    b.style.border = (d * RING) + 'px solid ' + color;
    b.style.padding = (d * GAP) + 'px';
    b.style.rotate = TILT[i % TILT.length] + 'deg';

    var inner = document.createElement('i');
    inner.style.cssText = 'position:absolute;border-radius:50%;inset:' + (d * INNER_GAP) + 'px;' +
      'border:' + (d * INNER) + 'px solid ' + color;
    var face = document.createElement('i');
    var url = 'url("' + base + 'noyako-' + FACES[i % FACES.length] + '.svg")';
    face.style.cssText = 'display:block;width:100%;height:100%;background:' + color + ';' +
      '-webkit-mask:' + url + ' center/contain no-repeat;mask:' + url + ' center/contain no-repeat';
    b.appendChild(inner);
    b.appendChild(face);
  });
})();
