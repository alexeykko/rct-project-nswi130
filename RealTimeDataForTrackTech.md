# Dynamic View: Real-Time Data for Track Technician

**View key:** `RealTimeDataForTrackTech` (defined in [workspace.dsl](structurizr/workspace.dsl), exported as [F3_DataForTrackTech.png](structurizr/images/F3_DataForTrackTech.png))

The Track Technician checks the track conditions before a race starts. They view live track measurements and the weather forecast, get warnings about values outside the configured limits, and then state the track condition (dry, wet, ...). The feature is described in [features.md](features.md) under *Show data for track technician*.

## Participants

| Element | Role in this flow |
| :--- | :--- |
| Track technician | Selects a race, reviews the data and submits the track condition |
| External Telemetry Gateway | Streams track measurements and weather data |
| Telemetry Data Capturer | Validates incoming track data and stores it in `telemetryTrackDb` |
| Web Application | Dashboard and form for the technician |
| Analyzer API / Facade | Entry point; verifies permissions and routes track requests |
| Identity Provider | Checks that the technician may access the selected race |
| Maintenance Data Analyzer (component) | Compares track measurements with configured limits |
| Loader | Reads track data and writes the stated track condition |
| Telemetry Track database | Stores track measurements and track conditions |

## Flow

1. **Background ingestion (steps 1–2):** The External Telemetry Gateway continuously sends track measurements and weather data. The Telemetry Data Capturer validates them and stores them in the Telemetry Track database.
2. **Viewing track data (steps 3–11):** The technician opens the dashboard and selects an upcoming race. The Analyzer API checks the technician's permissions with the Identity Provider and passes the request to the analyzer. The Loader reads the latest track measurements, the analyzer compares them with the configured limits, and the dashboard shows the measurements, forecast and warnings.
3. **Stating the track condition (steps 12–19):** The technician reviews the data and submits the track condition. Permissions are checked again, the Loader writes the condition to the Telemetry Track database, and the technician sees a confirmation or an error message.

## Notes

* Data ingestion and data viewing are independent: the Capturer writes into the time-series database, and the Analyzer only reads the newest stored data when the technician asks for it.
* Permissions are verified on every request (viewing and saving), not only when the dashboard is opened.
