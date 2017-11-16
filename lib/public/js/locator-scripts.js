function change_voting(element) {
      var isChecked = $(element).is(':checked');
      var selectedData;
      var $switchLabel = $('.switch-label');
      var checkboxId = $(element).attr('id');
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
             //console.log(result.responseText);
       });

}

var counter = 1;
function counter_fields() {
  
  counter++;
  var objTo = document.getElementById('counter_fields')
  var divtest = document.createElement("div");
  divtest.setAttribute("class", "form-group removeclass"+counter);
  var rdiv = 'removeclass'+counter;
  divtest.innerHTML = '<div class="form-group"><label class="control-label col-lg-2" for="content">Ort</label><div class="add-location-txtfield col-lg-10"><input type="text" class="form-control" id="location'+ counter +'" name="location'+ counter +'" value="" ></div><label class="control-label col-lg-2" for="content">URL</label><div class="add-location-txtfield col-lg-10"> <input type="text" class="form-control" id="url'+ counter +'" name="url'+ counter +'" value=""></div><div  class="add-location-btn"> <button class="btn btn-danger" type="button" onclick="remove_counter_fields('+ counter +');"> <span class="glyphicon glyphicon-minus" aria-hidden="true"></span> </button></div></div></div></div><div class="clear"></div>';

  objTo.appendChild(divtest)
}
function remove_counter_fields(rid) {
  $('.removeclass'+rid).remove();
}
