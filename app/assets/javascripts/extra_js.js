$(document).on("ready", function(){
  $('[data-toggle="slide-collapse"]').on('click', function() {
    if($(".nav.navbar-nav").css("width") == "0px"){
      $(".nav.navbar-nav").css("width", "100vw");
      $(".collapse.navbar-collapse").css("width", "100vw");
    }
    if($(".nav.navbar-nav").css("height") == "0px"){
      $(".collapse.navbar-collapse").css("height", "70vh");
    }
    else{
      // $(".collapse.navbar-collapse").css("height", "");
    }
    $navMenuCont = $($(this).data('target'));
    $navMenuCont.animate({'width':'toggle'}, 500, 'easeOutBounce');
  });
  $(".nav-tabs li[role='presentation'] a").on("click", function(e){
    // $(".nav-tabs li[role='presentation']").removeClass("active");
    // $(".tab-pane").removeClass("active");
    // var $tab_panel = $($(this).attr("href"));
    // $tab_panel.addClass("active");
    // e.preventDefault();
    $(this).tab("show");
  });
  $(".modal-trigger-forgot-password").on("click", function(e){
    $(".nav-tabs li[role='presentation']").removeClass("active");
    $("#login-modal").modal("show");
    $(this).tab("show");
  });
});

$(window).on("resize", function(){
  if($(this).width() > 768){
    $(".nav.navbar-nav").css("width", "");
    $(".collapse.navbar-collapse").css("width", "");
    $(".nav.navbar-nav").css("height", "");
  }
});

// window.exit_intent_shown = false;
// $(document).on("mouseleave", function(e){
//   if((e.clientX >= 1100 || e.clientX <= 300) && !window.exit_intent_shown){
//     window.exit_intent_shown = true
//     $("#exit-modal-1").modal("show");
//   }
// });
