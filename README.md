# Final-Project-COMP593
This repository will contain the final project for the course 


## Purpose
The purpose of this script is to change the background image of the PC every day at a predetermined time to that of the Nasa Image of the day. The script will also append (or create a database if script has never ran) data and important information pertaining to the image to an sqlite database. The Nasa image of the day can be found [here](https://www.nasa.gov/multimedia/imagegallery/iotd.html) along with the previous images selected. This script will automatically activate at a predetermined time everyday and obtain the Nasa image of the day IF and only IF the image has not already been obtained, save to data to the database and then change the background photo of the PC.

This database will contain one table (for simplicity) and contain the following information: 
1. Date of Image
<<<<<<< Updated upstream
2. Time of Image 
3. Filename of Image
4. Filesize of Image
5. SHA-256 Hash of Image
=======
2. Date Image was Obtained
3. Time Image was Obtained 
4. Filename of Image
5. Filesize (Bytes) of Image
6. SHA-256 Hash of Image
7. The URL of the Image
8. The Image Description
9. Image Copyright Information (if applicable)

## Set-Up
In order to achieve the objective without any complications please download the entire contents of the directory **Final-Project-COMP593** and do not modify the locations of any of the files. This will be provided as a .zip file, and contains the directory structure that is required for the script to function without errors. The additional directory **./Saved Images** found within, is mandatory and should contain an image called **default.jpg**. This file can be replaced with any .jpg file by the name of **default.jpg**. Ensure the PowerShell session used to start the script **RunAPODPBMZ.ps1**, has a CWD (Current Working directory) of the directory **Final-Project-COMP593** (that of the scripts). 

Below are a couple of screenshots showing the process to configure the application:
1. ["This Image shows the downloaded .zip file](https://drive.google.com/file/d/1z4SiO3Sql6EaOrqk-DXsvGjrGE_DUcrv/view?usp=sharing)
2. ["This Image shows the contents of the .zip file"](https://drive.google.com/file/d/17ikAs_s8srxE4_x_LurAfW9Zwka9Dvfs/view?usp=sharing)
3. ["This Image shows the contents of the ./Saved Images directory within"](https://drive.google.com/file/d/1aVbqC6hPVLgtIrOgzoV-_8MZFlRkrcq4/view?usp=sharing)

After the files have been unzipped and the scipts are ready to run the following command needs to be entered to allow the script to bypass any execution policy set in place for the current user: **Set-ExecutiuonPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force**. See [Screenshot](https://drive.google.com/file/d/1GR50op8zIL6dLXWnPPP_dgQqgbJmF6Yw/view?usp=sharing)

Note: It is imperative that python is installed and configured to be assosiated with ".py" files and configured to be launchable through PowerShell directly. For example one should be able to run the below command to execute a python file in powershell "python fileName". See [Screenshot](https://drive.google.com/file/d/1byCb7ubeTDNzvNXZ_bcDMQ3p2JeJXo8J/view?usp=sharing)

## Running The Application
In order to run the application simply open a new PowerShell session and move the working directory into the folder **Final-Project-COMP593** (after extraction, See above). From within, enter the command **. .\RunAPODPBMZ.ps1** and the script will run. Depending on the chooses made, the other scripts will run immediatley or start at the designated time. 

You can choose to run each script individually to complete a part of the objective and the uses of this and each scripts functionality is described below.

## Functionality
Included with the application are three serperate scripts, working in tandom to complete the objective. The three scripts are: **RunAPODPBMZ.ps1**, **FinalProject.ps1** and **FinalProject.py**, two being PowerShell scripts and one being a python script. All three are mandatory to achieve full functionality of the application. This section provides more detailed information about each script. Ensuring the functionality of each script is clear and concise. 

### RunAPODPBMZ.ps1
To run this script navigate to it's parent directory and enter: . .\RunAPODPBZ.ps1

This script provides the user the ability to configure how the scripts **FinalProject.ps1** and **FinalProject.py** execute. In order to run both of the previously mentioned scripts without command-line parameters, this script needs to be utilized to execute them because this script is the only one (of the three) that doesnt accepts/need parameters. This script provides the user with the ability to either run the script **FinalProject.ps1** directly, or configure a task to run the script instead. When selecting to create a new task, the name of the task will be set as "PBMZ Background Changer", with the option to either run the task once or daily. When selecting to create a new task, the user is also required to enter the time the task is to be completed. However, if the user selects the option to execute the scripts immediately,by entering **Now** when prompted (versus **Once** or **Daily**) this script will start a new PowerShell session in the correct location and then execute **FinalProject.ps1** inside of the newly created session. 

When run by itself this script will provide the full functionality of the application. No command line parameters are required to run this script and by following through the prompts either a new task will be created, to run once or daily at a specified time or the **FinalProject.ps1** script will execute in a new PowerShell session. 

### FinalProject.ps1
To run this script navigate to it's parent directory and enter: . .\FinalProject.ps1 "directorytosearch"

This script provides the main functionality of the application and once configured with the invoking script (normally run via a task or RunAPODPBMZ.ps1) will actually complete the background change. This script is used to call the python script, **FInalProject.py** depending on certain circumstances. When this script is called, the first objective it completes is to determine if the database **PBMZ-db-FP.sqlite** exists and if there is an entry in said database for the current day, by making an SQL query request. If there is no database or no entry exists, then this script calls the **FinalProject.py** script to create the database and create an entry for the current day. If there is an entry for the current date, the returned hash value from the SQL request is compared against the directory **./Saved Images** and another directory of the users choose (directorytosearch). If the comparison returns another file containing the same hash, that image is used to change the background image of the computer and the python script is not started. If the comparison doesn't reveal another file containing the hash obtained, this script will call the **FinalProject.py** script, but opposed to adding a new entry, it will just redownload the image and use that image to change the background. Whenever this script calls the python script, a relative filepath is returned which is converted into a fullPath, to be used to change the image. This script, will also read, output and then delete a file called **./temp.txt**, that the python script creates. This script completes the background change and the comparison of the hashes currently found in the two searched directories. 

If the script is run by itself, without being invoked by the script **RunAPODPBMZ.ps1** then it must be executed with the above mentioned command line parameter. The command line paramter tells the script which additional directory to search and while it completes succesfully without the parameter, there will be an error if none is provided (sometimes). The default parameter is "default" but any ***valid*** directory can be entered to search. This script will complete everything as normal,, and doesn't need to be invoked by the previously mentioned script to complete the background change properly but if run by itself then the command line parameter value needs to be specified. When a task is configured to run, it will run this script as this script calls the python script and completes the background change. The task is configured by **RunAPODPBMZ.ps1** and then its set to run this script, which in turn, if applicable will run **FinalProject.py**. 

### FinalProject.py
To run this script navigate to it's parent directory and enter: python FinalProject.py "1or2"

This script is invoked by the script **FInalProject.ps1** if there is no entry for the current date, the database doesnt exist, or there is an entry for the current date but the image doesnt exist in the searched directories. When invoked by the PowerShell script, it will be provided with either a 1 or a 2 to indicate the function it is to complete. If a 1 is passed to this script upon execution it indicates that there is no database or entry for the current date. In such a case, this script will make a connection to the NASA API containing the Astronomy Image of The Day and retrieve the image information. This will be appended to the database as a new entry or if the database doesnt exists, will be appended after the database and table are created. On the off chance the Image of the day is actually a video, the last available image (most recent) will be used as the background image for the current day. In the case when there is no database, or previous images to use and it is a video, a default image has been provided instead that will be used until the next available image is obtained. When being invoked and this script is provided with a 2, the PowerShell script indentified an entry for the current date but could not find an image that matches the hash of the image in the entry. In this situation, the python script will make an SQL query on the database for the current dates filepath and url. This will be used to reobtain the image and save it again. Whenever This script is called, a file is created called **./temp.txt** and it contains all of the output of this script. This will be read back to the PowerShell Terminal after this script is completed. This script also outputs the relative filepath of the image its saved back to the PowerShell script to be used as the background image. 
>>>>>>> Stashed changes

