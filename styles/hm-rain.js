/* hm unified matrix rain — attaches to <canvas id="hm-rain"> if present.
   Brand-tuned: navy trails, cyan glyphs, harmony accents.
   Respects prefers-reduced-motion (canvas hidden by hm-theme.css). */
(function () {
  var cv = document.getElementById('hm-rain');
  if (!cv) return;
  var cx = cv.getContext('2d');
  var GLYPHS = '01✦HM和声演进-{}<>/;$#'.split('');
  var W, H, cols, drops, speeds;
  function fit() {
    W = cv.width = window.innerWidth;
    H = cv.height = window.innerHeight;
    cols = Math.floor(W / 16);
    drops = [];
    speeds = [];
    for (var i = 0; i < cols; i++) {
      drops.push(Math.random() * -H / 16);
      speeds.push(0.45 + Math.random() * 0.75);
    }
  }
  fit();
  window.addEventListener('resize', fit);
  function frame() {
    cx.fillStyle = 'rgba(8,20,38,0.14)';
    cx.fillRect(0, 0, W, H);
    cx.font = '14px Consolas, monospace';
    for (var i = 0; i < cols; i++) {
      var y = drops[i] * 16;
      var ch = GLYPHS[(Math.random() * GLYPHS.length) | 0];
      cx.fillStyle = Math.random() < 0.06
        ? 'rgba(234,244,250,0.92)'
        : 'rgba(79,216,235,0.72)';
      cx.fillText(ch, i * 16, y);
      if (y > H && Math.random() > 0.985) drops[i] = 0;
      drops[i] += speeds[i];
    }
    requestAnimationFrame(frame);
  }
  frame();
})();
