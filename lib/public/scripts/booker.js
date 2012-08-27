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

  $.ajax({
    type: "POST",
    url: REST + "reservations",
    data: {
      email: document.getElementById("email").value,
      roomid: document.getElementById("uuid").value,
      title: document.getElementById("title").value,
      details: document.getElementById("details").value,
      start: document.getElementById("start").value,
      duration: document.getElementById("duration").value
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


function check_token() {

  if(!is_authenticated()) {
    $("#email").removeClass("hidden"); 
  }
  else if( !$("#email").is(".hidden") ) {
    $("#email").addClass("hidden");
  }

} // check_token

