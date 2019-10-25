var os = function () {
  var ua = navigator.userAgent,
    isWindowsPhone = /(?:Windows Phone)/.test(ua),
    isSymbian = /(?:SymbianOS)/.test(ua) || isWindowsPhone,
    isAndroid = /(?:Android)/.test(ua),
    isFireFox = /(?:Firefox)/.test(ua),
    isChrome = /(?:Chrome|CriOS)/.test(ua),
    isTablet = /(?:iPad|PlayBook)/.test(ua) || (isAndroid && !/(?:Mobile)/.test(ua)) || (isFireFox && /(?:Tablet)/.test(ua)),
    isPhone = /(?:iPhone)/.test(ua) && !isTablet,
    isPc = !isPhone && !isAndroid && !isSymbian;
  return {
    isTablet: isTablet,
    isPhone: isPhone,
    isAndroid: isAndroid,
    isPc: isPc
  }
}()


function getCookie(name) {
  var value = "; " + document.cookie;
  var parts = value.split("; " + name + "=");
  if (parts.length == 2) return parts.pop().split(";").shift();
}

function getToken() {
  let value = getCookie('UM_distinctid');
  if (!value) {
    return defaultToken;
  }
  return value.substring(value.length - 6).toUpperCase();
}

var locked = false;
var articleSelector = '#main-content';
var defaultToken = 'tinylab';

$(articleSelector).ready(function () {
  var articleElement = $(articleSelector)[0];

  if (articleElement) {
    var height = articleElement.clientHeight;
    var halfHeight = height * 0.3;
    var token = getToken();
    $('#locker').find('.token').text(token);

    var home = false;
    if (window.location.href.split('/').length <= 4)
       home = true;

    console.log('articleElement is there, halfheight is', halfHeight);

    function update() {
      if (locked) {
        $(articleSelector).css('height', halfHeight + 'px');
        $(articleSelector).addClass('lock');
        $('#locker').css('display', 'block');
      } else {
        $(articleSelector).css('height', 'initial');
        $(articleSelector).removeClass('lock');
        $('#locker').css('display', 'none');
      }
    }


    function detect() {
      $.ajax({
        url: '/users.xml', dataType: 'xml', success: function (data) {
          var u = data.getElementsByTagName('u');
          console.log('Detecting Token', token);
          for (var i = 0; i < u.length; i ++) {
             var user = $(u[i]).text();
             if (user == token) {
                console.log('Detected Token', token);
                locked = false;
                break;
             }
          }
          if (i == u.length) {
              console.log('Not detected', token);
              locked = true;
          }
          update();
        },
        error: function (data) {
          locked = false;
          update();
        }
      });
    }

    var once = 0;
    var unlock_delay = 30000;

    function unlock(delay) {
      if (once == 0) {
         console.log('unlocking in ', delay);
         once = 1;
         setTimeout(function () {
           console.log('unlock it now ...');
           locked = false;
           update();
        }, delay);
      }
    }

    document.getElementById('unlocker').addEventListener('click', function (e){
        unlock(0);
    }, false);

    document.getElementById('unlocker').addEventListener('touchstart', function (e){
        unlock(0);
    }, false);

    if (halfHeight > 800 && !home) {
      detect();
    } else {
      console.log('Lock did not work at', os);
    }

  }
})
