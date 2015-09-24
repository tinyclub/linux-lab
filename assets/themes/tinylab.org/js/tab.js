;(function($) {

	/**
	 * 公共函数: 初始化tab出发事件
	 */
	function init_tab_trigger_event(container,opts) {
		$(container).find('.tab_header li').on(opts.trigger_event_type, function () {
			$(container).find('.tab_header li').removeClass('active');
			$(this).addClass('active');

			$(container).find('.tab_content div').hide();
			$(container).find('.tab_content div').eq($(this).index()).show();

			opts.change($(this).index());
		})
	}

	/**
	 * 公共函数: 初始化tab出发事件
	 */
	function init_with_config(opts) {
		// 调用私有函数
		_init_aaa_with_config(opts);

		// 调用私有函数
		_init_bbb_with_config(opts);

		// 调用私有函数
		_init_ccc_with_config(opts);
	}

	/**
	 * 私有函数
	 */
	function _init_aaa_with_config(opts) {

	}

	function _init_bbb_with_config(opts) {

	}

	function _init_ccc_with_config(opts) {

	}

	$.fn.tab = function(options) {
		// 将defaults 和 options 参数合并到{}
		var opts = $.extend({},$.fn.tab.defaults,options);

		return this.each(function() {
			var obj = $(this);

			// 根据配置进行初始化
			init_with_config(opts);

			// 初始化tab出发事件
			init_tab_trigger_event(obj,opts);
		});
		// each end
	}

	//定义默认
	$.fn.tab.defaults = {
		trigger_event_type:'mouseover', //mouseover | click
	    change: function(index) {
			/* console.log('current index = ' + index); */
		}
	};

})(jQuery);

$(function(){
       $('.tab_mouseover').tab({
	       trigger_event_type:'mouseover', //mouseover | click 默认是click
       });
});
