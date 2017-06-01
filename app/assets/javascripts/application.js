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
//= require_tree .

$(document).on("ready", function(){
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