#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
# Description:
#  This script works in conjuction with the powershell script ------------- and is used to obtained the astronomy image of the day 
#  from the nasa API (one of them). The powershell script will activate this script automatically. This script will obtain the 
#  "image". Once the Image object is retreieved the script will manipulate the incomming data 
#  (from the image) and output the path of the image for the powershell script and output information to an sqlite database. The
#  sqlite database will have to have the name "PBMZ-db-FP.db" (PeterBaileyMcmurrayZitman-DataBase-FinalProject.db) for this script
#  and the powershell to work (this will be noted in the README.md file in the main branch of the repository). The database will
#  will be created in the same directory that the script was run if it doesnt already exist. An image will be created using the
#  hd-url path and the file will be created in a directory called "./Saved Images" (created in the same directory as the script).
#  The format of the image is very specific and will be created in the format "PBMZ-AIOTD-Date.jpg" (ex. PBMZ-AIOTD-2021-10-26.png).
#
# Usage
#  python FinalProject.py 
#
#  For a detailed summary on functionality and usability please visit the "README.md" file in the main Github repository
#
# History
#  For a detailed history sumamry vist the file "History.md" in the main Github repository 
#
#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
from http import client #needed to connect to the API
import json #needed to manipulate the obtained Json object 
from pprint import pprint as pp #used to make json data more readable during testing
import sqlite3 #used for connecting to the sqlite database that will save the image information each day
import datetime #used for adding time obtained from API
import re
import requests #used to obatin the image and save it to the file
import os.path #used to check if the directory "/Saved Images" already exists 
import os #used to create the directory "./Saved Images" if  doesnt exist- will store images of the day (script is set to run daily)

connection = client.HTTPSConnection('api.nasa.gov', 443) #connection to BASE URL and type
connection.request('GET', '/planetary/apod?api_key=sjs4hKLE3bgesXYphayaDhYNfuLVIJfNUOqC0Z6H')
response = connection.getresponse()

json_image = response.read().decode()
json_image = json.loads(json_image)

date = datetime.datetime.now()
time = date.time() #used later but this is the time image was obtained
date = date.date()#used right below in the filepath. the date for the db will be added from the json object

if re.match(r".+.[Jj][pP][Gg]$", json_image["hdurl"]): #checks to see if jpg because it could be png
    name_of_file = "PBMZ-AIOTD-" + str(date) + ".jpg"
else:
    name_of_file = "PBMZ-AIOTD-" + str(date) + ".png"

if not os.path.isdir('./Saved Images'): #if directory doesnt exist make it. will be used to save images to daily as a history log
    os.mkdir("./Saved Images")

if not os.path.isfile("./Saved Images/" + name_of_file): #only create a file if it doesnt exist already.
    image_response = requests.get(json_image["url"]) #will fetch the url from the interwebs to assign the the file below
    image_file = open("./Saved Images/" + name_of_file, "wb") #will create an empty file in the directory thats waiting for binary content
    image_file.write(image_response.content) #writes the contents of the image_response (request) to the waiting file.
    image_file.close() #close the file which is located in the directory "./Saved Files"

connection_db = sqlite3.connect('PBMZ-db-FP.db') #connect to the database. if one doesnt exist already create one
db_cursor = connection_db.cursor() #create a cursor object to run the queries

#Create a table if one doesn't exist already that will be the basis of our request to append information
create_AIOD_Table = """ CREATE TABLE IF NOT EXISTS 'Astronomy Image of The Day' (
                          'Date of Image' text NOT NULL,
                          'Time Obtained'  text NOT NULL,
                          'File Name HD URL ONLY' text NOT NULL,
                          'File Size'  text NOT NULL,
                          'SHA-256 Hash' text NOT NULL,
                          'Image URL' text NOT NULL,
                          'Image HD URL' text NOT NULL,
                          'Copyright' text NOT NULL,
                          'Title of Image' text,
                          'Description of Image' text,
                          PRIMARY KEY ('Date of Image')
                        );"""
db_cursor.execute(create_AIOD_Table) #creates the table using the above parameters if doesnt already exist

addDataQuery = """INSERT INTO 'Astronomy Image of The Day' (
                      'Date of Image', 
                      'Time Obtained', 
                      'File Name HD URL ONLY', 
                      'File Size', 
                      'SHA-256 Hash', 
                      'Image URL', 
                      'Image HD URL', 
                      'Copyright',
                      'Title of Image',
                      'Description of Image')
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"""

Data_query = (json_image["date"], 
            str(time), 
            name_of_file, 
            "TESTTESTTESTTESTTEST", 
            "TESTTESTTESTTESTTEST", 
            json_image["url"], 
            json_image["hdurl"], 
            json_image["copyright"],
            json_image["title"],
            json_image["explanation"])
db_cursor.execute(addDataQuery, Data_query)
connection_db.commit()
connection_db.close()