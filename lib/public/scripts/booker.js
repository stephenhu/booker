const REST = "http://172.16.97.175:4567/rest/"

function redirect( resource, id ) {
  window.location.replace(window.location.protocol + "//" +
    window.location.host + '/' + resource + '/' + id);
} // redirect


function vote() {
 if( !is_authenticated() ) {
   authenticate("user2@gmail.com");
 }
 else {
   // check vote status
 }
} // vote 


function is_authenticated() {

  if( $.cookie("topics") == null ) {
    return false;
  }
  else {
    return true;
  }

} // is_authenticated


function authenticate(email) {
  $.ajax({
    type: "POST",
    url: REST + "authenticate",
    data: { email: email },
    success: function(response) {
      alert(response);
      //$.cookie( "topics", response );
    },
    dataType: "json"
  });
} // authenticate

