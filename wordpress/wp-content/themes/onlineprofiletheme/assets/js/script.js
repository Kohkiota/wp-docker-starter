// ====================共通コンポーネント=======================
const pageId = document.querySelector('main').id;
const loadingArea = document.querySelector('#loading');
const upBtn = document.querySelector('#up-btn');
const menuBtn = document.querySelector('#menu-toggle-btn');

// NOTE: currentSlide は slideshow() だけが更新する。他は参照のみ。
let currentSlide = 0;
let zoomStartTime = 0; // ズーム先行開始の時刻を記録

/*
画面遷移
================================================ */
// ロゴ＋背景がフェードアウト

const indexPageLoadAnimation = () => {
    window.scrollTo(0, 0);

    return fadeInOpeningText()
        .then(() => appearAndWait())
        .then(() => exitText())
        .then(() => openShutterAndFinish()) 
        .then(() => {
            loadingArea.style.display = 'none';
    });
};

// opening-text 全体を 0.2秒でフェードイン
const fadeInOpeningText = () => {
  return new Promise((resolve) => {
    const text = document.querySelector('#opening-text');
    text.style.opacity = '0';
    const anim = text.animate(
      [
        { opacity: 0 },
        { opacity: 1 },
      ],
      {
        duration: 200,
        easing: 'linear',
        fill: 'forwards',
      }
    );

    anim.finished.then(resolve);
  });
};

// 文字出現、色変化
const appearAndWait = () => {
  return new Promise((resolve) => {
    const spans = document.querySelectorAll('#opening-text span');
    
    // 初期化
    spans.forEach(span => {
      span.getAnimations().forEach(a => a.cancel()); // 残ってたら停止
      span.style.backgroundPosition = '0 0%';
      span.style.willChange = 'background-position';
    });

    // 次フレームに開始（初期値を描画させてから動かす）
    requestAnimationFrame(() => {
      spans.forEach(span => {
          span.animate([
              { backgroundPosition: '0 0%' },    // 黒表示（下から塗られる）
              { backgroundPosition: '0 100%' } // グレー表示
        ], {
          duration: 800,
          easing: 'cubic-bezier(0.22, 1, 0.36, 1)', //ベジェ曲線でeaseoutっぽく
          fill: 'forwards' //これないと、終わるともとにもどる
        });
      });
    });
    setTimeout(resolve, 1800);
  });
};

// 文字移動、消失
const exitText = () => {
  return new Promise((resolve) => {
    const spans = document.querySelectorAll('#opening-text span');
    const totalSpans = spans.length

    spans.forEach((span, index) => {
      const randomY = Math.random() * 40 - 20;
      const delay = (totalSpans - 1 - index) * 60;

      setTimeout(() => {
        span.animate([
          { transform: 'translate(0, 0)', opacity: 1 },
          { transform: `translate(60px, ${randomY}px)`, opacity: 0 }
        ], {
          duration: 500,
          easing: 'cubic-bezier(0.55, 0, 1, 0.45)',
          fill: 'forwards'
        });
      }, delay);
    });
        
    // テキスト全体のフェードアウト（重ねがけ）
    const text = document.querySelector('#opening-text');
    text.animate([
      { opacity: 1 },
      { opacity: 0 }
    ], {
      duration: 750,
      easing: 'ease-in',
      fill: 'forwards'
    });
    
    setTimeout(resolve, 200);
  });
};

// シャッター解放
const openShutterAndFinish = () => {
  return new Promise((resolve) => {
    const shutterTop = document.querySelector('#shutter-top');
    const shutterBottom = document.querySelector('#shutter-bottom');
    
    shutterTop.animate([
      { transform: 'translateY(0)' },
      { transform: 'translateY(-100%)' }
    ], {
      duration: 1300,
      easing: 'cubic-bezier(0.76, 0, 0.24, 1)',
      fill: 'forwards'
    });
    
    shutterBottom.animate([
      { transform: 'translateY(0)' },
      { transform: 'translateY(100%)' }
    ], {
      duration: 1300,
      easing: 'cubic-bezier(0.76, 0, 0.24, 1)',
      fill: 'forwards'
    });
    
    setTimeout(resolve, 1300);
  });
};

// 背景だけフェードアウト
const pageLoadAnimation = () => {
  return new Promise((resolve) => {
    const shutters = document.querySelectorAll('#shutter-top, #shutter-bottom');
    
    shutters.forEach(shutter => {
      shutter.animate([
        { opacity: 1 },
        { opacity: 0 }
      ], {
        duration: 700,
        easing: 'ease',
        fill: 'forwards'
      });
    });
    
    setTimeout(() => {
      loadingArea.style.display = 'none';
      resolve();
    }, 700);
  });
};

