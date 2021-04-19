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
#  python FinalProject.py 1or2
#
# Paramaters
#  1or2 = This is used to identify whether a new entry is to appended to the database[1] or if the image is to be downloaded only[2]
#
#  Note: For a detailed summary on functionality and usability please visit the "README.md" file in the main Github repository
#
# History
#  For a detailed history summary vist the file "History.md" in the main Github repository 
#
#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
from http import client #needed to connect to the API
import json #needed to manipulate the obtained Json object 
import sqlite3 #used for connecting to the sqlite database that will save the image information each day
import datetime #used for adding time obtained from API
import re #used to determine if .jpg or .png
import requests #used to obatin the image and save it to the file
import os.path #used to check if the directory "/Saved Images" already exists 
import os #used to create the directory "./Saved Images" if  doesnt exist- will store images of the day (script is set to run daily). also used to detrmine size of file
import hashlib #used to get the images hash value to save to the database
from sys import argv #used to indentify if image is to be appended and downloaded or just downloaded

def Connection_and_json(): #makes connection to nasa api and returns the json data
    connection = client.HTTPSConnection('api.nasa.gov', 443) #connection to BASE URL and type
    connection.request('GET', '/planetary/apod?api_key=sjs4hKLE3bgesXYphayaDhYNfuLVIJfNUOqC0Z6H') #make conenction with my key
    response = connection.getresponse() #get response
    json_image = response.read().decode() #decode response still not json just in json format
    json_image = json.loads(json_image) #turn data in the above variable which is in json format into a json objuect for easy manipulation
    return json_image #returns json object containing data from api for TODAY

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

def get_size(FileName): #determines the files size in a really convoluted way 
    FilePath = '.\Saved Images\\' + FileName
    File_info = os.stat(FilePath) #get the stats on the file
    File_size = File_info.st_size #pull the size base on the stats info
    return File_size #return size only in bytes

def write_output(Output): #this creates and saves and closes the temp directory where all of the output of this script is store. WHich is read by powershell. 
    open_file = open(".\\temp.txt", "w")
    open_file.write(Output)
    open_file.close()
    
def parse_json(json): #used to determine what keys are available for that day, each day the keys are variable and this determines what keys are used for the day ran
    keys = []
    for i in json: #assigns the keys to a list to be used later
        keys += [i]
    return keys #returns list of keys that the json image currently has, used to determine if the copyright key is found within later on

command_for_script = argv[1] #which "control" parameter was passed to the script
output = [] #start the log file output array, its outputted as an array and read back reformatted in FInalProject.ps1

