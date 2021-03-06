// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require tinymce
//= require jquery
//= require bootstrap-sprockets
//= require bootbox
//= require moment
//= require jquery-ui
//= require jquery.mCustomScrollbar
//= require_tree .

function device_warning(){
  if(is_devise_mobile == true){
    var show_device_warning = false;
    if($(".instruction-form-1").length != 0){
      show_device_warning = true;
      device_warning_message = "Although we have worked very hard to provide similar experience on mobile devices too, but still we recommend to use desktop pcs or laptops for attempting the test!";
    }else if(charts_page == true){
      show_device_warning = true;
      device_warning_message = "Graphical representations of your performance are best visible on desktop or laptops!";
    }
    if(show_device_warning == true){
      bootbox.alert({
        size: "small",
        title: "Device alert!",
        message: device_warning_message,
        className: ""
      }).find('.modal-content').css({
        'margin-top': function (){
          var w = $( window ).height();
          var b = $(".modal-dialog").height();
          var h = (w-b)/2 - 180;
          return h+"px";
        }
      });
    }
  }
}
$(document).on('ready', function(){
  var scrollbar_options = {
    theme:"dark",
    scrollbarPosition: "inside",
    scrollInertia: 100
  }
  $(".passage-question-left").mCustomScrollbar(scrollbar_options);
  $(".passage-question-right").mCustomScrollbar(scrollbar_options);
  $(".scrolling-box").mCustomScrollbar(scrollbar_options);

  $(".body-inner").css("height", $(window).height());
  var scrollbar = Scrollbar.init($(".body-inner")[0], { speed: 2, alwaysShowTracks: true });
  device_warning();
  $("p").each(function(){
    var $p = $(this);
    if($p.text() == ""){
      $p.remove();
    }
  });
  $(".nested-form-fields").find("input, select, textarea, select").each(function(){
    var name = $(this).attr("name");
    var regexp = /\[\d+\]/;
    var splitted_name = name.split(regexp);
    var last_ele = splitted_name[splitted_name.length - 1];
    regexp = new RegExp("\\[[0-9]+\]" + (RegExp.escape(last_ele)))
    name = name.replace(regexp, "[]" + last_ele)
    // name = name.split("").reverse().join("").replace(regexp, "[]");
    $(this).attr("name", name);
  });

  if($("#passage_question_count").length != 0){
    if(parseInt($("#passage_question_count").val()) == 3){
      $("#passage_questions_attributes_3_description").closest(".panel").hide();
    }else{
      $("#passage_questions_attributes_3_description").closest(".panel").show();
    }
  }
  $("#passage_question_count").on("change", function(){
    if(parseInt($("#passage_question_count").val()) == 3){
      $("#passage_questions_attributes_3_description").closest(".panel").hide();
    }else{
      $("#passage_questions_attributes_3_description").closest(".panel").show();
    }
  });
});



RegExp.escape= function(s) {
    return s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
};

$(document).on("submit", ".paypal-form", function(e){
  e.preventDefault();
  var $form = $(this)
  var payment_id = $form.data("paymentid");
  $.ajax({
    url: payment_init_url,
    type: "post",
    data: {id: payment_id},
    success: function(retdata){
      if(retdata.status == "success"){
        $form[0].submit();
      }
    }
  })
});

$(document).on("submit", ".candidate-question-form", function(e){
  e.preventDefault();
  var $form = $(this);
  if($form.hasClass("sol-mode")){
    window.location.href = $form.attr("action");
  }else{
    if($form.find("input[type='radio']:checked").length != 0){
      var confirm_message = ""
      if($form.hasClass("question-no-41")){
        confirm_message = "Click yes to finish the test.";
      }else{
        confirm_message = "Click yes to confirm your answer and continue to the next question.";
      }
      if(true){
        bootbox.confirm({
          size: "small",
          title: "Answer Confirmation",
          message: confirm_message,
          buttons: {
            cancel: {
              label: 'No',
              className: 'btn btn-danger'
            },
            confirm: {
              label: 'Yes',
              className: 'btn btn-primary'
            }
          },
          callback: function (result) {
            if(result){
              $(".submit-btn").hide();
              $(".wait-btn").show();
              $form[0].submit();
            }
          }
        }).find('.modal-content').css({
          'margin-top': function (){
            var w = $( window ).height();
            var b = $(".modal-dialog").height();
            var h = (w-b)/2 - 180;
            return h+"px";
          }
        });
      }else{
        $form[0].submit();
      }
    }else{
      bootbox.alert({
        size: "small",
        title: "Answer Required",
        message: "You can not continue with this question unanswered.",
        className: ""
      }).find('.modal-content').css({
        'margin-top': function (){
          var w = $( window ).height();
          var b = $(".modal-dialog").height();
          var h = (w-b)/2 - 180;
          return h+"px";
        }
      });
    }
  }
});

function set_time(){
  var seconds = seconds_elapsed;
  var minutes = parseInt(seconds / 60);
  var hours = parseInt(minutes / 60);
  var sec = 0;
  // if(hours == 0){
  //   sec = seconds - (minutes * 60);
  // }else{
  //   minutes = minutes - (hours * 60);
  //   sec = seconds - (minutes * 60) - (hours * 60 * 60);
  // }
  sec = seconds - (minutes * 60);
  var ssec = sec <= 9 ? "0" + sec.toString() : sec.toString();
  var smin = minutes <= 9 ? "0" + minutes.toString() : minutes.toString();
  // var shour = hours <= 9 ? "0" + hours.toString() : hours.toString();
  seconds_elapsed = seconds_elapsed - 1;
  if(seconds_elapsed == -1){
    bootbox.alert({
      size: "small",
      title: "Time finished",
      message: "Your time is finished, click OK to proceed",
      className: "",
      callback: function () {
        $(".test-finish")[0].submit();
      }
    }).find('.modal-content').css({
      'margin-top': function (){
        var w = $( window ).height();
        var b = $(".modal-dialog").height();
        var h = (w-b)/2 - 180;
        return h+"px";
      }
    });
    clearInterval(window.timer_interval);
  }else{
    $("#timer").html(smin + ":" + ssec);
  }
}

// setTimeout(function(){
//   $(window).on("mouseleave", function(){

//   });
// }, 5000);