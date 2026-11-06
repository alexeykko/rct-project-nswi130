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

            # Level 2: web application
            webApp = container "Web Application" "Dashboards for managers and technicians" "React" "WebBrowserTag"

            # Level 2: business logic and Level 3 components
            administartionApp = container "Administration Application" "Validates data and stores them" "Java" {
                accessControl = component "Access Control" "Checks permissions"

                carValidator = component "Car data validation" "Validates car IDs"
                carProvider = component "External car data provider" "Connects to manufacturer"
                carRepo = component "Car and sensor repository" "Persists car and sensor data"
                sensorManager = component "Sensor Configuration Manager" "Manages sensor settings"

                techValidator = component "Tech. data validation" "Validates technician IDs"
                techProvider = component "External Tech. data provider" "Connects to government registry"
                techRepo = component "Tech. Repository" "Persists technician data"

                #driverManager = component "Driver Management" "Registers drivers"

                #maintenanceAnalyzer = component "Maintenance Data Analyzer" "Compares data with limits"

                #raceReporter = component "Race Result Reporter" "Generates race reports"
            }

            dataAnalyzer = container "Maintenance Data Analyzer" "Loads and analyzes data" "Java" {
                analyzerAccessControl = component "Access Controll" "Checks permissions"
                maintenanceAnalyzer = component "Maintenance Data Analyzer" "Compares data with limits")
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
        component administartionApp "Components" {
            include *
        }

        component telemetryCapturer "CollectorComponents" {
            include *
        }

        component dataAnalyzer "AnalyzerComponents" {
            include *
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