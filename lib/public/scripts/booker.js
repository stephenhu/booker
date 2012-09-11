const REST = "http://172.16.97.176:4567/rest/"

function redirect( resource, id, args ) {

  if( id.length == 0 ) {
    window.location.replace(window.location.protocol + "//" +
      window.location.host + '/' + resource + '?' + args );
  }
  else {
    window.location.replace(window.location.protocol + "//" +
      window.location.host + '/' + resource + '/' + id);
  }

} // redirect


function set_duration(d) {

  da = { "0.5" : [ "d1", 1 ], "1.0" : [ "d2", 2 ], "1.5" : [ "d3", 3 ],
    "2.0" : [ "d4", 4 ], "3.0" : [ "d5", 5 ], "4.0" : [ "d6", 6 ],
    "12.0" : [ "d7", 7 ] };

  if( da[d] != "0.0" && da[d] != null ) {
    document.getElementById("d0").removeAttribute("selected");
    document.getElementById(da[d][0]).setAttribute( "selected", "selected" );
    document.getElementById("duration").selectedIndex = da[d][1];
  }

} // set_duration


function reserve() {

  invalid = false;

  if(!is_authenticated()) {
    if( document.getElementById("email").value.length == 0 ) {
      $("#email-error").removeClass("hidden");
      invalid = true;
    }
    else if( !$("#email-error").is(".hidden") ) {
      $("#email-error").addClass("hidden");
    }
  }

  if( document.getElementById("title").value.length == 0 ) {
    $("#title-error").removeClass("hidden");
    invalid = true;
  }
  else if( !$("#title-error").is(".hidden") ) {
    $("#title-error").addClass("hidden");    
  }

  if( document.getElementById("invitees").value.length == 0 ) {
    $("#invitees-error").removeClass("hidden");
    invalid = true;
  }
  else if( !$("#invitees-error").is(".hidden") ) {
    $("#invitees-error").addClass("hidden");
  }

  if( document.getElementById("duration").value == "select duration" &&
    !document.getElementById("recur5").checked ) {
    $("#duration-error").removeClass("hidden");
    invalid = true;
  }
  else if( !$("#duration-error").is(".hidden") ) {
    $("#duration-error").addClass("hidden");
  }
 
  if( document.getElementById("details").value.length == 0 ) {
    $("#details-error").removeClass("hidden");
    invalid = true;
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

  if(invalid) {
    return;
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


function set_menu(active) {

  $("#floors").removeClass("active");
  $('#'+active).addClass("active");

} // set_menu


function check_token() {

  if(!is_authenticated()) {
    $("#email").removeClass("hidden"); 
  }
  else if( !$("#email").is(".hidden") ) {
    $("#email").addClass("hidden");
  }

} // check_token

