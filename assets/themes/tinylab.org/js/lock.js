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
var toc = '#toc_widget_container';
var defaultToken = 'tinylab';

$(articleSelector).ready(function () {
  var articleElement = $(articleSelector)[0];

  if (articleElement) {
    var height = articleElement.clientHeight;
    var halfHeight = height * 0.3;
    var token = getToken();
    $('#locker').find('.token').text(token);

    console.log('articleElement is there, halfheight is', halfHeight);

    function update() {
      if (locked) {
        $(articleSelector).css('height', halfHeight + 'px');
        $(articleSelector).addClass('lock');
        $('#locker').css('display', 'block');
        $(toc).css('display', 'none');
      } else {
        $(articleSelector).css('height', 'initial');
        $(articleSelector).removeClass('lock');
        $('#locker').css('display', 'none');
        $(toc).css('display', 'block');
      }
    }


    function detect() {
      $.ajax({
        url: '/users.xml', dataType: 'xml', success: function (data) {
          var u = data.getElementsByTagName('u');
          console.log('Detecting Token', token);
          for (var i = 0; i < u.length; i ++) {
             var user = $(u[i]).text();
             console.log('Registered user', user);
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

    if (os.isPc && halfHeight > 800) {

      detect();

      setTimeout(function () {
        console.log('Allow normal users access after 30 seconds');
        locked = false;
        update();
      }, 30000);

    } else {
      console.log('Lock did not work at', os);
    }

  }
})
