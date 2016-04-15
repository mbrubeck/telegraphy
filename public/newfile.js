$(document).ready(function() {
  $('.modal-trigger').leanModal();

  $('#name').on('input', function() {
    console.log($('#name').val());
    if ($(this).val() == "") {
      if (!$('#newFileBtn').hasClass('disabled')) {
        $('#newFileBtn').addClass('disabled');
      }
    } else {
      $('#newFileBtn').removeClass('disabled');
    }
  });
});
