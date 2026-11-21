workspace "RCT" "RCT System" {

    model {
        # Level 1: Users
        manager = person "Race manager" "Registers cars and technicians, manages the race"
        maintenanceTech = person "Maintenance technician" "Monitors real-time car telemetry to prepare for pitstops"
        trackTech = person "Track technician" "Monitors track telemetry and states track condition"
        driver = person "Driver" "Drives a race car"
        team = person "Team" "Views race results"

        # Level 1: External Systems
        manufacturerSystem = softwareSystem "External manufacturer web/database" "Provides car data" "External"
        govSystem = softwareSystem "Government registry API" "Provides technician data" "External"
        telemetryGateway = softwareSystem "External Telemetry Gateway" "Provides real-time car and track telemetry data" "External"

        # Level 1: Main Software System
        rctTracker = softwareSystem "RCT Tracker" "Tracks cars and track conditions" {
            !docs docs

            # Level 2: Web Application
            webApp = container "Web Application" "Dashboards and forms for managers and technicians" "React" "WebBrowserTag"

            # Level 2: Identity Provider (split from Administration App)
            identityProvider = container "Identity Provider" "Authenticates users and verifies role-based permissions" "Java" {
                authApi = component "Identity API" "Exposes authentication and permission verification endpoints"
                authService = component "Auth & Permission Service" "Verifies user identity, tokens, and access permissions"
                userAuthRepo = component "User Auth Repository" "Reads user credentials, roles, and permissions"
            }

            # Level 2: Car and Sensor Registration (split from Administration App)
            carRegistration = container "Car and Sensor Registration" "Manages registration of race cars and sensor configurations" "Java" {
                carApi = component "Car & Sensor API" "Handles car registration and sensor configuration requests; verifies permissions via Identity Provider"
                carValidator = component "Car Data Validator" "Validates car IDs and cleans downloaded manufacturer data"
                carProvider = component "External Car Data Provider" "Connects to the manufacturer system to download car data"
                carRepo = component "Car and Sensor Repository" "Persists and queries car and sensor data"
                sensorManager = component "Sensor Configuration Manager" "Manages sensor settings for registered cars"
            }

            # Level 2: Technician Registration (split from Administration App)
            techRegistration = container "Technician Registration" "Manages registration of technicians, CV extraction, groups, and roles" "Java" {
                techApi = component "Technician API" "Handles technician registration and CV uploads; verifies permissions via Identity Provider"
                techValidator = component "Technician Data Validator" "Validates technician IDs and extracts CV data using OCR and LLM"
                techProvider = component "External Technician Data Provider" "Connects to the government registry API"
                techRepo = component "Technician Repository" "Persists technician profiles, specializations, groups, and roles"
            }

            # Level 2: Maintenance Data Analyzer
            dataAnalyzer = container "Maintenance Data Analyzer" "Analyzes car and track telemetry data against configured limits" "Java" {
                analyzerApi = component "Analyzer API / Facade" "External entry point; verifies permissions via Identity Provider and routes requests by domain (track, engine, tires, etc.)"
                maintenanceAnalyzer = component "Maintenance Data Analyzer" "Compares telemetry data with configured limits and processes track conditions"
                dataLoader = component "Loader" "Loads telemetry measurements and sensor configurations directly from databases"
            }

            # Level 2: Telemetry Data Capturer
            telemetryCapturer = container "Telemetry Data Capturer" "Collects, validates, and stores real-time data from sensors" "Java" {
                telemetryCollector = component "Telemetry Collector" "Receives incoming telemetry streams"
                telemetryValidator = component "Telemetry Validator" "Checks measurement validity and recency"
                telemetryRepository = component "Telemetry Repository" "Stores validated telemetry measurements to time-series databases"
            }

            # Level 2: Databases
            carDb = container "Car and sensor database" "Stores registered cars and sensor configurations" "PostgreSQL" "Database"
            userDb = container "User database" "Stores users (managers, technicians, drivers), credentials, roles, and specializations" "PostgreSQL" "Database"
            telemetryCarDb = container "Telemetry Car database" "Stores car time-series telemetry data" "InfluxDB" "Database"
            telemetryTrackDb = container "Telemetry Track database" "Stores track time-series telemetry and track condition data" "InfluxDB" "Database"
        }

        # Relationships between users and Web Application
        manager -> webApp "Uses"
        maintenanceTech -> webApp "Uses"
        trackTech -> webApp "Uses"
        driver -> webApp "Views real-time data"
        team -> webApp "Views race results"

        # Relationships between Web Application and backend APIs
        webApp -> authApi "Authenticates users with"
        webApp -> carApi "Sends car and sensor registration requests to"
        webApp -> techApi "Sends technician registration and CV requests to"
        webApp -> analyzerApi "Requests telemetry analysis and submits track conditions"

        # Permission verification via Identity Provider
        carApi -> authApi "Verifies user permissions with"
        techApi -> authApi "Verifies user permissions with"
        analyzerApi -> authApi "Verifies user permissions with"

        # Identity Provider internals
        authApi -> authService "Delegates verification to"
        authService -> userAuthRepo "Loads user credentials and roles from"
        userAuthRepo -> userDb "Reads from"

        # Car and Sensor Registration internals
        carApi -> carValidator "Forwards car registration requests to"
        carApi -> sensorManager "Forwards sensor configuration requests to"
        carValidator -> carProvider "Gets car data from"
        carProvider -> manufacturerSystem "Makes calls to read car data"
        carValidator -> carRepo "Checks IDs and stores car data via"
        sensorManager -> carRepo "Updates sensor configuration via"
        carRepo -> carDb "Reads from and writes to"

        # Technician Registration internals
        techApi -> techValidator "Forwards technician registration and CV requests to"
        techValidator -> techProvider "Gets government data from"
        techProvider -> govSystem "Makes calls to read technician data"
        techValidator -> techRepo "Checks IDs and stores technician data via"
        techRepo -> userDb "Reads from and writes to"

        # Maintenance Data Analyzer internals
        analyzerApi -> maintenanceAnalyzer "Routes domain-specific requests (track, engine, tires) to"
        maintenanceAnalyzer -> dataLoader "Requests data from and saves track conditions via"
        dataLoader -> carDb "Reads sensor configurations from"
        dataLoader -> telemetryCarDb "Reads car telemetry measurements from"
        dataLoader -> telemetryTrackDb "Reads track measurements from and stores track conditions in"

        # Telemetry Data Capturer internals
        telemetryGateway -> telemetryCollector "Sends new measurements"
        telemetryCollector -> telemetryValidator "Sends measurements to"
        telemetryValidator -> telemetryRepository "Sends validated measurements to"
        telemetryRepository -> telemetryCarDb "Stores car telemetry data"
        telemetryRepository -> telemetryTrackDb "Stores track telemetry data"

        # Deployment for Production
        deploymentEnvironment "Production" {

            deploymentNode "Application Server" "" "Ubuntu 26.04 LTS" {
                deploymentNode "Web server" "" "Apache Tomcat 11.0.29" {
                    identityProviderInstance = containerInstance identityProvider
                    carRegistrationInstance = containerInstance carRegistration
                    techRegistrationInstance = containerInstance techRegistration
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
                    userDbInstance = containerInstance userDb
                }

                deploymentNode "Time-Series DB server" "" "InfluxDB 3.12.2" {
                    telemetryCarDbInstance = containerInstance telemetryCarDb
                    telemetryTrackDbInstance = containerInstance telemetryTrackDb
                }
            }

            deploymentNode "External IoT Network" "" "" {
                telemetryGatewayInstance = softwareSystemInstance telemetryGateway
                govSystemInstance = softwareSystemInstance govSystem
                manufacturerSystemInstance = softwareSystemInstance manufacturerSystem
            }
        }

        # Deployment for Development
        deploymentEnvironment "Development" {
            deploymentNode "Developer Workstation" "Local development machine" "Windows 11 / macOS / Linux" {

                deploymentNode "Developer's web browser" "Local web browser" "Google Chrome / Mozilla Firefox" {
                    devWebAppInstance = containerInstance webApp
                }

                deploymentNode "Docker Desktop" "" "Docker Engine" {

                    deploymentNode "Local Java Runtime" "IDE" "" {
                        devIdentityProviderInstance = containerInstance identityProvider
                        devCarRegistrationInstance = containerInstance carRegistration
                        devTechRegistrationInstance = containerInstance techRegistration
                        devDataAnalyzerInstance = containerInstance dataAnalyzer
                        devTelemetryCapturerInstance = containerInstance telemetryCapturer
                    }

                    deploymentNode "Relational DB server" "Local relational DB container" "PostgreSQL 18.7" {
                        devCarDbInstance = containerInstance carDb
                        devUserDbInstance = containerInstance userDb
                    }

                    deploymentNode "Time-Series DB server" "Local time-series DB container" "InfluxDB 3.12.2" {
                        devTelemetryCarDbInstance = containerInstance telemetryCarDb
                        devTelemetryTrackDbInstance = containerInstance telemetryTrackDb
                    }

                    deploymentNode "Telemetry simulator" "Simulates race telemetry data" "Python Telemetry Simulator" {
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

        # Level 3: Component Views (one per L2 application container)
        component identityProvider "IdentityProviderComponents" {
            include *
        }

        component carRegistration "CarRegistrationComponents" {
            include *
        }

        component techRegistration "TechRegistrationComponents" {
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

        # Dynamic Views
        # 1. Dynamic view for feature: Register new car
        dynamic carRegistration "RegisterNewCar" "Dynamic diagram for registering a new car and its sensors" {
            # 1-2. Race manager submits unique car ID
            manager -> webApp "1. Opens dashboard and submits unique car ID"
            webApp -> carApi "2. Sends car registration request"
            carApi -> identityProvider "3. Verifies manager permissions"
            carApi -> carValidator "4. Forwards car registration request"

            # 3. System checks if ID is valid and not already present
            carValidator -> carRepo "5. Checks if car ID already exists"
            carRepo -> carDb "6. Queries existing car IDs"

            # 4. Download basic car info from manufacturer
            carValidator -> carProvider "7. Requests basic car data by ID"
            carProvider -> manufacturerSystem "8. Downloads car info (brand, model, motor, weight)"

            # 5-6. Clean data, store to DB, and return response for redirect
            carValidator -> carRepo "9. Sends cleaned car data for storage"
            carRepo -> carDb "10. Writes new car record"
            carValidator -> carApi "11. Returns registration result"
            carApi -> webApp "12. Returns confirmation and redirects to car info page"

            # 7-8. Manager registers sensors for the new car
            manager -> webApp "13. Fills and submits new sensor configuration (part, unit, frequency)"
            webApp -> carApi "14. Sends sensor configuration request"
            carApi -> identityProvider "15. Verifies manager permissions"
            carApi -> sensorManager "16. Forwards sensor configuration request"
            sensorManager -> carRepo "17. Updates sensor configuration for the car"
            carRepo -> carDb "18. Writes sensor configuration to database"
            sensorManager -> carApi "19. Returns save result"
            carApi -> webApp "20. Returns confirmation or error message"

            autoLayout lr
        }

        # 2. Dynamic view for feature: Register new technician
        dynamic techRegistration "RegisterNewTechnician" "Dynamic diagram for registering a new technician with specialization and roles" {
            # 1-3. Manager submits identification, system verifies permissions and checks duplicates
            manager -> webApp "1. Opens technician registration and enters ID and bank account"
            webApp -> techApi "2. Sends technician identification request"
            techApi -> identityProvider "3. Verifies manager permissions"
            techApi -> techValidator "4. Forwards request for ID validation"
            techValidator -> techRepo "5. Checks if technician ID already exists"
            techRepo -> userDb "6. Queries existing technician IDs"

            # 4. Download government data and return to UI
            techValidator -> techProvider "7. Requests government data by technician ID"
            techProvider -> govSystem "8. Downloads technician identification data"
            techValidator -> techApi "9. Returns processed government data"
            techApi -> webApp "10. Presents government data and requests CV upload"

            # 5-7. Upload CV, extract data via OCR/LLM, return for review
            manager -> webApp "11. Uploads technician CV"
            webApp -> techApi "12. Sends CV for extraction"
            techApi -> identityProvider "13. Verifies manager permissions"
            techApi -> techValidator "14. Extracts CV data using OCR and LLM"
            techValidator -> techApi "15. Returns extracted CV data"
            techApi -> webApp "16. Presents extracted data for manager review"

            # 8-10. Manager reviews data, assigns group/roles, system stores everything
            manager -> webApp "17. Reviews data and assigns specialized group and roles"
            webApp -> techApi "18. Sends final technician registration request"
            techApi -> identityProvider "19. Verifies manager permissions"
            techApi -> techValidator "20. Validates final registration data"
            techValidator -> techRepo "21. Sends validated profile, CV data, group, and roles"
            techRepo -> userDb "22. Stores technician user, group, and roles"
            techValidator -> techApi "23. Returns registration result"
            techApi -> webApp "24. Returns confirmation or validation errors"

            autoLayout lr
        }

        # 3. Dynamic view for feature: Show data for track technician
        dynamic dataAnalyzer "RealTimeDataForTrackTech" "Dynamic diagram for real-time track technician view" {
            # Background: Continuous ingestion of track measurements
            telemetryGateway -> telemetryCapturer "1. Streams new track measurements and weather data"
            telemetryCapturer -> telemetryTrackDb "2. Validates and stores track telemetry"

            # 1-5. Technician requests track data, API verifies access and routes track request
            trackTech -> webApp "3. Opens dashboard and selects an upcoming race"
            webApp -> analyzerApi "4. Requests track measurements and forecast"
            analyzerApi -> identityProvider "5. Verifies technician permissions for selected race"
            analyzerApi -> maintenanceAnalyzer "6. Routes track telemetry request"
            maintenanceAnalyzer -> dataLoader "7. Requests latest track measurements and limits"
            dataLoader -> telemetryTrackDb "8. Queries track time-series database"
            dataLoader -> maintenanceAnalyzer "9. Returns track measurements"

            # 6. Analyzer evaluates limits and returns response directly via API
            maintenanceAnalyzer -> analyzerApi "10. Returns evaluated track data and warnings"
            analyzerApi -> webApp "11. Returns track info, measurements, forecast, and warnings"

            # 7-8. Technician states track condition and system stores it
            trackTech -> webApp "12. Reviews data and submits track condition (dry, wet, ...)"
            webApp -> analyzerApi "13. Sends track condition update"
            analyzerApi -> identityProvider "14. Verifies technician permissions"
            analyzerApi -> maintenanceAnalyzer "15. Routes track condition save request"
            maintenanceAnalyzer -> dataLoader "16. Stores track condition for the race"
            dataLoader -> telemetryTrackDb "17. Writes track condition"
            maintenanceAnalyzer -> analyzerApi "18. Returns save result"
            analyzerApi -> webApp "19. Returns confirmation or error message"

            autoLayout lr
        }

        # 4. Dynamic view for feature: Real time data for maintenance technician
        dynamic dataAnalyzer "RealTimeDataForMaintenanceTech" "Dynamic diagram for real-time maintenance technician view" {
            # Background: Continuous ingestion of car telemetry
            telemetryGateway -> telemetryCapturer "1. Streams real-time car sensor measurements"
            telemetryCapturer -> telemetryCarDb "2. Validates and stores car telemetry"

            # 1-5. Technician selects car, API verifies access and routes request (engine, tires, etc.)
            maintenanceTech -> webApp "3. Opens dashboard, selects active race and car"
            webApp -> analyzerApi "4. Requests real-time car maintenance data"
            analyzerApi -> identityProvider "5. Verifies technician permissions for selected car"
            analyzerApi -> maintenanceAnalyzer "6. Routes car maintenance request (engine, tires, etc.)"

            # 6-8. Loader fetches sensor limits and latest telemetry directly from databases
            maintenanceAnalyzer -> dataLoader "7. Requests sensor configuration and latest measurements"
            dataLoader -> carDb "8. Reads sensor configuration and limits"
            dataLoader -> telemetryCarDb "9. Queries latest car telemetry measurements"
            dataLoader -> maintenanceAnalyzer "10. Returns configuration and telemetry data"

            # 9-11. Analyzer compares with limits and returns data/warnings via API
            maintenanceAnalyzer -> analyzerApi "11. Returns analyzed values, timestamps, and limit warnings"
            analyzerApi -> webApp "12. Returns data and warnings for dashboard display"

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