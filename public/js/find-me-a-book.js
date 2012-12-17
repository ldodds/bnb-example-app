$(document).ready(function(){

	/*
	 * Find the title of a book based on its ISBN
	 */
	function findTitle() {
		//empty the dynamically populated sections of the page
		$("#title").empty();
		$("#author-results").empty();
		$("#related-results").empty();
		
		//query the application to retrieve the ISBN
		$.get("/title", 
			{"isbn": $("#isbn").val() 
			},
			function(data) {
		      if (data.error) {
		    	  $("#title").append("Sorry, but we can't identify that ISBN :(");
		      }
		      else {
		    	  //if we've found a title, add it to the page and trigger
		    	  //the other ajax requests, one to find books by author
		    	  //and one to find by related
		    	  $("#title").append(data.title);
		    	  find("/by-author", "author");
				  find("/related", "related");		    	  
		      }
			}			
		);			
	}
	
	/*
	 * Function that will submit an AJAX request to a URL, sending an ISBN as a parameter
	 * 
	 * The server is indicated using the "path" parameter.
	 * 
	 * The response to the request will be a JSON document that includes a list of results
	 * Each result will have a title and an ISBN
	 * 
	 * The results are used to dynamically populated a list with links to LibraryThing.com
	 * The list to be populated is identified by the prefix parameter.
	 */
	function find(path, prefix) {
		
		//Add a loading indicator to indicate something is happening
		$("#" + prefix).append("<img id='indicator' valign='middle' src='/img/ajax-loader.gif'/>");
		
		//Perform the AJAX request to the desired service
		$.get(path, 
			{"isbn": $("#isbn").val() 
			},
			function(data) {
		      //remove the loading indicator
			  $("#indicator").remove();
			  if (data.results.length == 0) {
				  $("#" +prefix).append("<p>No books found</p>");
			  }
			  //loop through the results and build the LibryThing links
			  $.each(data.results, function(index, value) {				  
				  $("#"+prefix+"-results").append(
						  "<li><a class='book-link' href='http://www.librarything.com/isbn/" + value.isbn + "'>" 
						  + value.title + "</a></li>");
			  });		  
			}			
		);			
	}
	
	//bind a click handler to the submit button on the form that will call the 
	//findTitle function. This will then trigger additional AJAX requests if the
	//title is successfully found in the BNB.
	$("#find-book").click(function() {
		    findTitle();
			return false;
	});
	
});