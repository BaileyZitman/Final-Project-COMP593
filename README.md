# Final-Project-COMP593
This repository will contain the final project for the course 


## Purpose
The purpose of this script is to change the background image of the PC every day at a predetermined time to that of the Nasa Image of the day. The script will also append (or create a database if script has never ran) data and important information pertaining to the image to an sqlite database. The Nasa image of the day can be found [here](https://www.nasa.gov/multimedia/imagegallery/iotd.html) along with the previous images selected. This script will automatically activate at a predetermined time everyday and obtain the Nasa image of the day IF and only IF the image has not already been obtained, save to data to the database and then change the background photo of the PC.

This database will contain one table (for simplicity) and contain the following information: 
1. Date of Image
2. Time of Image 
3. Filename of Image
4. Filesize of Image
5. SHA-256 Hash of Image

