$(document).on("ready", function(){
  $('[data-toggle="slide-collapse"]').on('click', function() {
    $navMenuCont = $($(this).data('target'));
    $navMenuCont.animate({'width':'toggle'}, 10);
  });
  $(".nav-tabs li[role='presentation'] a").on("click", function(e){
    // $(".nav-tabs li[role='presentation']").removeClass("active");
    // $(".tab-pane").removeClass("active");
    // var $tab_panel = $($(this).attr("href"));
    // $tab_panel.addClass("active");
    // e.preventDefault();
    $(this).tab("show");
  });
});
