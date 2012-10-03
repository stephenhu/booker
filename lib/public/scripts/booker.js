const REST = "http://172.16.63.128:4567/rest/"

// args: string representation of get parameters
//   e.g. row=20&column=12&age=23
function redirect( resource, id, args ) {

  if( id.length == 0 ) {

    if( args.length != 0 ) {
      window.location.replace(window.location.protocol + "//" +
        window.location.host + "/" + resource + "?" + args );

    }
    else {
      window.location.replace(window.location.protocol + "//" +
        window.location.host + "/" + resource );
    }

  }
  else {

    if( args.length != 0 ) {

      window.location.replace(window.location.protocol + "//" +
        window.location.host + "/" + resource + "/" + id + "?" + args );

    }
    else {
      window.location.replace(window.location.protocol + "//" +
        window.location.host + "/" + resource + "/" + id);
    }

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


function reserve( reserveid, update ) {

  var invalid     = false;

  var email       = document.getElementById("email").value;
  var title       = document.getElementById("title").value;
  var uuid        = document.getElementById("uuid").value;
  var invitees    = document.getElementById("invitees").value;
  var duration    = document.getElementById("duration").value;
  var details     = document.getElementById("details").value;
  var start_date  = document.getElementById("datepicker1").value;
  var end_date    = document.getElementById("datepicker2").value;
  var start       = document.getElementById("start").value;

  var recur0      = document.getElementById("recur0");
  var recur1      = document.getElementById("recur1");
  var recur2      = document.getElementById("recur2");
  var recur3      = document.getElementById("recur3");
  var recur4      = document.getElementById("recur4");

  var emails      = new Array();

  if(!is_authenticated()) {
    if( email.length == 0 ) {
      $("#email-error").removeClass("hidden");
      invalid = true;
    }
    else if( !$("#email-error").is(".hidden") ) {
      $("#email-error").addClass("hidden");
    }
  }

  if( title.length == 0 ) {
    $("#title-error").removeClass("hidden");
    invalid = true;
  }
  else if( !$("#title-error").is(".hidden") ) {
    $("#title-error").addClass("hidden");    
  }

  if( invitees.length == 0 ) {
    $("#invitees-error").removeClass("hidden");
    invalid = true;
  }
  else {

    emails = invitees.split(",");

    for( var i = 0; i < emails.length; i++ ) {

      e = emails[i].trim();

      if(!valid_email(e)) {
        $("#invalid-email-error").removeClass("hidden");
        $("#invalid-email-domain-error").addClass("hidden");
        $("#invitees-error").addClass("hidden");
        invalid = true;
        break;
      }

      if(!valid_email_domain(e)) {
        $("#invalid-email-domain-error").removeClass("hidden");
        $("#invitees-error").addClass("hidden");
        $("#invalid-email-error").addClass("hidden");
        invalid = true;
        break;
      }
    }

    if( !$("#invitees-error").is(".hidden") ) {
      $("#invitees-error").addClass("hidden");
    }

  }

  if( duration == "select duration" &&
    !document.getElementById("recur5").checked ) {
    $("#duration-error").removeClass("hidden");
    invalid = true;
  }
  else if( !$("#duration-error").is(".hidden") ) {
    $("#duration-error").addClass("hidden");
  }
 
  if( details.length == 0 ) {
    $("#details-error").removeClass("hidden");
    invalid = true;
  }
  else if( !$("#details-error").is(".hidden") ) {
    $("#details-error").addClass("hidden");
  }

  if( recur0.checked ) {
    recurring = recur0.value;
  }
  else if( recur1.checked ) {
    recurring = recur1.value;
  }
  else if( recur2.checked ) {
    recurring = recur2.value;
  }
  else if( recur3.checked ) {
    recurring = recur3.value;
  }
  else if( recur4.checked ) {
    recurring = recur4.value;
  }

  if(invalid) {
    return;
  }

  if(update) {
  
    $.ajax({
      type: "PUT",
      url: REST + "reservations/" + reserveid,
      data: {
        email: email,
        roomid: uuid,
        title: title,
        details: details,
        start: start_date,
        end: end_date,
        time: start,
        duration: duration,
        recurring: recurring,
        invitees: invitees
      },
      success: function(response) {
        alert(response);
        window.location = "/users"; 
      },
      error: function(response) {
        alert(response);
        alert("Unable to update reservation at this time.");
      },
      dataType: "json"
    });

  }
  else {

    $.ajax({
      type: "POST",
      url: REST + "reservations",
      data: {
        email: email,
        roomid: uuid,
        title: title,
        details: details,
        start: start_date,
        end: end_date,
        time: start,
        duration: duration,
        recurring: recurring,
        invitees: invitees
      },
      success: function(response) {
        window.location = "/users";
      },
      error: function(response) {
        alert("Unable to create reservation at this time.");
      },
      dataType: "json"
    });

  }
  
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
      redirect( "users", "", "" ); 
    },
    dataType: "json"
  });
} // authenticate


function set_menu(active) {

  if(active) {
    $("#floors").removeClass("active");
    $('#'+active).addClass("active");
  }
  else {
    $("#floors").removeClass("active");
  }

} // set_menu


function check_token() {

  if(!is_authenticated()) {
    $("#email").removeClass("hidden"); 
  }
  else if( !$("#email").is(".hidden") ) {
    $("#email").addClass("hidden");
  }

} // check_token


function valid_email(email) {
 
  var regex =
    /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  return regex.test(email);

} // valid_email


function valid_email_domain(email) {

  if( email.search("emc.com") != -1 || email.search("mozy.com" ) != -1 ||
    email.search("rbcon.com") != -1 || email.search("vmware.com") != -1 ) {
    return true;
  }
  else {
    return false;
  }

} // valid_email_domain


function cancel_meeting(recurring_flag) {

  rid = document.getElementById("recurringid").value;

  $.ajax({
    type: "DELETE",
    url: REST + "reservations/" + rid,
    data: {
      recurring: recurring_flag
    }
  });
 

} // cancel_meeting


function init_cancel_dialog() {

  $("#cancel-dialog").dialog({
    autoOpen: false,
    height: 250,
    width: 650,
    modal: true,
    buttons: {
      "Cancel": function() {
        $(this).dialog("close");
      }
    }
  });

} // init_cancel_dialog


function open_cancel_dialog(rid) {

  document.getElementById("recurringid").value = rid;

  $("#cancel-dialog").dialog("open");

} // open_cancel_dialog


function set_recurring(val) {

  if(val) {

    c = document.getElementById("recur" + val);
    c.checked = true; 

  }

} // set_recurring 

