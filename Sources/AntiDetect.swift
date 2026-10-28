import Foundation

/// Script chạy trước khi trang tải (document-start) để trang không báo "Phát hiện AdBlock".
/// Trang kiểm tra bằng cách tải thử vài script quảng cáo (googlesyndication, amazon, taboola,
/// facebook, twitter) và xem chúng có lỗi không, cộng với dò dấu vết trình duyệt lạ.
enum AntiDetect {
    static let js = #"""
    (function () {
      if (window.__roAD) return; window.__roAD = true;
      var BAIT = /googlesyndication\.com|amazon-adsystem\.com|taboola\.com|facebook\.net|ads-twitter\.com|doubleclick\.net|googletagservices\.com|adservice\.google/i;

      // 1) Script "mồi": không tải thật, báo tải thành công
      function fakeLoad(el) {
        setTimeout(function () {
          try { el.dispatchEvent(new Event('load')); } catch (e) {}
        }, 30);
      }
      var desc = Object.getOwnPropertyDescriptor(HTMLScriptElement.prototype, 'src');
      if (desc && desc.set) {
        Object.defineProperty(HTMLScriptElement.prototype, 'src', {
          configurable: true, enumerable: desc.enumerable,
          get: function () { return this.__fakeSrc || desc.get.call(this); },
          set: function (v) {
            if (BAIT.test(String(v))) { this.__fakeSrc = String(v); this.__bait = true; return; }
            desc.set.call(this, v);
          }
        });
      }
      var origSetAttr = Element.prototype.setAttribute;
      Element.prototype.setAttribute = function (n, v) {
        if (this instanceof HTMLScriptElement && String(n).toLowerCase() === 'src' && BAIT.test(String(v))) {
          this.src = v; return;
        }
        return origSetAttr.apply(this, arguments);
      };
      ['appendChild', 'insertBefore'].forEach(function (m) {
        var orig = Node.prototype[m];
        Node.prototype[m] = function (child) {
          var r = orig.apply(this, arguments);
          if (child && child.__bait) fakeLoad(child);
          return r;
        };
      });
      var origAppend = Element.prototype.append;
      if (origAppend) Element.prototype.append = function () {
        var r = origAppend.apply(this, arguments);
        for (var i = 0; i < arguments.length; i++) if (arguments[i] && arguments[i].__bait) fakeLoad(arguments[i]);
        return r;
      };
      var origFetch = window.fetch;
      if (origFetch) window.fetch = function (input) {
        var u = typeof input === 'string' ? input : (input && input.url) || '';
        if (BAIT.test(u)) return Promise.resolve(new Response('', { status: 200 }));
        return origFetch.apply(this, arguments);
      };

      // 2) Giấu dấu vết WKWebView
      var origGOPN = Object.getOwnPropertyNames;
      Object.getOwnPropertyNames = function (o) {
        var r = origGOPN(o);
        if (o === window || o === navigator) r = r.filter(function (k) { return k !== 'webkit'; });
        return r;
      };

      // 3) Dự phòng: nếu màn hình chặn vẫn hiện thì gỡ đi
      function isBlocker(el) {
        if (!(el instanceof HTMLElement)) return false;
        var t = el.textContent || '';
        if (!/AdBlock|Cốc Cốc/i.test(t) || t.length > 3000) return false;
        var s = getComputedStyle(el);
        return s.position === 'fixed' && el.offsetWidth >= innerWidth * 0.9 && el.offsetHeight >= innerHeight * 0.9;
      }
      function sweep() {
        if (!document.body) return;
        var found = false;
        document.querySelectorAll('body > *, body > * > *').forEach(function (el) {
          if (isBlocker(el)) { el.remove(); found = true; }
        });
        if (found || document.body.style.overflow === 'hidden') {
          document.body.style.overflow = '';
          document.documentElement.style.overflow = '';
        }
      }
      new MutationObserver(function () { sweep(); })
        .observe(document.documentElement, { childList: true, subtree: true });
      setInterval(sweep, 1000);
    })();
    """#
}
