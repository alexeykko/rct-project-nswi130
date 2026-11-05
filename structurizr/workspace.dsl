workspace "RCT" "RCT System" {

    model {
        manager = person "Race manager" "Registers cars and technicians, manage the race"
        maintenanceTech = person "Maintenance technician" "Monitors realtime data to prepare for pitstops"
        trackTech = person "Track technician" "Monitors track condition"
        driver = person "Driver" "Drives a race car"
        team = person "Team" "Views race results"

        manufacturerSystem = softwareSystem "External manufacturer web/database" "Provides car data" "External"
        govSystem = softwareSystem "Government registry API" "Provides technician data" "External"
        telemetryGateway = softwareSystem "External Telemetry Gateway" "Provides telemetry data" "External"

        rctTracker = softwareSystem "RCT Tracker" "Tracks cars maintenance" {
            
            webApp = container "Web Application" "Dashboards for managers and technicians" "React"
            
            app = container "Application" "Processes data and validates" "Java/Spring" {
                accessControl = component "Access Control" "Checks permissions"
                
                carValidator = component "Car data validation" "Validates car IDs"
                carProvider = component "External car data provider" "Connects to manufacturer"
                carRepo = component "Car and sensor repository" "Persists car and sensor data"
                sensorManager = component "Sensor Configuration Manager" "Manages sensor settings"
                
                techValidator = component "Tech. data validation" "Validates technician IDs"
                techProvider = component "External Tech. data provider" "Connects to government registry"
                techRepo = component "Tech. Repository" "Persists technician data"
                
                driverManager = component "Driver Management" "Registers drivers"
                
                telemetryCollector = component "Telemetry Collector" "Receives measurements"
                telemetryValidator = component "Telemetry Validator" "Checks data validity"
                maintenanceAnalyzer = component "Maintenance Data Analyzer" "Compares data with limits"
                
                raceReporter = component "Race Result Reporter" "Generates race reports"
            }
            
            carDb = container "Car and sensor database" "Stores car and sensor data" "PostgreSQL" "Database"
            techDb = container "Technician database" "Stores technician data" "PostgreSQL" "Database"
            telemetryDb = container "Telemetry database" "Stores time-series data" "InfluxDB" "Database"
            driverDb = container "Driver database" "Stores driver data" "PostgreSQL" "Database"
            raceDb = container "Race database" "Stores race results" "PostgreSQL" "Database"
        }

        manager -> webApp "Uses"
        maintenanceTech -> webApp "Uses"
        trackTech -> webApp "Uses"
        driver -> webApp "Views realtime data"
        team -> webApp "Views race results"

        webApp -> accessControl "Requests access"
        webApp -> carValidator "Registers car"
        webApp -> sensorManager "Manages sensors"
        webApp -> techValidator "Registers technician"
        webApp -> driverManager "Registers driver"
        webApp -> raceReporter "Requests race results"

        accessControl -> maintenanceAnalyzer "Allows telemetry view"
        accessControl -> raceReporter "Allows results view"

        carValidator -> carProvider "Gets data from"
        carProvider -> manufacturerSystem "Makes calls to read data"
        carValidator -> carRepo "Sends data to"
        sensorManager -> carRepo "Updates sensor config"
        carRepo -> carDb "Writes to"
        techValidator -> techProvider "Gets data from"
        techProvider -> govSystem "Makes calls to read data"
        techValidator -> techRepo "Sends data to"
        techRepo -> techDb "Writes to"

        driverManager -> driverDb "Writes to"
        raceReporter -> raceDb "Reads from"

        telemetryGateway -> telemetryCollector "Sends new measurements"
        telemetryCollector -> telemetryValidator "Sends measurements to"
        telemetryValidator -> maintenanceAnalyzer "Sends validated measurements to"
        
        maintenanceAnalyzer -> carRepo "Loads sensor configuration"
        maintenanceAnalyzer -> telemetryDb "Stores/retrieves measurements"
        maintenanceAnalyzer -> webApp "Sends measurements and warnings"
    }

    views {
        systemContext rctTracker "SoftwareSystem" {
            include *
        }

        container rctTracker "Containers" {
            include *
        }

        component app "Components" {
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
        }
    }

    configuration {
        scope softwaresystem
    }

}