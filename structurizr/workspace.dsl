workspace "RCT" "RCT System" {

    model {
        # Level 1: Users
        manager = person "Race manager" "Registers cars and technicians, manage the race"
        maintenanceTech = person "Maintenance technician" "Monitors realtime data to prepare for pitstops"
        trackTech = person "Track technician" "Monitors track condition"
        driver = person "Driver" "Drives a race car"
        team = person "Team" "Views race results"

        # Level 1: External Systems
        manufacturerSystem = softwareSystem "External manufacturer web/database" "Provides car data" "External"
        govSystem = softwareSystem "Government registry API" "Provides technician data" "External"
        telemetryGateway = softwareSystem "External Telemetry Gateway" "Provides real-time car and track telemetry data" "External"

        # Level 1: Main Software System
        rctTracker = softwareSystem "RCT Tracker" "Tracks cars and track conditions" {
            !docs docs
            
            # Level 2: web application
            webApp = container "Web Application" "Dashboards for managers and technicians" "React" "WebBrowserTag"

            # Level 2: business logic and Level 3 components
            administrationApp = container "Administration Application" "Validates data and stores them" "Java" {
                accessControl = component "Access Control" "Checks permissions"

                carValidator = component "Car data validation" "Validates car IDs"
                carProvider = component "External car data provider" "Connects to manufacturer"
                carRepo = component "Car and sensor repository" "Persists car and sensor data"
                sensorManager = component "Sensor Configuration Manager" "Manages sensor settings"

                techValidator = component "Tech. data validation" "Validates technician IDs, extracts CV data using OCR and LLM"
                techProvider = component "External Tech. data provider" "Connects to government registry"
                techRepo = component "Tech. Repository" "Persists technician data"

                #driverManager = component "Driver Management" "Registers drivers"

                #maintenanceAnalyzer = component "Maintenance Data Analyzer" "Compares data with limits"

                #raceReporter = component "Race Result Reporter" "Generates race reports"
            }

            dataAnalyzer = container "Maintenance Data Analyzer" "Loads and analyzes data" "Java" {
                analyzerAccessControl = component "Access Controll" "Checks permissions"
                maintenanceAnalyzer = component "Maintenance Data Analyzer" "Compares data with limits"
                dataLoader = component "Loader" "Loads needed data from telemetry measurements and car/sensor repository"
                resultReporter = component "Result Reporter" "Reports results of analysis to"
            }

            # Level 2: data collection from sensors:
            telemetryCapturer = container "Telemetry Data Capturer" "Collects real-time data from sensors" "Java" {
                telemetryCollector = component "Telemetry Collector" "Receives measurements"
                telemetryValidator = component "Telemetry Validator" "Checks data validity"
                telemetryRepository = component "Telemetry Repository" "Stores measured data to database"
                telemetryCache = component "Cache" "Stores newest telemetry data for quicker access for analyzer"
            }

            # Level 2: databases
            carDb = container "Car and sensor database" "Stores car and sensor data" "PostgreSQL" "Database"
            techDb = container "Technician database" "Stores technician data" "PostgreSQL" "Database"
            telemetryCarDb = container "Telemetry Car database" "Stores time-series data" "InfluxDB" "Database"
            telemetryTrackDb = container "Telemetry Track database" "Stores time-series data" "InfluxDB" "Database"
            #driverDb = container "Driver database" "Stores driver data" "PostgreSQL" "Database"
            #raceDb = container "Race database" "Stores race results" "PostgreSQL" "Database"
        }

        # Relationships between users and containers
        manager -> webApp "Uses"
        maintenanceTech -> webApp "Uses"
        trackTech -> webApp "Uses"
        driver -> webApp "Views realtime data"
        team -> webApp "Views race results"

        # Relationships between Level 2 containers
        webApp -> accessControl "Requests access"
        carValidator -> webApp "Sends messages to"
        techValidator -> webApp "Sends messages to"
        sensorManager -> webApp "Sends messages to"
        webApp -> analyzerAccessControl "Requests access"
        #webApp -> carValidator "Registers car"
        #webApp -> sensorManager "Manages sensors"
        #webApp -> techValidator "Registers technician"
        #webApp -> driverManager "Registers driver"
        #webApp -> raceReporter "Requests race results"

        # Relationships between Level 3 components
        accessControl -> carValidator "Registers car"
        accessControl -> sensorManager "Manages sensors"
        accessControl -> techValidator "Registers technician"
        analyzerAccessControl -> maintenanceAnalyzer "Allows telemetry view"
        maintenanceAnalyzer -> resultReporter "Sends results to"
        dataLoader -> carRepo "Loads sensor configuration"
        dataLoader -> telemetryRepository "Retrieves measurements"
        dataLoader -> maintenanceAnalyzer "Provides data to"
        #accessControl -> raceReporter "Allows results view"

        carValidator -> carProvider "Gets data from"
        carProvider -> manufacturerSystem "Makes calls to read data"
        carValidator -> carRepo "Sends data to"
        sensorManager -> carRepo "Updates sensor config"
        carRepo -> carDb "Writes to"
        techValidator -> techProvider "Gets data from"
        techProvider -> govSystem "Makes calls to read data"
        techValidator -> techRepo "Sends data to"
        techRepo -> techDb "Writes to"

        #driverManager -> driverDb "Writes to"
        #raceReporter -> raceDb "Reads from"

        telemetryGateway -> telemetryCollector "Sends new measurements"
        telemetryCollector -> telemetryValidator "Sends measurements to"
        telemetryValidator -> telemetryRepository "Sends validated measurements to"
        telemetryRepository -> telemetryCarDb "Stores car telemetry data"
        telemetryRepository -> telemetryTrackDb "Stores track telemetry data"
        telemetryRepository -> telemetryCache "Stores newest telemetry data"
        
        #maintenanceAnalyzer -> carRepo "Loads sensor configuration"
        #maintenanceAnalyzer -> telemetryRepository "Retrieves measurements"
        resultReporter -> webApp "Reports measurements and warnings"

        # Deployment for Production
        deploymentEnvironment "Production" {

            deploymentNode "Application Server" "" "Ubuntu 26.04 LTS" {
                deploymentNode "Web server" "" "Apache Tomcat 11.0.29" {
                    adminAppInstance = containerInstance administrationApp
                    dataAnalyzerInstance = containerInstance dataAnalyzer
                }
            }

            deploymentNode "User's web browser" "" "" {
                webAppInstance = containerInstance webApp
            }

            deploymentNode "Capture Server" "" "Ubuntu 26.04 LTS" {
                telemetryCapturerInstance = containerInstance telemetryCapturer
            }

            deploymentNode "Database Server" "" "Ubuntu 26.04 LTS" {
                deploymentNode "Relational DB server" "" "PostgreSQL 18.7" {
                    carDbInstance = containerInstance carDb
                    techDbInstance = containerInstance techDb
                }

                deploymentNode "Time-Series DB server" "" "InfluxDB 3.12.2" {
                    telemetryCarDbInstance = containerInstance telemetryCarDb
                    telemetryTrackDbInstance = containerInstance telemetryTrackDb
                }
            }

            deploymentNode "External IoT Network" "" "" {
                telemetryGatewayInstance = softwareSystemInstance telemetryGateway
                GovSystemInstance = softwareSystemInstance govSystem
                ManufacturerSystemInstance = softwareSystemInstance manufacturerSystem
            }
        }

        # Deployment for development
        deploymentEnvironment "Development" {
            deploymentNode "Developer Workstation" "Local development machine" "Windows 11 / macOS / Linux" {

                deploymentNode "Developer's web browser" "Local web browser" "Google Chrome / Mozila Firefox" {
                    devWebAppInstance = containerInstance webApp
                }
                
                deploymentNode "Docker Desktop" "" "Docker Engine" {

                    deploymentNode "Local Java Runtime" "IDE" "" {
                        devAdminAppInstance = containerInstance administrationApp
                        devDataAnalyzerInstance = containerInstance dataAnalyzer
                        devTelemetryCapturerInstance = containerInstance telemetryCapturer
                    }

                    deploymentNode "Relational DB server" "Local relational DB container" "PostgreSQL 18.7" {
                        devCarDbInstance = containerInstance carDb
                        devTechDbInstance = containerInstance techDb
                    }

                    deploymentNode "Time-Series DB server" "Local time-series DB container" "InfluxDB 3.12.2" {
                        devTelemetryCarDbInstance = containerInstance telemetryCarDb
                        devTelemetryTrackDbInstance = containerInstance telemetryTrackDb
                    }

                    deploymentNode "Telemetry simualator" "Simulates race telemetry data" "Python Telemetry Simulator" {
                        devTelemetryGatewayInstance = softwareSystemInstance telemetryGateway
                    }
                }
            }

            deploymentNode "External IoT Network" "" "" {
                devGovSystemInstance = softwareSystemInstance govSystem
                devManufacturerSystemInstance = softwareSystemInstance manufacturerSystem
            }
        }
    }

    views {
        # Level 1: System Context View
        systemContext rctTracker "SoftwareSystem" {
            include *
        }

        # Level 2: Container View
        container rctTracker "Containers" {
            include *
        }

        # Level 3: Component View
        component administrationApp "Components" {
            include *
        }

        component telemetryCapturer "CollectorComponents" {
            include *
        }

        component dataAnalyzer "AnalyzerComponents" {
            include *
        }

        # Production Deployment View
        deployment rctTracker "Production" "ProductionDeployment" {
            include *
        }

        # Development Deployment View
        deployment rctTracker "Development" "DevelopmentDeployment" {
            include *
        }

        # Here comes dynamic views:
        # 1. Dynamic view for feature Register new car
        dynamic administrationApp "RegisterNewCar" "Dynamic diagram for registering a new car and its sensors" {
            # 1-2. Race manager opens web app and submits unique car ID
            manager -> webApp "1. Opens dashboard and submits unique car ID"
            webApp -> accessControl "2. Requests access to register a car"
            accessControl -> carValidator "3. Forwards car registration request"

            # 3. System checks if ID is valid and not already present in the database
            carValidator -> carRepo "4. Checks if car ID already exists"
            carRepo -> carDb "5. Queries existing car IDs"

            # 4. Download basic car info from manufacturer
            carValidator -> carProvider "6. Requests basic car data by ID"
            carProvider -> manufacturerSystem "7. Downloads car info (brand, model, motor, weight)"

            # 5-6. Clean data, store to DB, and redirect manager to new car page
            carValidator -> carRepo "8. Sends cleaned car data for storage"
            carRepo -> carDb "9. Writes new car record"
            carValidator -> webApp "10. Confirms registration and redirects to car info page"

            # 7-8. Manager registers sensors for the new car and system saves them
            manager -> webApp "11. Fills and submits new sensor configuration (part, unit, frequency)"
            webApp -> accessControl "12. Requests access to add sensor configuration"
            accessControl -> sensorManager "13. Forwards sensor configuration request"
            sensorManager -> carRepo "14. Updates sensor configuration for the car"
            carRepo -> carDb "15. Writes sensor configuration to database"
            sensorManager -> webApp "16. Sends confirmation (or error message) to user"

            autoLayout lr
        }

        # 2. Dynamic view for feature Register new technician
        dynamic administrationApp "RegisterNewTechnician" "Dynamic diagram for registering a new technician with specialisation and roles" {
            # 1.-2. Manager submits identification and the system checks access and duplicates
            manager -> webApp "1. Opens technician registration and enters ID and bank account"
            webApp -> accessControl "2. Requests access to register a technician"
            accessControl -> techValidator "3. Forwards registration request for ID validation"

            # 3. Check if technician ID is valid and not already present in the database
            techValidator -> techRepo "4. Checks if technician ID already exists"
            techRepo -> techDb "5. Queries existing technician IDs"

            # 4. Download and process government data for a valid, unique technician ID
            techValidator -> techProvider "6. Requests government data by technician ID"
            techProvider -> govSystem "7. Downloads technician identification data"
            techValidator -> webApp "8. Presents processed government data and requests CV upload"

            # 5-7. Uploads technician CV, system extracts data and send them for manager review
            manager -> webApp "9. Uploads technician CV"
            webApp -> accessControl "10. Requests access to process technician CV"
            accessControl -> techValidator "11. Forwards CV for OCR and LLM extraction by the validator"
            techValidator -> webApp "12. Presents extracted data for manager review"

            # 8-10. Manager reviews and corrects data, assigns specialised group and roles, system saves them
            manager -> webApp "13. Reviews and corrects data, assigns specialised group and roles"
            webApp -> accessControl "14. Requests access to save technician registration"
            accessControl -> techValidator "15. Forwards reviewed data for final validation"
            techValidator -> techRepo "16. Sends validated identification, CV data, group and roles for storage"
            techRepo -> techDb "17. Stores technician, group membership and roles"
            techValidator -> webApp "18. Shows registration confirmation or validation errors"

            autoLayout lr
        }

        # 5. Dynamic view for feature Real time data for track technician
        dynamic dataAnalyzer "RealTimeDataForTrackTech" "Dynamic diagram for real time track technician view" {
            # 1-2. Technician opens app, selects upcoming race, system checks access
            trackTech -> webApp "1. Opens dashboard and selects an upcoming race"
            webApp -> analyzerAccessControl "2. Requests access to view race track data"
            analyzerAccessControl -> maintenanceAnalyzer "3. Validates access to the selected race"

            # 3. System loads basic track information and latest track measurements
            dataLoader -> telemetryRepository "4. Requests basic track info and latest track measurements"
            telemetryRepository -> telemetryTrackDb "5. Queries track time-series database"

            # 4-5. System receives new track measurements and weather data, checks validity and recency
            telemetryGateway -> telemetryCollector "6. Sends new track measurements and weather forecast"
            telemetryCollector -> telemetryValidator "7. Sends data for validity and recency check"
            telemetryValidator -> telemetryRepository "8. Sends validated and cleaned measurements"
            telemetryRepository -> telemetryTrackDb "9. Stores track measurements"
            telemetryRepository -> telemetryCache "10. Updates cache with newest track data"
            dataLoader -> maintenanceAnalyzer "11. Provides track data for comparison with configured limits"

            # 6. System displays data and warnings
            maintenanceAnalyzer -> resultReporter "12. Sends analyzed track data and warnings"
            resultReporter -> webApp "13. Displays track info, measurements, forecast and warnings"

            # 7-8. Technician states track condition, system stores it and confirms
            trackTech -> webApp "14. Reviews data and states track condition (dry, wet, ...)"
            webApp -> analyzerAccessControl "15. Requests access to save track condition"
            analyzerAccessControl -> maintenanceAnalyzer "16. Forwards track condition for the race"
            maintenanceAnalyzer -> resultReporter "17. Sends result of saving track condition"
            resultReporter -> webApp "18. Shows confirmation or error message"

            autoLayout lr
        }

        # 4. Dynamic view for feature Real time data for maintenance technician
        dynamic dataAnalyzer "RealTimeDataFoeMaintenanceTech" "Dynamic diagram for real time maintenance technician view" {
            # 1-3. Technician opens app, selects car, system checks access
            maintenanceTech -> webApp "1. Opens dashboard, selects race and car"
            webApp -> analyzerAccessControl "2. Requests access to view car telemetry"
            analyzerAccessControl -> maintenanceAnalyzer "3. Validates access"

            # 4-7. System loads car sensors and latest measurements
            dataLoader -> carRepo "4. Loads sensor configuration"
            dataLoader -> telemetryRepository "5. Requests latest stored measurements"
            telemetryRepository -> telemetryCarDb "6. Queries time-series database"
            dataLoader -> maintenanceAnalyzer "7. Sends data to analyzer"

            # 8-11. System receives and stores new measurements in real time
            telemetryGateway -> telemetryCollector "8. Sends new real time measurements"
            telemetryCollector -> telemetryValidator "9. Sends data for validation"
            telemetryValidator -> telemetryRepository "10. Sends validated measurements"
            telemetryRepository -> telemetryCache "11. Updates cache"

            # 12-14. System reports data and warnings, technician reviews
            maintenanceAnalyzer -> resultReporter "12. Sends analyzed data and warnings"
            resultReporter -> webApp "13. Displays data, timestamps, and warnings"
            maintenanceTech -> webApp "14. Reviews displayed data to plan pitstop maintenance"

            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #0c2370
                color #ffffff
            }
            element "Software System" {
                background #2158b8
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #438dd5
                color #ffffff
            }
            element "WebBrowserTag" {
                shape WebBrowser
            }
        }
    }

    configuration {
        scope softwaresystem
    }

}
