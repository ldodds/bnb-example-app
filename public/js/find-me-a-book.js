
$(document).ready(function(){

	function findTitle() {
		$("#title").empty();		
		$.get("/title", 
			{"isbn": $("#isbn").val() 
			},
			function(data) {
		      if (data.error) {
		    	  $("#title").append("Unknown ISBN!");
		      }
		      else {
		    	  $("#title").append(data.title);
		    	  find("author", "/by-author");
				  find("related", "/related");		    	  
		      }
			}			
		);			
	}
	
	function find(prefix, path) {
		$("#" + prefix +"-results").hide();
		$("#" + prefix +"-results").empty();
		$("#" + prefix).append("<img id='indicator' valign='middle' src='/img/ajax-loader.gif'/>");
		
		$.get(path, 
			{"isbn": $("#isbn").val() 
			},
			function(data) {
			  $("#indicator").remove();
			  if (data.results.length == 0) {
				  $("#" +prefix).append("<p>No books found</p>");
			  }
			  $.each(data.results, function(index, value) {				  
				  $("#"+prefix+"-results").append(
						  "<li><a class='book-link' href='http://www.librarything.com/isbn/" + value.isbn + "'>" 
						  + value.title + "</a></li>");
			  });		  
			  $("#" + prefix+ "-results").show();
			}			
		);			
	}
	
	$("#find-book").click(function() {
		    findTitle();
			return false;
	});
	
});