/*
画面遷移のメイン処理
================================================ */
// sessionに初回アクセスかどうかフラグを保存し、indexページならロゴから遷移、スライドショー開始。index以外または2回目以降のアクセスなら画面遷移のみ。
// 'load'はコンポーネント挿入時に終了してしまっているので即実行
const runLoadScreen = () => {
  const isFirstLoad = sessionStorage.getItem('isFirstLoad');
  
  // 画像・フォント完全読み込みを待つ
  Promise.all([
    document.fonts.ready,
    new Promise(resolve => {
      if (document.readyState === 'complete') {
        resolve();
      } else {
        window.addEventListener('load', resolve);
      }
    })
  ]).then(() => {

  // スクロールのたびに色を更新
  window.addEventListener('scroll', requestUpdateBtnClr, { passive: true });

    if (pageId === 'front-page') {
      // シャッターが開く前にズームを先行開始（開いた瞬間にscale(1)から始まるカクつき防止）
      const firstSlide = document.querySelector('.slide');
      if (firstSlide) {
        firstSlide.classList.add('zooming');
        zoomStartTime = performance.now();
      }

      if (isFirstLoad === null) {
        indexPageLoadAnimation()
          .then(() => slideshow());
      } else {
        pageLoadAnimation()
          .then(() => slideshow());
      }
    } else {
      pageLoadAnimation();
    }
    sessionStorage.setItem('isFirstLoad', 'true');
  });
};

// init()実行時に既にloadが終わっている場合
if (document.readyState === 'complete') {
    // loadイベントは既に発火済み → 即座に実行
    runLoadScreen();
} else {
    // まだload前 → イベントリスナーで待つ
    window.addEventListener('load', runLoadScreen);
}


/*
// メニューの開閉・スライドショーの状況に応じて、ボタンの色とヘッダー(sp)のブラーを制御する関数
================================================ */
function updateBtnClr(currentSlide) {
  const header = document.querySelector('header');
  const headerTitle = document.querySelector('#header-title');
  const allLines = document.querySelectorAll('#menu-toggle-btn>.btn-menu__line');

  const isOpen = menuBtn.classList.contains('active');

  // トップページ以外
  if (pageId !== 'front-page') {
    header.classList.toggle('header-mod', !isOpen);
    return;
  }

  // トップページ用
  const slideshowContainer = document.querySelector('#slideshow-container');

  const btnRect = menuBtn.getBoundingClientRect();
  const slideshowRect = slideshowContainer.getBoundingClientRect();
  // menuBtnの下辺が、slideshowの下辺より下にある = 外に出ている
  const isOutside = btnRect.bottom > slideshowRect.bottom;

  // 初期化
  header.classList.remove('header-mod');
  headerTitle.classList.remove('is-white');
  allLines.forEach(line => line.classList.remove('is-white'));

  if (isOutside || isOpen) {
    // メニューボタンがスライドショーコンテナの
    // 外に出ている、または、ボタン開いている
    //  → メニューボタン黒固定｜smでの文字も黒固定
  } else {
    // メニューボタンがスライドショーコンテナに
    // 重なっている、かつ、ボタン閉じてる
    //  → スライドに応じた色で：メニューボタンの色｜smでの文字色
    if (currentSlide === 1) {
      headerTitle.classList.add('is-white');
      allLines.forEach(line => line.classList.add('is-white'));
    } else {
      headerTitle.classList.remove('is-white');
      allLines.forEach(line => line.classList.remove('is-white'));
    }
  }

  // トップページでは、スライドショーコンテナの外かつボタン閉じてるときは、spのヘッダーにブラー効果
  // トップページ以外では、ボタン閉じてるときはつねにspのヘッダーにブラー効果
  header.classList.toggle('header-mod', isOutside && !isOpen);
}

// スクロールでのupdateBtnClrによる負荷上昇でのかくつき防止
let ticking = false;

function requestUpdateBtnClr() {
  if (ticking) return;
  ticking = true;

  requestAnimationFrame(() => {
    updateBtnClr(currentSlide); // この中で getBoundingClientRect する
    ticking = false;
  });
}

/*
スライドショー
================================================ */
const slideshow = () => {
  const slides = document.querySelectorAll('.slide');

    // 次のスライドに切替る関数
    function nextSlide() {
        const prev = slides[currentSlide];
        prev.classList.remove('active');
        // フェードアウト完了後にズームをリセット
        setTimeout(() => prev.classList.remove('zooming'), 1000);

        currentSlide = (currentSlide + 1) % slides.length;
        slides[currentSlide].classList.add('active', 'zooming');
        updateBtnClr(currentSlide);
    }

    // 初期スライドのズーム開始（先行開始済みならスキップ）
    if (!slides[currentSlide].classList.contains('zooming')) {
        slides[currentSlide].classList.add('zooming');
    }

    // 初期色設定 & スライドショー開始
    updateBtnClr(currentSlide);

    // ズーム先行開始分を差し引いて最初の切り替えタイミングを調整
    const elapsed = zoomStartTime ? performance.now() - zoomStartTime : 0;
    const firstDelay = Math.max(6000 - elapsed, 0);
    setTimeout(() => {
        nextSlide();
        setInterval(nextSlide, 6000);
    }, firstDelay);
};


