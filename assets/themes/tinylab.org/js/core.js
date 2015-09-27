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
  var icon = pid + " i";

  /* Hide all of the other nodes */
  var nodes = root.find("ul");
  $.each(nodes, function() {
    var nodeid = $(this).attr('id');

    if (!nodeid)
       return; 

    childid = child.replace('#','');
    if (child != nodeid && child.indexOf(nodeid) < 0 && $(this).css('display') == "block") {
      var iconid = nodeid.replace(/-cld$/,'');
      var myicon = $("#" + iconid + " i");

      $(this).hide();
      switch_icon(myicon, open, close);
    }
  });

  common_click(child, icon, open, close);
}

function color_toc()
{
  var root_id = "toc_widget_content";
  var root = $('#' + root_id);

  var nodes = root.find(".not_empty");
  $.each(nodes, function() {
     var p = $(this).parent().parent();;
     var p_id = p.attr('id');
     var cnt = 0;
     while (p_id != root_id && cnt < 4) {
       /* console.log(p_id); */
       var p_li = p_id.replace(/-cld$/,'');
       $("#" + p_li + " a").addClass('not_empty');
       cnt ++;
       p = p.parent();
       p_id = p.attr('id');
     }
  });
}
