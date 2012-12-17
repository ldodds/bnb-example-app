# Find Me A Book!

The British National Bibliography (BNB) is a bibliographic database that contains information on a wide range of books and serial publications that have been published in the UK and Ireland since the 1950s. The database is available under a public domain license and can be accessed via an online API.

This project is a demo application that illustrates how to build a web application using 
the BNB SPARQL endpoint available from:

	http://bnb.data.bl.uk/sparql

A working version of this demo application can be found at [http://findmeabook.herokuapp.com](http://findmeabook.herokuapp.com)

## Installing and Running the Application

Clone from git:

	git clone https://github.com/ldodds/bnb-example-app.git

Ensure ruby and ruby gems are installed. Then install bundle:

	sudo gem install bundle

Then run bundle to install the project gems:

	sudo bundle install

Then to run the application:

	rackup

This will launch a local version of the application available from:

	http://localhost:9292

## License

The custom code and Javascript in this project is placed into the public domain under the terms of the [CC0 Waiver](<http://creativecommons.org/publicdomain/zero/1.0/>).

The project includes copies of the JQuery and Bootstrap libraries which are re-used under 
the terms of their individual licenses
