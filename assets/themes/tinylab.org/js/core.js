function switch_icon(icon, open, close)
{
    if (icon) {
      icon.removeClass("icon-" + open);
      icon.addClass("icon-" + close);
    }
}

function common_click(child, icon, open, close)
{
  var child = $(child);
  var status = child.css("display");
  var icon= $(icon);

  if (status == "block") {
    child.hide();
    switch_icon(icon, open, close);
  } else {
    switch_icon(icon, close, open);
    child.show();
  }
}

function click_toc(pid, open, close)
{
  var root = $('#toc_widget_content');
  var child = pid + "-cld";
  var icon = pid + " a i";

  /* Hide all of the other nodes */
  var nodes = root.find("ul");
  $.each(nodes, function() {
    var nodeid = $(this).attr('id');

    if (!nodeid)
       return; 

    childid = child.replace('#','');
    if (child != nodeid && child.indexOf(nodeid) < 0 && $(this).css('display') == "block") {
      var iconid = nodeid.replace(/-cld$/,'');
      var myicon = $("#" + iconid + " a i");

      $(this).hide();
      switch_icon(myicon, open, close);
    }
  });

  common_click(child, icon, open, close);
}
