---
title: 二维码
tagline: 二维码生成器，方便手机快速共享资源
layout: page
group: navigation
permalink: /qrcode/
comments: false
order: 500
---
{% include JB/setup %}

<form id="qrcode-form" style="text-align:center;"><input id="qrcode-text" type="text" style="text-align:center;height:28px;width:268px" placeholder="请输入任意字符串、网址等"></form><hr>

<div style="text-align:center">
二维码显示区，手机端扫一扫即可访问：<br/><br/>
  <div style="margin-left:auto;margin-right:auto;text-align:center;border:1px solid #000;height:202px;width:202px">
    <div id="qrcode-picture" style="margin-left:auto;margin-right:auto;margin-top:1px"></div>
  </div>
</div>

<script type="text/javascript">
$(document).ready(function() {
  $('#qrcode-picture').qrcode({ text: 'http://tinylab.org', width: 200, height: 200 });
  $('#qrcode-form').submit(function() {
    var qrcode_text = $('#qrcode-text').val();
    var html = '<div id="qrcode-picture" style="margin-left:auto;margin-right:auto;margin-top:1px"></div>';

    if (qrcode_text) {
      $('#qrcode-picture').html(html);
      $('#qrcode-picture').show();
      $('#qrcode-picture').qrcode({ text: qrcode_text, width: 200, height: 200 });
    }
    return false;
  });
  $('#qrcode-text').mouseover(function () {
    $('#qrcode-text').blur().attr('placeholder', '');
  });
  $('#qrcode-text').mouseout(function () {
    $('#qrcode-text').blur().attr('placeholder', '请输入任意字符串、网址等');
  });

});
</script>
