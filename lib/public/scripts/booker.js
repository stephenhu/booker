const REST = "http://172.16.97.175:4567/rest/"

function redirect( resource, id ) {
  window.location.replace(window.location.protocol + "//" +
    window.location.host + '/' + resource + '/' + id);
} // redirect


function reserve() {

  if(!is_authenticated()) {
    if( document.getElementById("email").value.length == 0 ) {
      $('#email-error').removeClass('hidden');
    }
    else if( !$("#email-error").is('.hidden') ) {
      $("#email-error").addClass("hidden");
    }
  }

  if( document.getElementById("title").value.length == 0 ) {
    $("#title-error").removeClass("hidden");
    return;
  }
  else if( !$("#title-error").is(".hidden") ) {
    $("#title-error").addClass("hidden");    
  }

  if( document.getElementById("duration").value == "select duration" ) {
    $("#duration-error").removeClass("hidden");
    return;
  }
  else if( !$("#duration-error").is(".hidden") ) {
    $("#duration-error").addClass("hidden");
  }
 
  if( document.getElementById("details").value.length == 0 ) {
    $("#details-error").removeClass("hidden");
    return;
  }
  else if( !$("#details-error").is(".hidden") ) {
    $("#details-error").addClass("hidden");
  }

  if( document.getElementById("recur1").checked ) {
    recurring = document.getElementById("recur1").value;
  }
  else if( document.getElementById("recur2").checked ) {
    recurring = document.getElementById("recur2").value;
  }
  else if( document.getElementById("recur3").checked ) {
    recurring = document.getElementById("recur3").value;
  }
  else if( document.getElementById("recur4").checked ) {
    recurring = document.getElementById("recur4").value;
  }
  else if( document.getElementById("recur5").checked ) {
    recurring = document.getElementById("recur5").value;
  }

  $.ajax({
    type: "POST",
    url: REST + "reservations",
    data: {
      email: document.getElementById("email").value,
      roomid: document.getElementById("uuid").value,
      title: document.getElementById("title").value,
      details: document.getElementById("details").value,
      start: document.getElementById("datepicker1").value,
      end: document.getElementById("datepicker2").value,
      time: document.getElementById("start").value,
      duration: document.getElementById("duration").value,
      recurring: recurring
    },
    success: function(response) {
      alert(response);
    },
    dataType: "json"
  });
  

} // reserve


function is_authenticated() {

  if( $.cookie("booker") == null ) {
    return false;
  }
  else {
    return true;
  }

} // is_authenticated


function enable_element(id) {
  $('#' + id).removeAttr("disabled");
} // enable_element


function disable_element(id) {
  $('#'+id).attr( "disabled", "disabled" );
} // disable_element


function single_day() {

  enable_element("duration");
  disable_element("datepicker2");

} // single_day


function multi_day() {

  enable_element("datepicker2");
  disable_element("duration");

} // multi_day



// TODO: probably can be discarded
function authenticate() {
  $.ajax({
    type: "POST",
    url: REST + "authenticate",
    data: { email: document.getElementById("email").value },
    success: function(response) {
      alert("authenticate " + response);
    },
    dataType: "json"
  });
} // authenticate


// TODO: probably can be discarded
function check_token() {

  if(!is_authenticated()) {
    $("#email").removeClass("hidden"); 
  }
  else if( !$("#email").is(".hidden") ) {
    $("#email").addClass("hidden");
  }

} // check_token

