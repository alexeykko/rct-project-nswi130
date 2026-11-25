# RCT Tracker – Software System Architecture

**RCT Tracker** is a software system that continuously collects real-time telemetry data from remote sensors placed on race cars and around the track. It processes incoming measurements to monitor car health and track conditions, provides live dashboards and limit warnings to authorized team members, and supports managing cars, sensor configurations, and technicians.

---

## Running Structurizr Locally

The C4 architecture model (L1–L3 diagrams, dynamic views, deployment views, and embedded documentation) is defined in `structurizr/workspace.dsl` and rendered locally using Docker.

### Prerequisites
* [Docker](https://www.docker.com/) (Docker Engine / Docker Desktop)

### Linux (Bash)
```bash
docker run -it --rm -p 8080:8080 --mount type=bind,source="$(pwd)/structurizr",target=/usr/local/structurizr structurizr/structurizr local
```

Run the command from the repository root (the folder containing `structurizr/`).
Once the container is running, open http://localhost:8080 in your browser to view the interactive C4 diagrams and documentation.

### Windows (PowerShell)
```powershell
docker run -it --rm -p 8080:8080 --mount "type=bind,source=${PWD}\structurizr,target=/usr/local/structurizr" structurizr/structurizr local
```

Run the command from the repository root (the folder containing `structurizr/`).
Once the container is running, open http://localhost:8080 in your browser to view the interactive C4 diagrams and documentation.

### Documentation
Features & Responsibilities Analysis: [features.md](/features.md) – contains the core features, user story breakdowns, and identified system responsibilities.

C4 Architecture Documentation: Source Markdown files are located in structurizr/docs/ and are automatically rendered by Structurizr (accessible via the Documentation tab in the Structurizr web interface at http://localhost:8080).