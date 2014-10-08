require 'rubygems'
require 'sinatra/base'
require 'sparql/client'
require 'json'

class FindMeABook < Sinatra::Base
  
    #Configure application level options in Sinatra
    configure do |app|
      #support delivery of static files
      set :static, true    
      #configure location of views (templates) and static files
      set :views, File.dirname(__FILE__) + "/../views"
      set :public_folder, File.dirname(__FILE__) + "/../public"     
      enable :xhtml        
    end
    
    #Query to lookup the URI and title of a book
    #
    #Uses a limit to just return a single title if there are several
    #publications with the same ISBN
    FIND_BOOK=<<-EOL 
      PREFIX bibo: <http://purl.org/ontology/bibo/>
      PREFIX dct: <http://purl.org/dc/terms/>    
      SELECT ?book ?title WHERE {
        ?book bibo:isbn10 "?isbn";
          dct:title ?title.
      }      
      LIMIT 1
    EOL

    #Query to find more books by author(s)
    #
    #The ?isbn parameter is intended to be replaced with an actual
    #ISBN. The query will then find the author and all of their works
    #
    #The filter clause ensures that the results only contain new titles        
    FIND_BOOKS_BY_AUTHOR=<<-EOL 
      PREFIX bibo: <http://purl.org/ontology/bibo/>
      PREFIX blterms: <http://www.bl.uk/schemas/bibliographic/blterms#>
      PREFIX dct: <http://purl.org/dc/terms/>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>    
      
      SELECT DISTINCT ?otherTitle ?otherIsbn WHERE {
        ?book bibo:isbn10 "?isbn";
          dct:creator ?author;
          dct:title ?title.
      
        ?author foaf:name ?name;
          blterms:hasCreated ?otherBook.
      
        ?otherBook dct:title ?otherTitle;
            bibo:isbn10 ?otherIsbn.
      
        FILTER (?otherTitle != ?title)
      
      }      
      LIMIT 10
    EOL
        
    #Query to find related books by series
    #
    #The ?isbn parameter is intended to be replaced with an actual
    #ISBN. The query will then find if the book is in a series
    #
    #If it is in a series then other books from those series are
    #returned as recommendations
    FIND_RELATED_BY_SERIES=<<-EOL
      PREFIX bibo: <http://purl.org/ontology/bibo/>
      PREFIX blterms: <http://www.bl.uk/schemas/bibliographic/blterms#>
      PREFIX dct: <http://purl.org/dc/terms/>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>    
      
      SELECT ?otherTitle ?otherIsbn WHERE {
        ?book bibo:isbn10 "?isbn";
            dct:title ?title.
      
        ?series dct:hasPart ?book;
           dct:hasPart ?otherBook.
      
        ?otherBook dct:title ?otherTitle;
           bibo:isbn10 ?otherIsbn.
      
        FILTER (?otherTitle != ?title)
      }      
      LIMIT 10     
    EOL
    
    #Query to find related books by category
    #
    #The ?isbn parameter is intended to be replaced with an actual
    #ISBN. The query will then find other books in the same category    
    FIND_RELATED_BY_CATEGORY=<<-EOL 
      PREFIX bibo: <http://purl.org/ontology/bibo/>
      PREFIX blterms: <http://www.bl.uk/schemas/bibliographic/blterms#>
      PREFIX dct: <http://purl.org/dc/terms/>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>    
      
      SELECT ?otherTitle ?otherIsbn WHERE {
        ?book bibo:isbn10 "?isbn";
            dct:creator ?author;
            dct:subject ?subject.
      
        ?otherBook dct:subject ?subject;
            dct:title ?otherTitle;
            bibo:isbn10 ?otherIsbn.
      
        FILTER (?otherBook != ?book)
      }      
      LIMIT 10    
    EOL

    #Add parameters to a SPARQL query
    #
    #Replaces variables in the query (e.g. ?isbn) with values
    #found in the params hash
    #
    #query::a SPARQL query
    #params::a hash of variable name to value
    def add_parameters(query, params={})
        #use a regular expression to match variables in the query
        final_query = query.gsub(/(\?|\$)([a-zA-Z]+)/) do |pattern|
          key = $2
          if params.has_key?(key)
            params[key].to_s
          else
            pattern
          end              
        end            
        return final_query  
    end
        
    #Perform a SPARQL query against the BNB SPARQL endpoint
    #
    #The first parameter is a SPARQL query which will have its ?isbn
    #variable replaced by the second parameter. The query should
    #have 2 bindings: otherTitle and otherIsbn
    #
    #The query will return a hash that contains the ISBN used
    #in the query and the results.
    def find_books(query, isbn)
      sparql = SPARQL::Client.new("http://bnb.data.bl.uk/sparql")      
      #build the SPARQL query
      query = add_parameters(query, { "isbn" => isbn })
      
      #execute the query and build JSON response  
      results = sparql.query(query)      
      response = { :isbn => isbn, :results => []}
      results.each do |result|
        response[:results] << { :title => result[:otherTitle], :isbn => result[:otherIsbn] }
      end 
      return response     
    end
      
    # Serve the homepage
    get "/" do
      erb :home
    end  
    
    # A simple web service to perform a title lookup on the BNB
    # Responds to GET requests to /title and expects an isbn parameter
    # to be provided
    #
    # The code executes a SPARQL query (see FIND_TITLE) against the BNB to fetch the first
    # matching title
    #
    # The response is a simple JSON document that includes either a "title"
    # value (if the title is found) or an "error" value if not.
    #
    # Example call: http://findmeabook.herokuapp.com/title?isbn=0261102214
    get "/title" do
      isbn = params[:isbn]
      if isbn == nil || isbn == ""
        error 400
        return "Missing ISBN parameter"
      end
      
      sparql = SPARQL::Client.new("http://bnb.data.bl.uk/sparql")      
      #build the SPARQL query
      query = add_parameters(FIND_BOOK, { "isbn" => isbn })
      
      #execute the query and build JSON response  
      results = sparql.query(query)      
      response = { :isbn => isbn }

      if results.length > 0
        response[:title] = results.first[:title]
      else
        response[:error] = "Not Found"
      end
      content_type "application/json"
      return response.to_json           
    end
    
    # A simple web service to find more books by an author in the BNB. The 
    # service responds to GET requests to /by-author and expects an isbn parameter
    # to be provided
    #
    # The code executes a SPARQL query (see FIND_BOOKS_BY_AUTHOR) to 
    # find the books
    #
    # The response is a JSON document that contains the ISBN searched for
    # and an array of results. Each result will have a title and an ISBN
    #
    # Example call: http://findmeabook.herokuapp.com/by-author?isbn=0261102214
    get "/by-author" do
      isbn = params[:isbn]
      if isbn == nil || isbn == ""
        error 400
        return "Missing ISBN parameter"
      end  
        
      response = find_books(FIND_BOOKS_BY_AUTHOR, isbn)      
      content_type "application/json"
      return response.to_json
    end

    # A simple web service to related books in the BNB. The 
    # service responds to GET requests to /related and expects an isbn parameter
    # to be provided
    #
    # The code first attempts to execute a SPARQL query to see if the book is in a
    # series. If it is then other books in that series are used as recommendations
    # (see FIND_RELATED_BY_SERIES)
    #
    # The code falls back to finding other books in the same category if a series
    # can't be found. See FIND_RELATED_BY_CATEGORY
    #
    # The response is a JSON document that contains the ISBN searched for
    # and an array of results. Each result will have a title and an ISBN
    #
    # Example call: http://findmeabook.herokuapp.com/related?isbn=0261102214
    get "/related" do      
      isbn = params[:isbn]
      if isbn == nil || isbn == ""
        error 400
        return "Missing ISBN parameter"
      end  
        
      response = find_books(FIND_RELATED_BY_SERIES, isbn)
      #if we didn't find any by series, try by category
      if response[:results].empty?
        response = find_books(FIND_RELATED_BY_CATEGORY, isbn)
      end
        
      content_type "application/json"
      return response.to_json
    end
    
end
