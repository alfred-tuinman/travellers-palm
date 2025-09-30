/* filter */

jQuery("#themes :checkbox").click(function() {
 $("article").hide();
 $("#themes :checkbox:checked").each(function() {
   $("." + $(this).val()).show();
 });
 $("#ideas :checkbox:checked").each(function() {
   $("." + $(this).val()).show();
 });
});


// google site search
(function() {
  var cx = '013743661630190283677:rkjcf6riyd8';
  var gcse = document.createElement('script'); gcse.type = 'text/javascript'; gcse.async = true;
  gcse.src = (document.location.protocol == 'https:' ? 'https:' : 'http:') + '//www.google.com/cse/cse.js?cx=' + cx;
  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(gcse, s);
})();