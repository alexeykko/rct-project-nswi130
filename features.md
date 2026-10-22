# RCT System

## Core features and responsibilities

### Register new car
- role: admin / race manager
- action: register new car with sensors to system
- why: the entity to be tracked

#### Feature breakdown
1) race manager opens dashboard (web application)
1) Manager uploads unique car identifier from the original manufacturer
1) System checks if the id is correct and not present in system (else show error message to user)
1) Download basic car information from manufacturer (car brand, car model, motor info, weight, ...)
1) Clean downloaded data and store them to system database
1) system redirects manager to new car info page
1) Manager register sensors for new car - in car page he will click button to add new sensor and fill following info:
    - what part sensor monitors
    - in wich unit
    - how often
1) system saves sensor stuff to database and show confirmation, or before saving show some error if occured

#### Responsibilities
1) UI interaction responsibilities 
    - Serve web application
    - Show a form for entering the unique car identifier
    - Show a form for adding new sensor configurations
    - Display success confirmations or error messages to the user
    - Handle user redirection to specific pages
1) Car Identification and validation responsibilities
    - Validate the provided unique car identifier
    - Verify that the car ID doesn't already exist in the system
1) External data downloading responsibilities
    - Connect to the manufacturer's database
    - Download basic car information based on the unique identifier
1) Data processing and storing responsibilities
    - Clean the downloaded car data into our internal format
    - Store the new car record
    - Store the sensor configurations linked to the specific car

### Register new technician
- role: admin / race manager
- action: register new techician with specialisation
- why: to know how to maintain the car at pitstop

#### Feature breakdown
1) Manager opens web app and select to add new technician
1) In form, manager must fill basic identification info (ID, Bank account,)
1) System checks if the id is correct and not present in system (else show error message to user)
1) Download and process data about the technician from some government system using the technician id
1) Upload technicians CV
1) System (Using OCR and LLM) uploads basic data about new technician available in CV (contact, specialisation, ...)
1) Present the extracted data from CV to the manager for review
1) Assign the technician to a specialized group
1) Assign roles for the technician
1) Store these data about the technician to the database

#### Responsibilities
1) UI interaction responsibilities 
    - Serve web application
    - Show a form for entering identification info
    - Show a file picker for uploading a CV
    - Display success confirmations or error messages to the user
    - Show a form for manager's review
    - Show a form for group and roles assignment
1) Identification and validation responsibilities
    - Validate the provided technician identification
    - Verify that technician doesn't already exist in the system
1) External data downloading responsibilities
    - Connect to the government system
    - Download information about the person
    - Access some interface with an LLM
    - Retrieve processed data from LLM
1) Data processing and storing responsibilities
    - Store data about the technician (id, CV data, specialization, ...)
    - Clean the downloaded data about the person into our internal format
    - Store the technician group relation
    - Store the technician roles relation

### Show data for track technician
- role: track technician
- action: show data for track technician to state the track condition
- why: to now track conditions before race starts

#### Feature breakdown

1) The technician opens the web application and selects an upcoming race
1) The system checks if the technician can access the selected race
1) The system loads basic track information (track name, length, surface type, ...)
1) The system downloads track measurements (surface temperature, humidity, ...) and weather forecast from external services
1) The system checks if the data are valid and recent (else informs the technician)
1) The system displays the data on a dashboard and warns about values outside configured limits
1) The technician reviews the data and states the track condition (dry, wet, ...)
1) The system stores the track condition and shows confirmation

#### Responsibilities

1) UI interaction responsibilities
   - Display available races
   - Display basic track information
   - Display track measurements, weather forecast and warnings
   - Show a form for stating the track condition
   - Display success confirmations or error messages to the user

1) Access control responsibilities
   - Check if the technician has permission to view the selected race data

1) External data downloading responsibilities
   - Connect to the track and weather services
   - Download track measurements and weather forecast

1) Data processing and storing responsibilities
   - Retrieve basic track information
   - Validate the downloaded data and clean them into our internal format
   - Compare measurements with configured limits
   - Store the track condition linked to the specific race

### Real time data for maintanance technician
- role: maintanance technician
- action: show data specific to detect what maintanance will be needed at next pit stop
- why: to maintain the car in good condition during the race

#### Feature breakdown

1) The technician opens the web application
1) The technician selects an active race and a car
1) The system checks if the technician can access the selected car
1) The system loads the car sensors and their latest measurements
1) The system receives new measurements from the sensors
1) The system checks if the measurements are valid and recent
1) The system selects data relevant to car maintenance
1) The system displays the sensor values, units, and timestamps on a dashboard
1) The system compares the values with configured limits
1) If a value is outside its limit, the system displays a warning and identifies the related car part
1) If data is missing the system informs the technician
1) The technician reviews the data and warnings to decide what maintenance needed

#### Responsibilities

1) UI interaction responsibilities
   - Display available races and cars
   - Display sensor measurements, units, and timestamps
   - Display warnings and data error messages

1) Access control responsibilities
   - Check if the technician has permission to view the selected car data

1) Data collection responsibilities
   - Load the sensors registered for the selected car
   - Receive new measurements from the sensors
   - Link each measurement to the correct car and sensor

1) Data validation responsibilities
   - Check if measurements contain valid values
   - Check if measurements are recent
   - Inform the technician when data is missing

1) Data processing responsibilities
   - Select measurements relevant to maintenance
   - Compare measurements with configured limits
   - Detect values outside the configured limits
   - Identify the car part related to a warning

1) Data storing responsibilities
   - Retrieve the latest stored measurements when needed
   - Record processing errors

## Auxiliary features

### Register new driver
- role: admin / race manager
- action: register new driver for system
- why: to see real data of the race car during race and can react to it

### Real time data for driver
- role: driver
- action: real time data for driver about current car condition to detect critical situations
- why: so he can react to the car's conditions

### Result race data
- role: team
- action: show final results about the preformance in the race
- why: to know what updates do before next race

### Manage sensors configuration
- role: admin / race manager
- action: manage sensors configuration for registered cars
- why: to keep sensor settings correct when sensors are added or changed

### Maybe
- health tracking of driver
- sensors management (now hidden under cars)

## System

### Architecture

#### 1. Presentation

#### 2. Business/application

#### 3. Persistance/infrastructure


### Columns

#### Capturing car measurements
    3. - Data collection
       - 

#### Capturing track measurements
    3. 

#### Technician Registry

#### Car Registry

#### Data assessment/Main/Everything Else
