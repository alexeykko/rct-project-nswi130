workspace "RCT" "RCT System" {

    model {
        manager = person "Race manager" "Registers cars and technicians, manage the race"
        maintenanceTech = person "Maintenance technician" "Monitors realtime data to prepare for pitstops"
        trackTech = person "Track technician" "Monitors track condition"
        driver = person "Deiver" "Drives a race car "

        rctTracker = softwareSystem "RCT Tracker" "Tracks cars maintenance" {}

        maintenanceTech -> rctTracker "Views realtime data"
        trackTech -> rctTracker "Views track data"
        manager -> rctTracker "Register cars and technicians"
    }

    views {
        systemContext rctTracker "Diagram1" {
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
        }
    }

    configuration {
        scope softwaresystem
    }

}