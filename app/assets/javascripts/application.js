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
//= require turbolinks
//= require tinymce
//= require jquery
//= require bootstrap-sprockets
//= require bootbox
//= require moment
//= require_tree .

$(document).on('load turbolinks:load', function(){
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
  if($form.find("input[type='radio']:checked").length != 0){
    $form[0].submit();
  }else{
    bootbox.alert({
      size: "small",
      message: "Please select one of the options",
      className: "alert alert-danger"
    });
  }
});

function set_time(){
  var seconds = seconds_elapsed;
  var minutes = parseInt(seconds / 60);
  var hours = parseInt(minutes / 60);
  var sec = 0;
  if(hours == 0){
    sec = seconds - (minutes * 60);
  }else{
    minutes = minutes - (hours * 60);
    sec = seconds - (minutes * 60) - (hours * 60 * 60);
  }
  var ssec = sec <= 9 ? "0" + sec.toString() : sec.toString();
  var smin = minutes <= 9 ? "0" + minutes.toString() : minutes.toString();
  var shour = hours <= 9 ? "0" + hours.toString() : hours.toString();
  seconds_elapsed = seconds_elapsed - 1;
  $("#timer").html(shour + ":" + smin + ":" + ssec);
  if(seconds_elapsed == -1){
    clearInterval(window.timer_interval)
  }
}
