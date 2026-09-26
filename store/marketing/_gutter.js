// **ストアの並びの隙間を見込んで組む**（ユーザーの指定）。
//
// App Store も Google Play も、スクショを**隙間を空けて**横に並べる。4 枚を 1 枚の
// 絵として続けて組むと（1・2 枚目をまたぐ端末、枚をまたぐスタンプ）、並んだ時に
// 隙間のぶんだけ継ぎ目がずれ、斜めのものほど折れて見える。
//
// そこで**隙間も絵の一部として組み、隙間に当たる帯は捨てる**: 枚 k の窓を
// `k × (幅 + 隙間)` に置き、枚をまたぐ飾りは「主に載っている枚」に合わせて隙間の
// ぶんだけずらす。こうすると、ストアで隙間を空けて並んだ時にちょうどつながる。
//
// **組版の座標は隙間なしのまま書く**（ここが一律に直す）。隙間は幅の 4%
// （App Store の並びを実測した比。Play も同じ程度）。
(function () {
  var GUTTER = 0.04;
  var view = document.querySelector('.viewport');
  var stage = document.querySelector('.stage');
  if (!stage) return;
  var W = (view || stage).offsetWidth;
  var G = Math.round(W * GUTTER);
  var pair = view && stage.offsetWidth > W * 1.5;
  var sr = stage.getBoundingClientRect();
  var scale = sr.width / stage.offsetWidth || 1;

  // 飾りと端末を、主に載っている枚に合わせてずらす（枚 k なら k × 隙間）
  document.querySelectorAll('.stage > .blob, .stage > .device').forEach(function (el) {
    var r = el.getBoundingClientRect();
    var cx = (r.left + r.width / 2 - sr.left) / scale;
    var home = Math.floor(cx / W);
    if (!home) return;
    el.style.left = (parseFloat(getComputedStyle(el).left) + home * G) + 'px';
  });
  // 2 枚目の窓は「幅 + 隙間」先
  if (pair && document.body.classList.contains('b')) stage.style.left = -(W + G) + 'px';
})();
