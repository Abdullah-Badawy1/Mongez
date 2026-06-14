# Mongez — Software Architecture

Authoritative source: [`ARCHITECTURE.puml`](ARCHITECTURE.puml). That
file contains **seven PlantUML diagrams** which together describe the
whole platform from different angles:

| # | Diagram | What it shows |
|---|---|---|
| 1 | **System context** | The three actors (Client, Worker, Admin) and the three runtime surfaces (mobile, dashboard, API) plus external Paymob / FCM. |
| 2 | **Components / deployment** | What lives inside the Docker container, how Gunicorn routes through middleware into the eight Django apps, where SQLite + media volumes live, and how the dashboard and mobile clients connect. |
| 3 | **Domain class diagram** | Every persisted model (User, ServiceCategory, WorkerProfile, Order, OrderAttachment, CommissionPayment, Rating, Favorite, Notification, DeviceToken) and the relationships between them. |
| 4 | **Sequence — login + role redirect** | How the dashboard authenticates and gates `/admin/*` on `role == "admin"`. |
| 5 | **Sequence — place an order** | Multipart upload → Paymob authorize → notification fan-out → worker accept → Paymob capture. |
| 6 | **Sequence — admin dashboard load** | How `/api/admin/dashboard/` aggregates counts and recent orders through the ORM. |
| 7 | **State machine — Order lifecycle** | PENDING → ACCEPTED → COMPLETED with REJECTED / CANCELLED branches and the Paymob action on each transition. |

## Rendering

The diagrams render with any PlantUML toolchain:

```bash
# Standalone JAR
java -jar plantuml.jar docs/ARCHITECTURE.puml          # → 7 PNGs next to the file

# Docker
docker run --rm -v "$PWD:/work" -w /work plantuml/plantuml docs/ARCHITECTURE.puml

# VS Code
# Install: "PlantUML" by jebbs, open ARCHITECTURE.puml, Alt+D to preview.
```

Brand-aligned styling — every diagram uses the **Inter** font and the
Mongez blue (`#3498db`) for arrows so the rendered images match the
mobile app, the web dashboard, and the landing page identity.