if command_for_script == "1": #if a new entry is to be made and a new image is to be downloaded
    json = Connection_and_json() #call function to get data for today
    output.append("The data from the Nasa API was recieved sucessfully")

    date = datetime.datetime.now()
    time = date.time() #used later but this is the time image was obtained
    date = date.date()#used right below in the filepath. the date for the db will be added from the json object

    if json["media_type"] == "image": #this makes sure no videos are appended to the database. In the case a video is availabe for the desired day and not an image, use last available image.
        if re.match(r".+.[Jj][pP][Gg]$", json["url"]): #checks to see if jpg because it could be png or even a video
            name_of_file = "PBMZ-AIOTD-" + json["date"] + ".jpg" #the date is based on the date of the image and not when it was obtained
        elif re.match(r".+.[Pp][Nn][Gg]$", json["url"]):
            name_of_file = "PBMZ-AIOTD-" + json["date"] + ".png"

        image_response = requests.get(json["url"]) #will fetch the url from the interwebs to assign the the file below
        image_file = open("./Saved Images/" + name_of_file, "wb") #will create an empty file in the directory thats waiting for binary content
        image_file.write(image_response.content) #writes the contents of the image_response (request) to the waiting file.
        image_file.close() #close the file which is located in the directory "./Saved Files"

        output.append("The image: ./Saved Images/" + name_of_file + " was saved sucessfully")

        File_Hash = get_hash(name_of_file) #get the files hash
        File_size = get_size(name_of_file) #gets the files size
        File_Path = "./Saved Images/" + name_of_file #specifies the filepath for the directory. 

        connection_db = sqlite3.connect('PBMZ-db-FP.sqlite') #connect to the database. if one doesnt exist already create one
        db_cursor = connection_db.cursor() #create a cursor object to run the queries
        create_AIOD_Table = """ CREATE TABLE IF NOT EXISTS 'Astronomy Image of The Day' (
                                'Date of Image' text NOT NULL,
                                'Date Image was Obtained' text NOT NULL,
                                'Time Obtained'  text NOT NULL,
                                'File Name' text NOT NULL,
                                'File Path' text NOT NULL,
                                'File Size (Bytes)'  text NOT NULL,
                                'SHA-256 Hash' text NOT NULL,
                                'Image URL' text NOT NULL,
                                'Explanation' text NOT NULL,
                                'Copyright' text NOT NULL,
                                PRIMARY KEY ('Date of Image')
                            );"""
        db_cursor.execute(create_AIOD_Table) #creates the table using the above parameters if doesnt already exist

        keys = parse_json(json) #gets the keys returned in the object
        Copyright = 'No Copyright' #for public images
        if (re.findall('copyright', str(keys))): #if the copyright key is found in the returned keys, add it. 
            Copyright = json["copyright"] #for copyrighted images, good idea to include. 
        
        addDataQuery = """INSERT INTO 'Astronomy Image of The Day' (
                            'Date of Image',
                            'Date Image was Obtained', 
                            'Time Obtained', 
                            'File Name',
                            'File Path', 
                            'File Size (Bytes)', 
                            'SHA-256 Hash', 
                            'Image URL',
                            'Explanation',
                            'Copyright')
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"""

        Data_query = (json["date"], 
                    str(date),
                    str(time), 
                    name_of_file,
                    File_Path, 
                    File_size, 
                    File_Hash.upper(), 
                    json["url"],
                    json["explanation"],
                    Copyright)

        db_cursor.execute(addDataQuery, Data_query) #executes the adding of the data
        connection_db.commit() #commites or saves the data so it will persists after the session closes
        connection_db.close() #closes the connection
        output.append("The image was returned successfully and the data was saved to the database PBMZ-db_FP.sqlite")
        write_output(str(output)) #creates, saves all of the info, and closes the temp file. (may not see unless only running this script by itself)
        print(File_Path) #this is captured by powerhsell as the images path used back in the powershell script. 

    else: #an image isnt available today  becasue it is a video instead, 
        output.append("The Image of the Day provided by Nasa is actually a Video. Will use the last available image instead.")
        if os.path.isfile("PBMZ-db-FP.sqlite"): #if the database exists already
            connection_db = sqlite3.connect('PBMZ-db-FP.sqlite') #connect to the database.
            db_cursor = connection_db.cursor() #create a cursor object to run the queries
            db_cursor.execute('SELECT "File Path", "Date Image was Obtained" FROM "Astronomy Image of The Day"') #executes query for all files paths and dates of the db
            File_Path = db_cursor.fetchall() #gets all of the info and assigns to this variable
            write_output(str(output)) #write to and close temp file
            print(File_Path[0][0]) #return the first result, which will be the most recent image available
            connection_db.close() #closes the db conenction
        else: #use the default image if the directory doesnt exist already.  
            output.append("The database does not exist and the current available data for the current day is a video and not an image. This script will work to its fullest extent on the next day an image available. A default image will be used instead")
            write_output(str(output)) #write and close temp file
            print("./Saved Images/default.jpg") #output the path to the default image which must be located here

else: #if the image is to be retrieved and downloaded instead.
    date = datetime.datetime.now()
    date = date.date()
    connection_db = sqlite3.connect('PBMZ-db-FP.sqlite') #connect to the database. if one doesnt exist already create one
    db_cursor = connection_db.cursor() #create a cursor object to run the queries
    query = 'SELECT "File Path", "Image URL" FROM "Astronomy Image of The Day" WHERE "Date Image was Obtained"' + ' = "' + str(date) + '"'
    db_cursor.execute(query) #execute query
    File_Path = db_cursor.fetchall() #gather the data
    File_Path_location = File_Path[0][0] #get the files path to be outputted for powershell because that makes it happy (mandatory not joking)
    File_URL = File_Path[0][1] #obtains the url for the image

    if re.match(r".+.[Jj][pP][Gg]$", str(File_Path_location)): #checks to see if jpg because it could be png
        name_of_file = "PBMZ-AIOTD-" + str(date) + ".jpg"
    elif re.match(r".+.[Pp][Nn][Gg]$", str(File_Path_location)):
        name_of_file = "PBMZ-AIOTD-" + str(date) + ".png"
    
    image_response = requests.get(File_URL) #will fetch the url from the interwebs to assign the the file below
    image_file = open("./Saved Images/" + name_of_file, "wb") #will create an empty file in the directory thats waiting for binary content
    image_file.write(image_response.content) #writes the contents of the image_response (request) to the waiting file.
    image_file.close() #close the file which is located in the directory "./Saved Files"  

    print(File_Path_location) #output file path back to powershell
    connection_db.close() #close the database. 
    