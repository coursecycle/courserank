### Courserank Scraper

On October 13, Chegg announced that they were [shutting down Courserank](http://www.stanforddaily.com/2014/11/07/goodbye-courserank/). There is obviously a wealth of information on the site that would be nice to have around. This scraper is the result of my work in keeping as much data as possible.

#### Payload

* `parse.rb` handles the extraction of data from Courserank. Please check the Requirements section below to ensure that you are able to run this script on your local machine. You will be prompted for your Courserank user name and password; these are only used locally so the headless browser can log onto Courserank.

#### Requirements

This script uses the following gems

* highline - user input made easier
* mechanize - headless browsing
* mongo - Ruby API for storage in MongoDB
* nokogiri - XML parsing

In addition, [MongoDB](https://mongodb.com/) is used to store information, so it should be running in the default location (port 21027) on your machine.

#### License

This scraper is released under the MIT License (MIT).

Copyright (c) 2014 Roger Chen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
