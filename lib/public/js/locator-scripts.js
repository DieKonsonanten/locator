function change_voting(element) {
      var isChecked = $(element).is(':checked');
      var selectedData;
      var $switchLabel = $('.switch-label');
      var checkboxId = $(element).attr('id');

      posting = $.post( "cast_activity", { vote: checkboxId, isChecked: isChecked} );
      posting.done(function(response, textStatus, jqXHR){
        //nothing to do here
      });
      posting.fail(function(response, textStatus, jqXHR) {
          document.getElementById(checkboxId).click();
          document.getElementById('alert-danger-text').innerHTML = "Maximale Anzahl an Votes erreicht";
          $('#alert_danger').slideDown();
      });
}

function signup_user(element) {
  $('form[name=signup_form]').submit(function(){
  posting = $.post($(this).attr('action'), $(this).serialize() );
    posting.done(function(response, textStatus, jqXHR){
      var modal = $('#myModal');
      modal.find('.modal-header').text("Info");
      modal.find('.modal-body').text("Nach Absenden des Formulars muss dein Account durch einen Admin freigeschaltet werden. Die Admins werden per Mail über den neuen Account informiert und ihn schnellstmöglich freischalten. Du erhälst nach erfolgreicher Freischaltung eine Mail.");
      modal.modal();
      window.setTimeout(function(){window.location.href = "/login";}, 5000); 
      return false;
    });
    posting.fail(function(response, textStatus, jqXHR) {
      document.getElementById('alert-danger-text').innerHTML = "E-Mail-Addresse bereits vergeben!";
      $('#alert_danger').slideDown();
      return false;
    });
    return false;
  });
}

function change_location(element, activity) {
      var isChecked = $(element).is(':checked');
      var checkboxId = $(element).attr('id');

      posting = $.post( "cast_location", { loc: checkboxId, isChecked: isChecked, activity: activity} );
      posting.done(function(response, textStatus, jqXHR){
        
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
  divtest.innerHTML = '<div class="form-group"><label class="control-label col-lg-2" for="content">Ort</label><div class="add-location-txtfield col-lg-10"><input type="text" class="form-control" id="location'+ counter +'" name="location'+ counter +'" value="" ></div><label class="control-label col-lg-2" for="content">URL</label><div class="add-location-txtfield col-lg-10"> <input type="url" class="form-control" id="url'+ counter +'" name="url'+ counter +'" value="https://"></div><div  class="add-location-btn"> <button class="btn btn-danger" type="button" onclick="remove_counter_fields('+ counter +');"> <span class="glyphicon glyphicon-minus" aria-hidden="true"></span> </button></div></div></div></div><div class="clear"></div>';

  objTo.appendChild(divtest)
}
function remove_counter_fields(rid) {
  $('.removeclass'+rid).remove();
}

function forceLower(strInput) {
  strInput.value = strInput.value.toLowerCase();
}

function getRandomColor() {
  var letters = '0123456789ABCDEF';
  var color = '#';
  for (var i = 0; i < 6; i++) {
    color += letters[Math.floor(Math.random() * 16)];
  }
  return color;
}
