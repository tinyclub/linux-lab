/*
 * Customized js for Thomas's Blog.
 * Thomas.Zhao, 2015-01-13
 */

Array.prototype.fill = function(value, start, length) {
    while (length--){
        if (length >= start)
          this[length] = value;
    }
    return this;
}

var Toc = {
    /*
     * Toc Affixing
     *
     * reference to:
     * https://github.com/twbs/bootstrap/blob/master/docs/assets/js/src/application.js#L35
     */
    setTocAffixing:function() {

        /* Scrollspy */
        var $window = $(window);
        var $body   = $(document.body);

        $body.scrollspy({
            target: '.toc_widget_container'
        });
        $window.on('load', function () {
            $body.scrollspy('refresh')
        });

        /* Kill links */
        $('#main_content_container [href=#]').click(function (e) {
            e.preventDefault()
        });
    }, /* end of setTocAffixing:function() */


    /* Generate directory tree
     *
     * toc_widget_content: side navigation element
     * main_content_container:  article body container.
     *
     * processing: search header elements(h1,h2,h3) in `main_content_container`,
     * generate directory tree list, and put them into toc_widget_content.
     */
    createToc:function (toc_widget_content, main_content_container, toc_widget){
        if(!toc_widget || main_content_container.length < 1 ||
                !toc_widget_content) {
            return false;
        }

        var nodes = main_content_container.find("h1,h2,h3,h4,h5");
        var ultoc = toc_widget_content;

        var node_num = 0;
        var h1, h2, h3, h4, h5;
        var h_cnt = new Array(0, 0, 0, 0, 0);
        var h_id = new Array("", "", "", "");
        var hid = new Array("", "", "", "");
        $.each(nodes,function(){
            var anchorPrefix = 'tocAnchor-';
            var tocid_prefix = 'ctg-';
            var tocid_suffix = '-cld';
            var icon_close = 'angle-right';
            var icon_open = 'angle-down';
            var $this = $(this);

            var nodetext = $this.text();

            // There maybe HTML tags in header inner text, use regex to erase them
            nodetext = nodetext.replace(/<\/?[^>]+>/g,"");
            nodetext = nodetext.replace(/&nbsp;/ig, "");

            // btw: Jekyll generates id for each header.
            var nodeid = $this.attr("id");
            if(!nodeid) {
                var anchorId = anchorPrefix + "_" + node_num;
                $(this).attr('id', anchorId);
                nodeid = anchorId;
            }

            var item_a = $("<a title='" + nodetext +"'></a>");
            item_a.attr("href", "#" + nodeid);
            item_a.text(nodetext);

            if (node_num == 0) {
                switch($this.get(0).tagName) {
                case "H1":
                    h1 = "H1";
                    h2 = "H2";
                    h3 = "H3";
                    h4 = "H4";
                    h5 = "H5";
                    break;
                case "H2":
                    h1 = "H2";
                    h2 = "H3";
                    h3 = "H4";
                    h4 = "H5";
                    h5 = "H6";
                    break;
                case "H3":
                    h1 = "H3";
                    h2 = "H4";
                    h3 = "H5";
                    h4 = "H6";
                    h5 = "H7";
                    break;
                case "H4":
                    h1 = "H4";
                    h2 = "H5";
                    h3 = "H6";
                    h4 = "H7";
                    h5 = "H8";
                    break;
                }
            }

            var ret_li;
            var h_ol;
            /* wrapper: ul ( in the template, outside this code ) */
            /* h1: layer 1: li - a */
            /* h2: layer 2: ul - li - a */
            /* h3: layer 3: ul - ul - li - a */
            /* h4: layer 4: ul - ul - ul - li - a */
            /* h5: layer 5: ul - ul - ul - ul - li - a */
            h = $this.get(0).tagName;
            switch(h) {
            case h1:
                h_cnt[0] ++;
                if (h_cnt[0] > 1)
                  h_cnt.fill(0, 1, h_cnt.length);
                h_ol = h_cnt.slice(0, 1);

                h_id[0] = tocid_prefix.concat(h_ol);
                console.log("h_id[0]: " + h_id[0]);

                $("<i class='icon-fixed-width icon-" + icon_close +"' onclick=\"click_toc('#" + "".concat(h_id[0], "','", icon_open, "','", icon_close) + "')\"></i>").prependTo(item_a);
                var li_a = $("<li id='" + h_id[0] + "'></li>").append(item_a);

                ret_li = li_a;
                break;
            case h2:
                h_cnt[1] ++;
                if (h_cnt[1] > 1)
                  h_cnt.fill(0, 2, h_cnt.length);
                h_ol = h_cnt.slice(0, 2);

                hid[1] = h_id[0].concat(tocid_suffix);
                h_id[1] = hid[1].concat("-", h_cnt[1]);
                console.log("h_id[1]: " + h_id[1]);

                $("<i class='icon-fixed-width icon-" + icon_close +"' onclick=\"click_toc('#" + "".concat(h_id[1], "','", icon_open, "','", icon_close) + "')\"></i>").prependTo(item_a);
                var li_a = $("<li id='" + h_id[1] +"'></li>").append(item_a);
                if (h_cnt[1] > 1)
                  var nav_li_a = $("#" + hid[1]).append(li_a);
                else
                  var nav_li_a = $("<ul class='nav' id='" + hid[1] +"'></ul>").append(li_a);

                ret_li = nav_li_a;
                break;
            case h3:
                h_cnt[2] ++;
                if (h_cnt[2] > 1)
                  h_cnt.fill(0, 3, h_cnt.length);
                h_ol = h_cnt.slice(0, 3);

                hid[2] = h_id[1].concat(tocid_suffix);
                h_id[2] = hid[2].concat("-", h_cnt[2]);
                console.log("h_id[2]: " + h_id[2]);

                $("<i class='icon-fixed-width icon-" + icon_close +"' onclick=\"click_toc('#" + "".concat(h_id[2], "','", icon_open, "','", icon_close) + "')\"></i>").prependTo(item_a);
                var li_a = $("<li id='" + h_id[2] +"'></li>").append(item_a);
                if (h_cnt[2] > 1)
                  var nav_li_a = $("#" + hid[2]).append(li_a);
                else
                  var nav_li_a = $("<ul class='nav' id='" + hid[2] +"'></ul>").append(li_a);

                var nav_nav_li_a = $("#" + hid[1]).append(nav_li_a);

                ret_li = nav_nav_li_a;

                break;
            case h4:
                h_cnt[3] ++;
                if (h_cnt[3] > 1)
                  h_cnt.fill(0, 4, h_cnt.length);
                h_ol = h_cnt.slice(0, 4);

                hid[3] = h_id[2].concat(tocid_suffix);
                h_id[3] = hid[3].concat("-", h_cnt[3]);
                console.log("h_id[3]: " + h_id[3]);

                $("<i class='icon-fixed-width icon-" + icon_close +"' onclick=\"click_toc('#" + "".concat(h_id[3], "','", icon_open, "','", icon_close) + "')\"></i>").prependTo(item_a);
                var li_a = $("<li id='" + h_id[3] +"'></li>").append(item_a);
                if (h_cnt[3] > 1)
                  var nav_li_a = $("#" + hid[3]).append(li_a);
                else
                  var nav_li_a = $("<ul class='nav' id='" + hid[3] +"'></ul>").append(li_a);

                var nav_nav_li_a = $("#" + hid[2]).append(nav_li_a);

                var nav_nav_nav_li_a = $("#" + hid[1]).append(nav_nav_li_a);
                ret_li = nav_nav_nav_li_a;

                break;
            case h5:
                h_cnt[4] ++;
                h_ol = h_cnt.slice(0, 5);

                hid[4] = h_id[3].concat(tocid_suffix);
                h_id[4] = hid[4].concat("-", h_cnt[4]);
                console.log("h_id[4]: " + h_id[4]);

                $("<i class='icon-fixed-width icon-" + icon_close +"' onclick=\"click_toc('#" + "".concat(h_id[4], "','", icon_open, "','", icon_close) + "')\"></i>").prependTo(item_a);
                var li_a = $("<li id='" + h_id[4] +"'></li>").append(item_a);
                if (h_cnt[4] > 1)
                  var nav_li_a = $("#" + hid[4]).append(li_a);
                else
                  var nav_li_a = $("<ul class='nav' id='" + hid[4] +"'></ul>").append(li_a);

                var nav_nav_li_a = $("#" + hid[3]).append(nav_li_a);
                var nav_nav_nav_li_a = $("#" + hid[2]).append(nav_li_a);
                var nav_nav_nav_nav_li_a = $("#" + hid[1]).append(nav_nav_nav_li_a);
                ret_li = nav_nav_nav_nav_li_a;
                break;
            }

            $(this).prepend("<ahead>" + h_ol.join('.') + "</ahead> ");

            if(!ret_li) {
                /* do nothing */
            } else {
                ultoc.append(ret_li);
            }

            node_num ++;
        });  /* end of each */

        /* show the table of content */
        if (node_num > 0)
	    toc_widget.show();

    } /* end of createToc:function() */
};


jQuery(function($) {
    $(document).ready( function() {
        /* Generate the side navigation `ul` elements */
        Toc.createToc($("#toc_widget_content"), $("#main_content_container"), $("#toc_widget"));

        /* caculate affixing */
        Toc.setTocAffixing();
    });
});
