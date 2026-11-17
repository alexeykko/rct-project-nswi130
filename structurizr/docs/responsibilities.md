# Assignment of Responsibilities to Containers and Components

## Context

RCT Tracker continuously collects data from remote sensors placed on cars and around the track. These captured data are then processed to assess car status and conditions on the track. Real-time car and track status is available to authorized team members. To support this, the system also allows registering new cars, sensors and technicians.

![](embed:SoftwareSystem)

This document maps the functional responsibilities identified in the feature analysis [feature.md](../../features.md) to specific **Level 2 Containers** and **Level 3 Components** of the **RCT Tracker** C4 architecture model.

---

## 1. Overview of Level 2 Containers

| Container | Technology | High-Level Responsibility |
| :--- | :--- | :--- |
| **Web Application** (`webApp`) | React | Presentation layer; renders dashboards, forms, warnings, and handles user redirection. |
| **Administration Application** (`administartionApp`) | Java | Business logic for registering and managing cars, sensors, and technicians. |
| **Maintenance Data Analyzer** (`dataAnalyzer`) | Java | Business logic for loading telemetry and sensor configurations, evaluating limits, and reporting results/warnings. |
| **Telemetry Data Capturer** (`telemetryCapturer`) | Java | Real-time ingestion, validation, caching, and persistence of car and track sensor measurements. |
| **Car and sensor database** (`carDb`) | PostgreSQL | Persistent storage of registered cars and their sensor configurations. |
| **Technician database** (`techDb`) | PostgreSQL | Persistent storage of technician profiles, specializations, groups, and roles. |
| **Telemetry Car database** (`telemetryCarDb`) | InfluxDB | Time-series storage of real-time and historical car sensor measurements. |
| **Telemetry Track database** (`telemetryTrackDb`) | InfluxDB | Time-series storage of real-time and historical track measurements. |

---

## 2. Detailed Responsibility Mapping by Feature

### Feature 1: Register New Car (and Manage Sensors)

* **Web Application (`webApp` – Container)**
  * Serves the web application to the Race Manager.
  * Displays the form for entering the unique manufacturer car identifier.
  * Displays the form for adding and updating sensor configurations (monitored part, unit, frequency).
  * Displays success confirmations or validation/processing error messages.
  * Handles user redirection to the newly created car information page.
* **Administration Application (`administartionApp` – Container)**
  * **Access Control (`accessControl` – Component):** Verifies that the user (Race Manager) has permissions to register cars and manage sensors.
  * **Car data validation (`carValidator` – Component):**
    * Validates the format of the provided unique car identifier.
    * Verifies (via `carRepo`) that the car ID does not already exist in the system.
    * Cleans the raw car data downloaded from the manufacturer into the internal system format.
  * **External car data provider (`carProvider` – Component):**
    * Connects to the external manufacturer system (`manufacturerSystem`).
    * Downloads basic car information (brand, model, motor info, weight) based on the unique identifier.
  * **Sensor Configuration Manager (`sensorManager` – Component):**
    * Validates and processes sensor settings (part, unit, frequency) linked to a specific car.
  * **Car and sensor repository (`carRepo` – Component):**
    * Persists the new car record into `carDb`.
    * Persists and updates sensor configurations linked to the car in `carDb`.
    * Queries `carDb` to check for existing car records and provides sensor configurations to the analyzer.

---

### Feature 2: Register New Technician

* **Web Application (`webApp` – Container)**
  * Serves the web application and displays the form for technician identification (ID, bank account).
  * Provides a file picker for uploading the technician's CV.
  * Displays extracted CV data for the Race Manager's review.
  * Displays forms for assigning the technician to specialized groups and roles.
  * Displays success confirmations or error messages.
* **Administration Application (`administartionApp` – Container)**
  * **Access Control (`accessControl` – Component):** Verifies that the Race Manager has permission to register technicians.
  * **Tech. data validation (`techValidator` – Component):**
    * Validates the provided technician identification.
    * Verifies (via `techRepo`) that the technician does not already exist in the system.
    * Cleans downloaded government registry data and extracted CV data into the internal format.
  * **External Tech. data provider (`techProvider` – Component):**
    * Connects to the external Government registry API (`govSystem`) and downloads personal information using the technician ID.
    * *(Note: Also responsible for interfacing with OCR/LLM services to extract contact and specialization data from uploaded CVs).*
  * **Tech. Repository (`techRepo` – Component):**
    * Stores technician data (ID, personal data, CV data, specialization) into `techDb`.
    * Stores technician group and role assignments into `techDb`.

---

### Feature 3 & 4: Real-Time Data for Maintenance Technician & Track Technician

* **Web Application (`webApp` – Container)**
  * Displays available races, cars, and basic track information.
  * Displays real-time sensor measurements, units, timestamps, and weather/track data on the dashboard.
  * Highlights warnings when values exceed configured limits and identifies the affected car part.
  * Displays error messages when sensor or track data is missing or outdated.
  * Provides a form for the Track Technician to state and submit the current track condition (e.g., dry, wet).
* **Telemetry Data Capturer (`telemetryCapturer` – Container)**
  * **Telemetry Collector (`telemetryCollector` – Component):**
    * Receives incoming streams of real-time car and track measurements from the External Telemetry Gateway (`telemetryGateway`).
  * **Telemetry Validator (`telemetryValidator` – Component):**
    * Checks whether incoming measurements contain valid values and recent timestamps.
    * Links measurements to the corresponding registered car, sensor, or track.
  * **Telemetry Repository (`telemetryRepository` – Component):**
    * Stores validated car telemetry data into `telemetryCarDb` and track telemetry data into `telemetryTrackDb`.
    * Updates the in-memory `telemetryCache` with the newest measurements for low-latency retrieval.
    * Retrieves the latest stored measurements for the analyzer.
  * **Cache (`telemetryCache` – Component):**
    * Holds the most recent telemetry measurements for fast access by `dataAnalyzer`.
* **Maintenance Data Analyzer (`dataAnalyzer` – Container)**
  * **Access Control (`analyzerAccessControl` – Component):**
    * Checks if the Maintenance Technician or Track Technician has permission to view data for the selected race/car.
  * **Loader (`dataLoader` – Component):**
    * Loads registered sensors and their limits for the selected car from `carRepo`.
    * Retrieves the latest car and track measurements from `telemetryRepository` (and `telemetryCache`).
  * **Maintenance Data Analyzer (`maintenanceAnalyzer` – Component):**
    * Filters measurements relevant to car maintenance and track condition assessment.
    * Compares incoming measurements against configured sensor limits.
    * Detects out-of-limit values, identifies the related car part, and flags missing or stale data.
  * **Result Reporter (`resultReporter` – Component):**
    * Sends processed measurements, limit warnings, and missing-data alerts back to `webApp`.