# RCT Features

### Maybe
- health tracking of driver
- sensors management (now hidden under cars)


## Register new car - core
- role: admin / race manager
- action: register new car with sensors to system
- why: the entity to be tracked

### Breakdown
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
1) system saves sensor staff to database and show confirmation, or before saving show some error if occured

### Responsibilities
1) Open web application
    - jajks

## Register new technician - core
- role: admin / race manager
- action: register new techician with specialisation
- why: to know how to maintain the car at pitstop

## Breakdown
1) manager opens web app and select to add new technician
1) In form, manager must fill basic identification info (ID, Bank account,)
1) Upload technicians CV
1) System (Using OCR and LLM) uploads basic data about new technician available in CV (contact, specialisation, ...)
1) TODO

## Register new driver
- role: admin / race manager
- action: register new driver for system
- why: to see real data of the race car during race and can react to it



## Show data for track techician - core
- role: track techician
- action: show data for track techician to state the track condition
- why: to now track conditions before race starts

## Real time data for driver
- role: driver
- action: real time data for driver about current car condition to detect critical situations

## Real time data for maintanance technician - core
- role: maintanance technician
- action: show data specific to detect what maintanance will be needed at next pit stop
- why: to maintain the car in good condition during the race

## Result race data
- role: team
- action: show final results about the preformance in the race
- why: to know what updates do before next race
