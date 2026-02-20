module.exports = { 
  proxy: "nginx:80",
  // Dockerコンテナ内で起動なら80。ローカルならlocalhost:8080

  // 既存そのまま
  host: "0.0.0.0", 

  // URL書き換えルール（追加）
  rewriteRules: [
    {
      match: /localhost:8080/g,
      fn: function() {
        return 'localhost:3000';
      }
    },
    {
      match: /http:\/\/localhost:8080/g,
      fn: function() {
        return 'http://localhost:3000';
      }
    }
  ],

  // CSSは最終物だけ監視
  files: [
    "./assets/css/{output.css,main.css}",
    "./assets/js/**/*.js",
    "./**/*.php",
    "./**/*.html"
  ],

  ignore: [
    "node_modules/**",
    "./assets/scss/**",
    "./assets/css/input.css"
  ],

  // 書き込みが落ち着くまで待つ
  watchOptions: {
    awaitWriteFinish: {
      stabilityThreshold: 400,
      pollInterval: 80
    }
  },

  port: 3000,
  open: true,
  injectChanges: true,
  reloadDelay: 0,
  reloadDebounce: 150,

  middleware: [
    function(req, res, next) {
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate, max-age=0');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');
      next();
    }
  ],

  snippetOptions: {
    rule: {
      match: /<\/body>/i,
      fn: function(snippet, match) {
        return snippet + match;
      }
    }
  }
};
