# Assignment of Responsibilities to Containers and Components

## Context

RCT Tracker continuously collects data from remote sensors placed on cars and around the track. These captured data are then processed to assess car status and conditions on the track. Real-time car and track status is available to authorized team members. To support this, the system also allows registering new cars, sensors and technicians.

![](embed:SoftwareSystem)

This document maps the functional responsibilities identified in the feature analysis [features.md](../../features.md) to specific **Level 2 Containers** and **Level 3 Components** of the **RCT Tracker** C4 architecture model.

---

## 1. Level 2 Architecture and Architectural Styles

![](embed:Containers)

### Applied Architectural Styles

#### Level 2 (Container Level): Service-Based Architecture Style
At the container level, RCT Tracker follows the **Service-Based Architecture** style (a distributed architecture style). The backend is decomposed into five main services (`Identity Provider`, `Car and Sensor Registration`, `Technician Registration`, `Maintenance Data Analyzer`, and `Telemetry Data Capturer`) behind a single-page `Web Application` frontend.

* **Why Service-Based instead of Monolithic:** Separating the system into independently deployable services allows isolating high-load parts of the system. Specifically, `Telemetry Data Capturer` can be deployed on a dedicated capture server to handle continuous real-time sensor streams without bigger delays.
However, unlike strict microservices, our services share databases where it simplifies data access and avoids unnecessary network hops:
  * `User database` (`userDb`) is shared between `Technician Registration` (writes technician accounts and roles) and `Identity Provider` (reads credentials and roles for verification).
  * `Car and sensor database` (`carDb`) is shared between `Car and Sensor Registration` (writes car and sensor configurations) and `Maintenance Data Analyzer` (reads sensor limits).
  * `Telemetry Car database` (`telemetryCarDb`) and `Telemetry Track database` (`telemetryTrackDb`) are shared between `Telemetry Data Capturer` (writes measurements) and `Maintenance Data Analyzer` (read-heavy analysis; additionally writes track conditions stated by the Track Technician into `telemetryTrackDb`), separating the high-volume write workload from the read workload.
* **Centralized Authentication and Authorization:** Instead of duplicating access control logic inside every service, a dedicated `Identity Provider` container authenticates users from `Web Application` and verifies role-based permissions for all domain services.

---

## 2. Overview of Level 2 Containers

| Container | Technology | High-Level Responsibility |
| :--- | :--- | :--- |
| **Web Application** (`webApp`) | React | Presentation layer; renders dashboards, forms, warnings, and handles user redirection. |
| **Identity Provider** (`identityProvider`) | Java | Centralized authentication of users and verification of role-based permissions across all services. |
| **Car and Sensor Registration** (`carRegistration`) | Java | Business logic for validating, registering, and managing race cars and their sensor configurations. |
| **Technician Registration** (`techRegistration`) | Java | Business logic for registering technicians, extracting CV data (OCR/LLM), and assigning groups and roles. |
| **Maintenance Data Analyzer** (`dataAnalyzer`) | Java | Routes domain-specific analysis requests, loads telemetry and sensor configurations directly from databases, evaluates limits, and returns results/warnings. |
| **Telemetry Data Capturer** (`telemetryCapturer`) | Java | Real-time pipeline for ingestion, validation, and persistence of car and track sensor measurements. |
| **Car and sensor database** (`carDb`) | PostgreSQL | Persistent storage of registered cars and their sensor configurations. |
| **User database** (`userDb`) | PostgreSQL | Persistent storage of system users (managers, technicians, drivers), credentials, specializations, groups, and roles. |
| **Telemetry Car database** (`telemetryCarDb`) | InfluxDB | Time-series storage of real-time and historical car sensor measurements. |
| **Telemetry Track database** (`telemetryTrackDb`) | InfluxDB | Time-series storage of real-time and historical track measurements and stated track conditions. |

---

## 3. Detailed Responsibility Mapping by Feature

### Cross-Cutting: Authentication & Access Control

* **Identity Provider (`identityProvider` – Container)**
  * **Identity API (`authApi` – Component):** Exposes endpoints for user login (from `webApp`) and permission verification (from `carApi`, `techApi`, and `analyzerApi`).
  * **Auth & Permission Service (`authService` – Component):** Authenticates user credentials/tokens and verifies whether a user has the required role to perform a requested action or view a specific race/car.
  * **User Auth Repository (`userAuthRepo` – Component):** Reads user credentials, roles, and permissions from `userDb`.

---

### Feature 1: Register New Car (and Manage Sensors)

* **Web Application (`webApp` – Container)**
  * Serves the web application to the Race Manager.
  * Displays the form for entering the unique manufacturer car identifier.
  * Displays the form for adding and updating sensor configurations (monitored part, unit, frequency).
  * Displays success confirmations or validation/processing error messages.
  * Handles user redirection to the newly created car information page.
