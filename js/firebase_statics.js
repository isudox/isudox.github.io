// 总数
var isudoxFirebase = new Firebase("https://isudox.firebaseio.com/");
// 明细由当前页面的url表示，将反斜线替换成下划线，并将中文decode出来
var current_url = decodeURI(window.location.pathname.replace(new RegExp('\\/|\\.', 'g'),"_"));
isudoxFirebase.child("sum").on("value", function(data) {
  var current_counter = data.val();
  if($("#sum_counter").length > 0  && current_counter > 1) {
     $("#sum_counter").html("&nbsp;|&nbsp;Total visit&nbsp;"+ current_counter +"&nbsp;times");
  };
});

// 获取明细，并将明细也展示在页面上
isudoxFirebase.child("detail/"+current_url).on("value", function(data) {
  var detail_counter = data.val();
	if($("#detail_counter").length > 0 && detail_counter > 1) {
		$("#detail_counter").html(
			"&nbsp;Page view&nbsp;"+ detail_counter +"&nbsp;times"
		);
	}
});

// 总数+1
isudoxFirebase.child("sum").transaction(function (current_counter) {
  return (current_counter || 0) + 1;
});
// 明细+1
isudoxFirebase.child("detail/"+current_url).transaction(function (current_counter) {
  return (current_counter || 0) + 1;
});
