# Final-Project-COMP593
This repository will contain the final project for the course 


## Purpose
The purpose of this script is to change the background image of the PC every day at a predetermined time to that of the Nasa Image of the day and to append (or create if first run) a database containing information of said image.The Nasa image of the day can be found [here](https://www.nasa.gov/multimedia/imagegallery/iotd.html) along with the previous images. This script will automatically activate and obtain the Nasa image of the day IF and only IF the image has not already been obtained. This is done because on top of changing the background of the PC, the script will also create a database if one doesnt exist and append important information from the obtain images to it. This database will contain one table (for simplicity) and contain the following information: 
1. Date of Image
2. Time of Image 
3. Filename of Image
4. Filesize of Image
5. SHA-256 Hash of Image

