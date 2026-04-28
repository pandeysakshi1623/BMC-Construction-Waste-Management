# Smart Waste Monitor — Complete Project Guide
### BMC Construction Waste Management System

> **Everything you need to understand, set up, and rebuild this project from scratch.**
> Covers architecture, every file, every API, every screen, all logic, and all decisions.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [System Architecture](#3-system-architecture)
4. [Prerequisites & Installation](#4-prerequisites--installation)
5. [Project Folder Structure](#5-project-folder-structure)
6. [Environment Configuration](#6-environment-configuration)
7. [Database — MongoDB](#7-database--mongodb)
8. [Backend — FastAPI](#8-backend--fastapi)
9. [Frontend — Flutter](#9-frontend--flutter)
10. [All API Endpoints](#10-all-api-endpoints)
11. [Authentication & JWT Flow](#11-authentication--jwt-flow)
12. [4 User Roles — Complete Workflows](#12-4-user-roles--complete-workflows)
13. [Pickup Lifecycle](#13-pickup-lifecycle)
14. [Live Location Tracking](#14-live-location-tracking)
15. [QR Code System](#15-qr-code-system)
16. [Image Upload System](#16-image-upload-system)
17. [Notification System](#17-notification-system)
18. [Driver Rating System](#18-driver-rating-system)
19. [State Management](#19-state-management)
20. [Navigation & Route Guards](#20-navigation--route-guards)
21. [Design System](#21-design-system)
22. [Running the Project](#22-running-the-project)
23. [Default Credentials](#23-default-credentials)
24. [Seeding the BMC Admin](#24-seeding-the-bmc-admin)
25. [Switching Environments](#25-switching-environments)
26. [Common Errors & Fixes](#26-common-errors--fixes)
27. [Optimization Decisions](#27-optimization-decisions)

---

## 1. Project Overview

**Smart Waste Monitor** is a full-stack mobile + web application that digitises construction waste management for the **Brihanmumbai Municipal Corporation (BMC)**, Mumbai, India.

### Problem it solves
Construction sites generate massive amounts of waste. Without a digital system:
- No tracking of waste disposal
- No accountability for contractors
- Citizens cannot report illegal dumping
- BMC has no real-time visibility

### What it does
Connects **4 roles** on a single platform:

| Role | Who | What they do |
|------|-----|-------------|
| **Contractor** | Construction company | Registers sites, schedules pickups, uploads disposal proof |
| **Citizen** | Mumbai resident | Reports waste complaints near construction sites |
| **Driver** | Waste truck driver | Accepts pickups, tracks location, uploads disposal proof |
| **BMC Official** | Government officer | Monitors everything, issues penalties, approves trucks |

### Key features
- QR code per construction site — scan to auto-fill details
- Live GPS tracking of drivers during active pickups
- Photo proof of waste disposal (mandatory before completion)
- Penalty system for non-compliant contractors
- Email notifications on every key event
- Role-based access — each role sees only their screens
- Real-time dashboard updates (15-second polling)

---

## 2. Tech Stack

### Frontend
| Library | Version | Purpose |
|---------|---------|---------|
| Flutter SDK | 3.x+ | Cross-platform UI (Android, iOS, Web, Desktop) |
| Dart | >=3.0.0 | Programming language |
| provider | ^6.1.2 | State management (ChangeNotifier pattern) |
| http | ^1.2.1 | REST API calls |
| image_picker | ^1.1.2 | Camera / gallery photo selection |
| geolocator | ^12.0.0 | GPS location, permission handling |
| mobile_scanner | ^5.2.3 | QR code scanning via camera |
| shared_preferences | ^2.3.2 | Persist JWT token + session locally |
| url_launcher | ^6.3.0 | Launch phone dialer for driver calls |
| qr_flutter | ^4.1.0 | Render QR code image from string |
| share_plus | ^10.1.4 | Share QR code image |
| path_provider | ^2.1.4 | File system paths |
| geocoding | ^3.0.0 | Convert lat/lng to human-readable address |

### Backend
| Library | Version | Purpose |
|---------|---------|---------|
| FastAPI | >=0.111.0 | Async REST API framework |
| Uvicorn | >=0.29.0 | ASGI server to run FastAPI |
| Motor | >=3.4.0 | Async MongoDB driver |
| PyMongo | >=4.6.2 | MongoDB sync utilities |
| Pydantic | >=2.7.1 | Request/response validation |
| passlib | >=1.7.4 | Password hashing |
| bcrypt | >=4.0.0,<5.0.0 | bcrypt hashing algorithm |
| python-jose | >=3.3.0 | JWT creation and verification |
| python-multipart | >=0.0.9 | File upload parsing |
| qrcode | >=7.4.2 | Generate QR code PNG images |
| Pillow | >=10.4.0 | Image processing (required by qrcode) |
| python-dotenv | >=1.0.0 | Load .env file into environment |

### Database
| Tool | Version | Purpose |
|------|---------|---------|
| MongoDB Community | 6.x+ | NoSQL document database |
| MongoDB Compass | any | GUI to inspect data (optional) |

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │Contractor│  │ Citizen  │  │  Driver  │  │ BMC Official │   │
│  │Dashboard │  │Complaints│  │ Pickups  │  │  Dashboard   │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘   │
│       │              │              │                │            │
│  ┌────▼──────────────▼──────────────▼────────────────▼───────┐  │
│  │                    ApiService (http)                        │  │
│  │              static const _base = 'http://...'             │  │
│  └────────────────────────┬────────────────────────────────────┘  │
│                            │ HTTP/REST + JWT Bearer               │
└────────────────────────────┼─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                      FASTAPI BACKEND                              │
│                    uvicorn main:app --port 8000                   │
│                                                                   │
│  /auth    /sites   /pickups   /bmc   /citizen  /alerts           │
│  /profile  /driver                                                │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    MongoDB (Motor async)                     │ │
│  │  contractors  sites  pickups  penalties  citizens            │ │
│  │  citizen_queries  officials  alerts  proof_history           │ │
│  │  driver_locations  driver_ratings                            │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  /static/  ← uploaded images served as static files              │
└───────────────────────────────────────────────────────────────────┘
```

### Data flow for a typical pickup
```
Contractor schedules pickup
        │
        ▼ POST /pickups/request
Backend creates pickup (status: Pending)
        │
        ▼ Email sent to contractor
Driver sees pickup in list
        │
        ▼ PATCH /pickups/{id}/status  {status: "Accepted"}
Driver starts → PATCH status: "In Progress"
        │
        ▼ Driver GPS sent every 8s → POST /driver/location
Contractor sees live location in DriverInfoCard
        │
        ▼ Driver arrives → PATCH status: "Arrived"
Contractor upload screen UNLOCKS
        │
        ▼ Driver uploads photo → POST /pickups/upload-proof
        ▼ PATCH status: "Completed"
Contractor rates driver → POST /driver/rating
```

---

## 4. Prerequisites & Installation

### Required tools

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | 3.x+ | https://docs.flutter.dev/get-started/install |
| Python | 3.10+ | https://www.python.org/downloads/ |
| MongoDB Community | 6.x+ | https://www.mongodb.com/try/download/community |
| Git | any | https://git-scm.com/downloads |

---

### macOS Setup

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Flutter
brew install --cask flutter
flutter doctor
# Fix any issues shown before continuing

# 3. Install Python 3
brew install python@3.11
python3 --version   # should show 3.11.x

# 4. Install MongoDB
brew tap mongodb/brew
brew install mongodb-community@7.0
brew services start mongodb-community@7.0

# Verify MongoDB is running
mongosh --eval "db.runCommand({ connectionStatus: 1 })"

# 5. Clone the repo
git clone <repository-url>
cd BMC-Construction-Waste-Management

# 6. Python virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 7. Flutter dependencies
flutter pub get
```

---

### Windows Setup

```cmd
:: 1. Install Flutter
:: Download from https://docs.flutter.dev/get-started/install/windows
:: Extract to C:\flutter
:: Add C:\flutter\bin to PATH (System Environment Variables)
flutter doctor

:: 2. Install Python 3
:: Download from https://www.python.org/downloads/windows/
:: CHECK "Add Python to PATH" during install
python --version
pip --version

:: 3. Install MongoDB
:: Download from https://www.mongodb.com/try/download/community
:: Run installer (Complete setup) — runs as Windows Service automatically
mongosh --eval "db.runCommand({ connectionStatus: 1 })"

:: 4. Clone the repo
git clone <repository-url>
cd BMC-Construction-Waste-Management

:: 5. Python virtual environment
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

:: 6. Flutter dependencies
flutter pub get
```

---

## 5. Project Folder Structure

```
BMC-Construction-Waste-Management/
│
├── main.py                    FastAPI app entry point
├── database.py                MongoDB connection + collections + indexes
├── requirements.txt           Python dependencies
├── pubspec.yaml               Flutter dependencies
├── .env                       Environment variables (SECRET_KEY, MONGO_DETAILS, SMTP)
│
├── routers/                   FastAPI route handlers (one file per domain)
│   ├── auth.py                Contractor + Driver signup/login
│   ├── citizen.py             Citizen signup/login/complaints
│   ├── sites.py               Site registration, QR, proof upload
│   ├── pickups.py             Pickup CRUD + status updates + proof
│   ├── bmc.py                 BMC login, QR scan, penalties, dashboard
│   ├── alerts.py              Alert fetch endpoints
│   ├── profile.py             Profile read/update/delete
│   └── driver.py              Driver location + rating
│
├── models/                    Pydantic request/response models
│   ├── contractor.py          ContractorCreate, DriverCreate, ContractorLogin
│   ├── site.py                SiteCreate, Site
│   ├── citizen.py             CitizenCreate, CitizenLogin, CitizenQuery
│   ├── bmc.py                 BMCOfficialLogin, PenaltyRequest, TruckApprovalRequest
│   └── token.py               Token, TokenData
│
├── utils/
│   ├── security.py            JWT creation/verification, bcrypt hashing
│   ├── deps.py                FastAPI auth dependencies (get_current_user, get_current_citizen)
│   ├── notify.py              Email + DB alert writer
│   ├── qr_generator.py        QR code PNG generation
│   └── scheduler.py           24h background penalty alert job
│
├── uploads/                   Uploaded images stored here (served as /static/)
│
└── lib/                       Flutter source code
    ├── main.dart              App entry, MultiProvider, route map, route guards
    │
    ├── models/
    │   ├── user_model.dart    UserModel (id, email, role, token, contractorId)
    │   ├── site_model.dart    SiteModel (id, name, location, area, waste, qrCode)
    │   ├── pickup_model.dart  PickupModel + PickupStatus enum (6 states)
    │   └── complaint_model.dart ComplaintModel (id, description, location, status)
    │
    ├── providers/
    │   ├── auth_provider.dart  Login/logout, JWT, SharedPreferences session
    │   ├── role_provider.dart  Syncs role from AuthProvider for UI
    │   └── pickup_provider.dart Driver pickup list, optimistic updates
    │
    ├── services/
    │   ├── api_service.dart    All HTTP calls (single _base URL constant)
    │   ├── pickup_service.dart Driver-specific pickup calls (own _base)
    │   ├── location_service.dart GPS permission + getCurrentPosition + reverseGeocode
    │   ├── image_service.dart  image_picker wrapper, web/mobile preview
    │   ├── notification_service.dart SnackBar notifications (global key)
    │   └── call_service.dart   url_launcher phone dialer
    │
    ├── screens/
    │   ├── splash_screen.dart  Session restore → route to correct dashboard
    │   ├── auth/
    │   │   ├── login_screen.dart       Role selector + credentials
    │   │   ├── signup_screen.dart      Role-aware registration form
    │   │   └── role_selection_screen.dart  (legacy, not used in main flow)
    │   ├── contractor/
    │   │   ├── contractor_dashboard_screen.dart  Sites list + penalties + alerts tabs
    │   │   ├── site_registration_screen.dart     Register new site → QR generated
    │   │   ├── qr_display_screen.dart            Show/share site QR code
    │   │   ├── pickup_scheduling_screen.dart     Date picker (future dates only)
    │   │   ├── upload_proof_screen.dart          Photo + quantity (locked until driver arrives)
    │   │   ├── proof_history_screen.dart         Past proof uploads for a site
    │   │   └── alerts_screen.dart                Real-time alerts from DB
    │   ├── citizen/
    │   │   ├── complaints_screen.dart            List of submitted complaints
    │   │   ├── report_complaint_screen.dart      Submit complaint (QR or manual)
    │   │   ├── citizen_qr_scanner_screen.dart    Scan site QR to auto-fill
    │   │   └── awareness_screen.dart             Waste education content
    │   ├── driver/
    │   │   ├── pickups_screen.dart               Tabbed pickup list + summary bar
    │   │   ├── qr_scanner_screen.dart            Validate site QR before starting
    │   │   └── upload_disposal_screen.dart       Upload disposal proof photo
    │   ├── bmc/
    │   │   ├── bmc_dashboard_screen.dart         Stats + quick actions + complaints preview
    │   │   ├── bmc_qr_scanner_screen.dart        Scan site QR → view details + add penalty
    │   │   ├── bmc_truck_approval_screen.dart    All pickups (Ongoing/Upcoming/Past tabs)
    │   │   ├── bmc_complaints_screen.dart        All citizen complaints + resolve actions
    │   │   └── bmc_alerts_screen.dart            System-wide alerts
    │   └── profile/
    │       └── profile_screen.dart               Universal profile (adapts by role)
    │
    ├── widgets/
    │   ├── status_chip.dart       Coloured status badge (Pending/Accepted/etc.)
    │   ├── loading_button.dart    ElevatedButton with spinner
    │   ├── driver_info_card.dart  Driver details + live location (polls every 10s)
    │   ├── image_picker_box.dart  Reusable image picker UI
    │   └── app_scaffold.dart      (legacy wrapper)
    │
    └── utils/
        ├── app_theme.dart         All design tokens (colors, spacing, typography)
        └── route_guard.dart       guardRoute() helper for manual route checks
```

---

## 6. Environment Configuration

Create a `.env` file in the project root:

```env
# MongoDB connection string
MONGO_DETAILS=mongodb://localhost:27017

# JWT secret — CHANGE THIS in production
# Generate: python -c "import secrets; print(secrets.token_hex(32))"
SECRET_KEY=change-me-to-a-long-random-secret-in-production

# Token expiry in minutes (120 = 2 hours)
TOKEN_EXPIRE_MINUTES=120

# SMTP Email (optional — prints to console if not set)
# For Gmail: generate App Password at https://myaccount.google.com/apppasswords
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_16_char_app_password
SMTP_FROM=BMC Waste Monitor <your_email@gmail.com>
```

The backend loads this automatically via `python-dotenv`:
```python
# main.py
from dotenv import load_dotenv
load_dotenv()  # reads .env into os.environ
```

`utils/security.py` reads:
```python
SECRET_KEY = os.getenv("SECRET_KEY", "change-me-in-production")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("TOKEN_EXPIRE_MINUTES", "120"))
```

---

## 7. Database — MongoDB

### Connection (database.py)

```python
from motor.motor_asyncio import AsyncIOMotorClient

client = AsyncIOMotorClient(
    os.getenv("MONGO_DETAILS", "mongodb://localhost:27017"),
    maxPoolSize=10,   # reuse up to 10 connections
    minPoolSize=2,
    serverSelectionTimeoutMS=5000,
)
database = client.bmc_waste_management
```

### Collections

| Collection | Purpose | Key fields |
|-----------|---------|-----------|
| `contractors` | Contractors AND drivers (same collection, role field differentiates) | username, contractor_id, role, hashed_password, email |
| `sites` | Construction sites | site_id, contractor_id, site_name, location, plot_size, qr_code |
| `pickups` | Waste pickup requests | pickup_id, site_id, contractor_id, status, scheduled_date, disposal_proof_url |
| `penalties` | Penalties issued by BMC | penalty_id, site_id, contractor_id, penalty_cost_rupees, penalty_status |
| `citizens` | Citizen accounts | citizen_id, username, hashed_password, contact |
| `citizen_queries` | Citizen complaints | query_id, citizen_id, description, location, status, site_id |
| `officials` | BMC official accounts (pre-seeded) | username, hashed_password, role |
| `alerts` | In-app notifications | contractor_id, message, site_id, timestamp |
| `proof_history` | Contractor disposal proof uploads | site_id, contractor_id, image_url, actual_waste, timestamp |
| `driver_locations` | Latest GPS per driver (upserted) | driver_id, latitude, longitude, timestamp |
| `driver_ratings` | Driver ratings from contractors | driver_id, rating (1-5), review, created_at |
| `bmc_master` | BMC master records per site | site_id, active_penalties |

### Indexes (created on startup)

```python
# Called in lifespan() before app starts serving requests
async def create_indexes():
    await contractor_collection.create_index("username", unique=True)
    await contractor_collection.create_index("contractor_id")
    await site_collection.create_index("site_id", unique=True)
    await site_collection.create_index("contractor_id")
    await pickup_collection.create_index("pickup_id", unique=True)
    await pickup_collection.create_index("contractor_id")
    await pickup_collection.create_index("status")
    await citizen_collection.create_index("username", unique=True)
    await citizen_query_collection.create_index("citizen_id")
    await citizen_query_collection.create_index("status")
    await driver_location_collection.create_index("driver_id", unique=True)
    await alert_collection.create_index("contractor_id")
    await alert_collection.create_index("timestamp")
```

Why indexes matter: without them, every query does a full collection scan. With 10,000 pickups, `find({"contractor_id": x})` goes from O(n) to O(log n).

---
