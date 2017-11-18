function change_voting(element) {
      var isChecked = $(element).is(':checked');
      var selectedData;
      var $switchLabel = $('.switch-label');
      var checkboxId = $(element).attr('id');
      // console.log('ID: '+ checkboxId);
      // console.log('isChecked: ' + isChecked);
      // console.log('Selected data: ' + selectedData);

      // if(isChecked) {
      //   selectedData = $switchLabel.attr('data-on');
      // } else {
      //   selectedData = $switchLabel.attr('data-off');
      // }
      //

      posting = $.post( "cast_activity", { vote: checkboxId, isChecked: isChecked} );
      posting.done(function(response, textStatus, jqXHR){
        //nothing to do here
      });
      posting.fail(function(response, textStatus, jqXHR) {
          document.getElementById(checkboxId).click();
            //$('#alert_max_votes').fadeIn();
            $('#alert_max_votes').slideDown();
      });
}

function change_location(element, activity) {
      var isChecked = $(element).is(':checked');
      var checkboxId = $(element).attr('id');

      posting = $.post( "cast_location", { loc: checkboxId, isChecked: isChecked, activity: activity} );
      posting.done(function(response, textStatus, jqXHR){
        //nothing to do here
      });
      posting.fail(function(response, textStatus, jqXHR) {
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
