#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
# Description:
#  This script works in conjuction with the powershell script "FinalProject.ps1" and is used to obtained the astronomy image of the day 
#  from the nasa API (one of them). The powershell script will activate this script automatically. This script will obtain the 
#  "image". Once the Image object is retreieved the script will manipulate the incomming data 
#  (from the image) and output the path of the image for the powershell script and output information to an sqlite database. The
#  sqlite database will have to have the name "PBMZ-db-FP.db" (PeterBaileyMcmurrayZitman-DataBase-FinalProject.db) for this script
#  and the powershell script to work (this will be noted in the README.md file in the main branch of the repository). The database will
#  will be created in the same directory that the script was run if it doesnt already exist. An image will be created using the
#  url path if an image was returned and the file will be created in a directory called "./Saved Images" (created in the same directory as the script).
#  The format of the image is very specific and will be created in the format "PBMZ-AIOTD-Date.jpg" (ex. PBMZ-AIOTD-2021-10-26.png).
#
# Usage
#  The powershell Script will automatically activate this script, however if a manual run is required use:
#
#  python FinalProject.py 
#
#  Note: For a detailed summary on functionality and usability please visit the "README.md" file in the main Github repository
#
# History
#  For a detailed history summary vist the file "History.md" in the main Github repository 
#
#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
from http import client #needed to connect to the API
import json #needed to manipulate the obtained Json object 
from pprint import pprint as pp #used to make json data more readable during testing
import sqlite3 #used for connecting to the sqlite database that will save the image information each day
import datetime #used for adding time obtained from API
import re #used to determine if .jpg or .png
import requests #used to obatin the image and save it to the file
import os.path #used to check if the directory "/Saved Images" already exists 
import os #used to create the directory "./Saved Images" if  doesnt exist- will store images of the day (script is set to run daily). also used to detrmine size of file
import hashlib #used to get the images hash value to save to the database

def Connection_and_json():
    connection = client.HTTPSConnection('api.nasa.gov', 443) #connection to BASE URL and type
    connection.request('GET', '/planetary/apod?api_key=sjs4hKLE3bgesXYphayaDhYNfuLVIJfNUOqC0Z6H&date=2020-01-22')
    response = connection.getresponse()
    json_image = response.read().decode()
    json_image = json.loads(json_image)
    return json_image

def get_hash(FileName): #get the hash and size of the specified file
    obj = hashlib.sha256() #creates a hash object with our desired algorithm
    FilePath = '.\Saved Images\\' + FileName
    open_file = open(FilePath, 'rb') #opens the file in "read binary" mode
    chunk = 0
    while chunk != b'': #read to end of file
        chunk = open_file.read(1024) #read only 1024 bytes at a time
        obj.update(chunk) #need to update the object on each read or will get the same hash everytime becasuse the last read in every loop without this would be the only thing hashed.
    hash_value = obj.hexdigest()
    open_file.close() #close file
    return hash_value

def get_size(FileName): #determines the files size
    FilePath = '.\Saved Images\\' + FileName
    File_info = os.stat(FilePath)
    File_size = File_info.st_size
    return File_size
    
def parse_json(json): #used to determine what keys are available for that day, each day the keys are variable and this determines what keys are used for the day ran
    keys = []
    for i in json: #assigns the keys to a list to be used later
        keys += [i]
    return keys

json = Connection_and_json()
#print(json) #used to test the output and returned json object

date = datetime.datetime.now()
time = date.time() #used later but this is the time image was obtained
date = date.date()#used right below in the filepath. the date for the db will be added from the json object

if json["media_type"] == "image": #this makes sure no videos are appended to the database. In the case a video is availabe for the desired day and not an image, use last available image.
    if re.match(r".+.[Jj][pP][Gg]$", json["url"]): #checks to see if jpg because it could be png or even a video
        name_of_file = "PBMZ-AIOTD-" + json["date"] + ".jpg"
    elif re.match(r".+.[Pp][Nn][Gg]$", json["url"]):
        name_of_file = "PBMZ-AIOTD-" + ["date"] + ".png"

    if not os.path.isdir('./Saved Images'): #if directory doesnt exist make it. will be used to save images to daily as a history log
        os.mkdir("./Saved Images")

    if not os.path.isfile("./Saved Images/" + name_of_file): #only create a file if it doesnt exist already and the retrieved image is actually an image.
        image_response = requests.get(json["url"]) #will fetch the url from the interwebs to assign the the file below
        image_file = open("./Saved Images/" + name_of_file, "wb") #will create an empty file in the directory thats waiting for binary content
        image_file.write(image_response.content) #writes the contents of the image_response (request) to the waiting file.
        image_file.close() #close the file which is located in the directory "./Saved Files"

    File_Hash = get_hash(name_of_file)
    File_size = get_size(name_of_file)


    connection_db = sqlite3.connect('PBMZ-db-FP.sqlite') #connect to the database. if one doesnt exist already create one
    db_cursor = connection_db.cursor() #create a cursor object to run the queries
    create_AIOD_Table = """ CREATE TABLE IF NOT EXISTS 'Astronomy Image of The Day' (
                            'Date of Image' text NOT NULL,
                            'Date Image was Obtained' text NOT NULL,
                            'Time Obtained'  text NOT NULL,
                            'File Name' text NOT NULL,
                            'File Size (Bytes)'  text NOT NULL,
                            'SHA-256 Hash' text NOT NULL,
                            'Image URL' text NOT NULL,
                            PRIMARY KEY ('Date Image was Obtained')
                        );"""
    db_cursor.execute(create_AIOD_Table) #creates the table using the above parameters if doesnt already exist

    addDataQuery = """INSERT INTO 'Astronomy Image of The Day' (
                        'Date of Image',
                        'Date Image was Obtained', 
                        'Time Obtained', 
                        'File Name', 
                        'File Size (Bytes)', 
                        'SHA-256 Hash', 
                        'Image URL')
                    VALUES (?, ?, ?, ?, ?, ?, ?);"""

    Data_query = (json["date"], 
                str(date),
                str(time), 
                name_of_file, 
                File_size, 
                File_Hash.upper(), 
                json["url"])
    db_cursor.execute(addDataQuery, Data_query)
    connection_db.commit()
    connection_db.close()
    print("The image was returned successfully and the data was saved to the database PBMZ-db_FP")

else: 
    print("The Image of the Day provided by Nasa is actually a Video. Will use the last available image instead.")