* **Car and Sensor Registration (`carRegistration` – Container)**
  * **Car & Sensor API (`carApi` – Component):**
    * Receives car registration and sensor configuration requests from `webApp`.
    * Verifies that the user (Race Manager) has permissions via `Identity Provider` (`authApi`).
    * Returns registration results, confirmation, or error messages back to `webApp`.
  * **Car Data Validator (`carValidator` – Component):**
    * Validates the format of the provided unique car identifier.
    * Verifies (via `carRepo`) that the car ID does not already exist in the system.
    * Cleans the raw car data downloaded from the manufacturer into the internal system format.
  * **External Car Data Provider (`carProvider` – Component):**
    * Connects to the external manufacturer system (`manufacturerSystem`).
    * Downloads basic car information (brand, model, motor info, weight) based on the unique identifier.
  * **Sensor Configuration Manager (`sensorManager` – Component):**
    * Validates and processes sensor settings (part, unit, frequency) linked to a specific car.
  * **Car and Sensor Repository (`carRepo` – Component):**
    * Persists the new car record into `carDb`.
    * Persists and updates sensor configurations linked to the car in `carDb`.
    * Queries `carDb` to check for existing car records.

---

### Feature 2: Register New Technician

* **Web Application (`webApp` – Container)**
  * Serves the web application and displays the form for technician identification (ID, bank account).
  * Provides a file picker for uploading the technician's CV.
  * Displays extracted CV data for the Race Manager's review.
  * Displays forms for assigning the technician to specialized groups and roles.
  * Displays success confirmations or error messages.
* **Technician Registration (`techRegistration` – Container)**
  * **Technician API (`techApi` – Component):**
    * Receives technician registration, CV upload, and final assignment requests from `webApp`.
    * Verifies that the Race Manager has permission via `Identity Provider` (`authApi`).
    * Returns processed government data, extracted CV data, and confirmation/error messages back to `webApp`.
  * **Technician Data Validator (`techValidator` – Component):**
    * Validates the provided technician identification.
    * Verifies (via `techRepo`) that the technician does not already exist in the system.
    * Cleans downloaded government registry data and extracts/cleans CV data (using OCR and LLM) into the internal format.
  * **External Technician Data Provider (`techProvider` – Component):**
    * Connects to the external Government registry API (`govSystem`) and downloads personal information using the technician ID.
  * **Technician Repository (`techRepo` – Component):**
    * Stores technician data (ID, personal data, CV data, specialization) into `userDb`.
    * Stores technician group and role assignments into `userDb`.

---

### Feature 3 & 4: Real-Time Data for Track Technician & Maintenance Technician

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
* **Maintenance Data Analyzer (`dataAnalyzer` – Container)**
  * **Analyzer API / Facade (`analyzerApi` – Component):**
    * Acts as the external entry point for dashboard requests from `webApp`.
    * Verifies via `Identity Provider` (`authApi`) whether the Maintenance Technician or Track Technician has permission to view data for the selected race/car or update track conditions.
    * Identifies the request domain (e.g., track, engine, tires) and routes it to `maintenanceAnalyzer`.
    * Returns analyzed measurements, warnings, and confirmation/error messages directly in the request response to `webApp`.
  * **Loader (`dataLoader` – Component):**
    * Loads registered sensors and their configured limits directly from `carDb`.
    * Retrieves the latest car telemetry measurements directly from `telemetryCarDb` and track measurements from `telemetryTrackDb`.
    * Stores the track condition stated by the Track Technician into `telemetryTrackDb`.
  * **Maintenance Data Analyzer (`maintenanceAnalyzer` – Component):**
    * Filters measurements relevant to car maintenance and track condition assessment.
    * Compares incoming measurements against configured sensor limits.
    * Detects out-of-limit values, identifies the related car part, and flags missing or stale data.

---

## 4. Deployment Architecture

### Production Environment

![](embed:ProductionDeployment)

The production deployment distributes the system across dedicated physical or virtual servers running **Ubuntu 26.04 LTS** to ensure performance isolation and reliability during live races:

* **Capture Server (`Telemetry Data Capturer`):** Deployed on a standalone server to handle the high amount of incoming real-time sensor streams from the `External Telemetry Gateway` (measured values by track and car sensors). Isolating this prevents telemetry spikes from overloading user-facing services or slowing down dashboard responsiveness.
* **Application Server (`Apache Tomcat 11.0.29`):** Hosts the four request-response backend services (`Identity Provider`, `Car and Sensor Registration`, `Technician Registration`, and `Maintenance Data Analyzer`). Because these services handle lower, user-driven requests, putting them together simplifies operations while keeping logical service boundaries intact.
* **Database Server:** Hosts both the relational database engine (**PostgreSQL 18.7** for `Car and sensor database` and `User database`) and the time-series database engine (**InfluxDB 3.12.2** for `Telemetry Car database` and `Telemetry Track database`).
* **Client & External Nodes:** `Web Application` runs in the `User's web browser`, while external dependencies (`External Telemetry Gateway`, `Government registry API`, and `External manufacturer web/database`) are outside the system boundary.

### Development Environment

![](embed:DevelopmentDeployment)

The development deployment puts the entire stack onto a single **Developer Workstation** (`Windows 11 / macOS / Linux`) to enable fast, cost-free local development and debugging:

* **Local Execution & Debugging (`Local Java Runtime`):** Without live race traffic, there is no need for a separate Capture Server. All five Java backend services run locally so developers can step through code and test changes immediately.
* **Databases via Docker (`Docker Desktop`):** The relational (**PostgreSQL 18.7**) and time-series (**InfluxDB 3.12.2**) databases run as local containers using the exact same engine versions as Production.
* **Telemetry Simulation (`Python Telemetry Simulator`):** Since developers do not have access to live race cars and track sensors locally, `External Telemetry Gateway` is replaced by a simulator generating telemetry streams, while `Government registry API` and `External manufacturer web/database` remain external endpoints.
