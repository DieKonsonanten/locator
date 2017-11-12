(function() {
  $(document).ready(function() {
    $('.switch-input').on('change', function() {
      var isChecked = $(this).is(':checked');
      var selectedData;
      var $switchLabel = $('.switch-label');
      var checkboxId = $(this).attr('id');
      // console.log('ID: '+ checkboxId);
      // console.log('isChecked: ' + isChecked); 
      


      if(isChecked) {
        selectedData = $switchLabel.attr('data-on');
      } else {
        selectedData = $switchLabel.attr('data-off');
      }

      // console.log('Selected data: ' + selectedData);
      
      $.post("cast", { vote: checkboxId, isChecked: isChecked},
           function(result) { 
       });
    });
  });

})();