/*
スライドメニューの開閉処理
================================================ */
const line1 = document.querySelector('.btn-menu__line--1');
const line2 = document.querySelector('.btn-menu__line--2');
const line3 = document.querySelector('.btn-menu__line--3');
const menuPanel = document.querySelector('#menu-panel');
const menuItems = document.querySelectorAll('.fade-in');
const menuOptions = {
    duration: 1200,
    easing: 'ease',
    fill: 'forwards',
}

// メニューを開く関数
function openMenu() {
    // パネルをスライドイン
    menuPanel.animate(
      [{ transform: 'translateX(100%)' }, { transform: 'translateX(0)' }],
      menuOptions
    );

    // 初期化。ちらつき防止
    menuItems.forEach(el => {
      el.style.opacity = '0';
      el.style.transform = 'translateY(-2rem)';
    });
    // メニューアイテムを順番にフェードイン
    menuItems.forEach((menuItem, index) => {
        menuItem.animate(
            {
                opacity: [0, 1],
                transform: ['translateY(-2rem)', 'translateY(0)'],
            },
            {
                duration: 800,
                delay: 100 * index,
                easing: 'ease',
                fill: 'forwards',
            }
        );
    });

    // ハンバーガーボタンをバツに変形
    line1.style.transform = 'translateY(9.5px) rotate(-45deg)';
    line1.style.width = '32px';
    line2.style.opacity = '0';
    line3.style.transform = 'translateY(-10.5px) rotate(45deg)';
    line3.style.width = '32px';

    // 影をすぐ追加
    menuPanel.classList.add('active');
    menuBtn.classList.add('active');
}

// メニューを閉じる関数
function closeMenu() {
    // パネルをスライドアウト
    menuPanel.animate(
      [{ transform: 'translateX(0)' }, { transform: 'translateX(100%)' }],
      menuOptions
    );

    // メニューアイテムをフェードアウト
    menuItems.forEach((menuItem) => {
        menuItem.animate(
            {opacity: [1, 0]},
            menuOptions
        );
    });

    // メニューを戻す（ハンバーガーに）
    line1.style.transform = '';
    line2.style.opacity = '';
    line3.style.transform = '';
    line3.style.width = '16px';

    // 影を一定時間後に消す
    setTimeout(() => {
        menuPanel.classList.remove('active');
    }, 700);

    // activeクラスを削除
    menuBtn.classList.remove('active');
}

// ハンバーガーボタンのクリックで開閉
menuBtn.addEventListener('click', () => {
    const isOpen = menuBtn.classList.contains('active');
    if (isOpen) {
        closeMenu();
    } else {
        openMenu();
    }
    requestUpdateBtnClr();
});

// メニューパネル以外の領域をクリックしたときに閉じる
document.addEventListener('click', (e) => {
    const isOpen = menuBtn.classList.contains('active');
    if (isOpen && !menuPanel.contains(e.target) && !menuBtn.contains(e.target)) {
        closeMenu();
    }
    requestUpdateBtnClr();
});


/*
スクロールフェードイン
================================================ */
const scrollFadeIn = () => {
    const targets = document.querySelectorAll('.scroll-fade-in');
    if (!targets.length) return;

    // 2回目以降はアニメーションなしで即表示
    if (sessionStorage.getItem('isFirstLoad') !== null) {
        targets.forEach(target => {
            target.style.transition = 'none';
            target.classList.add('is-visible');
        });
        return;
    }

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('is-visible');
                observer.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.15,
    });

    targets.forEach(target => observer.observe(target));
};

scrollFadeIn();

/*
上に戻るボタン
================================================ */
if (upBtn) {
    const handleScroll = () => {
        const scrollTop = window.scrollY;
        const documentHeight = document.documentElement.scrollHeight;
        const windowHeight = window.innerHeight;
        const scrollPercent = scrollTop / (documentHeight - windowHeight);
        
        if (scrollPercent >= 0.3) {
            upBtn.classList.add('show');
        } else {
            upBtn.classList.remove('show');
        }
    };
    window.addEventListener('scroll', handleScroll);

    // ボタンクリック時の上へのスムーズスクロール
    upBtn.addEventListener('click', () => {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
}