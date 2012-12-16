require 'rubygems'
require 'sinatra/base'

class FindMeABook < Sinatra::Base
  
    #Configure application level options
    configure do |app|
      set :static, true    
      set :views, File.dirname(__FILE__) + "/../views"
      set :public, File.dirname(__FILE__) + "/../public"     
      enable :xhtml        
    end
    
    get "/" do
      erb :home
    end  
    
    #Find the book in the dataset
    #Need to handle if not found
    #Return its metadata
    get "/find" do
      
    end
    
    get "/by-author" do
      
    end
    
    get "/related" do
      
    end
    
end