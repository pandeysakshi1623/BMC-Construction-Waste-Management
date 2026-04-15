# Smart Waste Monitor
### BMC Construction Waste Management System

A full-stack mobile + web application that digitises construction waste management for the Brihanmumbai Municipal Corporation (BMC). It connects four roles — **Contractors**, **Citizens**, **Drivers**, and **BMC Officials** — through a single platform backed by a FastAPI + MongoDB server and a Flutter frontend.

---

## Table of Contents

1. [Tech Stack](#tech-stack)
2. [Application Workflow](#application-workflow)
3. [Role Workflows](#role-workflows)
4. [Project Structure](#project-structure)
5. [Prerequisites](#prerequisites)
6. [Setup — macOS](#setup--macos)
7. [Setup — Windows](#setup--windows)
8. [Environment Configuration](#environment-configuration)
9. [Running the Project](#running-the-project)
10. [Default Credentials](#default-credentials)
11. [API Reference](#api-reference)
12. [Notification System](#notification-system)
13. [Troubleshooting](#troubleshooting)

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Mobile / Web UI | Flutter 3.x (Dart) | Cross-platform frontend |
| State Management | Provider 6.x | Reactive state |
| Backend API | FastAPI (Python) | REST endpoints |
| Database | MongoDB (Motor async) | Data persistence |
| Auth | JWT (python-jose) + bcrypt | Secure authentication |
| Email Alerts | SMTP / Gmail | Event notifications |
| QR Codes | qr_flutter + mobile_scanner | Site verification |
| GPS | geolocator + geocoding | Complaint geo-tagging |

---

## Application Workflow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        APPLICATION FLOW                                  │
│                                                                           │
│  App Launch                                                               │
│      │                                                                    │
│      ▼                                                                    │
│  [Splash Screen] ──── Session exists? ──YES──► Route to role dashboard   │
│      │                                                                    │
│      NO                                                                   │
│      │                                                                    │
│      ▼                                                                    │
│  [Login Screen]                                                           │
│      │  Select role + enter credentials                                   │
│      │  Backend validates + returns JWT token + role                      │
│      │                                                                    │
│      ├──► Contractor ──► /contractor/dashboard                            │
│      ├──► Citizen    ──► /citizen/complaints                              │
│      ├──► Driver     ──► /driver/pickups                                  │
│      └──► BMC        ──► /bmc/dashboard                                   │
│                                                                           │
│  Route Guard: Every protected route checks JWT + role match.             │
│  Wrong role → Access Denied screen → forced re-login.                    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Role Workflows

### Contractor

```
Register Account (/signup)
        │
        ▼
Login → /contractor/dashboard
        │
        ├── Register Site
        │       │  Fill: name, location, area (m²)
        │       ▼
        │   Site saved in DB → QR code generated
        │   Email sent: "Site Registered"
        │   Alert written to DB
        │       │
        │       ▼
        │   /contractor/qr-display
        │       Share QR code with drivers / print for site entrance
        │
        ├── Schedule Pickup
        │       │  Select site → pick date
        │       ▼
        │   Pickup created in DB (status: Pending)
        │   Email sent: "Pickup Scheduled"
        │   Alert written to DB
        │
        ├── Upload Disposal Proof
        │       │  Select site → take/choose photo → enter waste quantity
        │       ▼
        │   Image saved to server
        │   Actual waste updated in DB
        │
        ├── View Alerts
        │       Real-time alerts from DB (penalties, pickup updates)
        │
        └── View Driver Info
                Assigned driver name, vehicle, phone (tap to call)
```

---

### Citizen

```
Register Account (/signup)
        │
        ▼
Login → /citizen/complaints
        │
        ├── Report Complaint (+Report button)
        │       │  Take/choose photo
        │       │  Enter description
        │       │  Fetch GPS location (auto reverse-geocoded)
        │       ▼
        │   Complaint saved in DB (status: Pending)
        │   Email sent to citizen: "Complaint Received"
        │   Alert sent to BMC DB
        │       │
        │       ▼
        │   Complaint appears in list immediately
        │   Status updates: Pending → Under Review → Resolved
        │   Email sent on each status change
        │
        └── Waste Awareness
                Educational tips on waste segregation,
                recycling, hazardous disposal
```

---

### Driver

```
Register Account (/signup — select Driver)
        │
        ▼
Login → /driver/pickups
        │
        ├── View Assigned Pickups (tabs: Active / Completed / All)
        │       Summary bar: Pending | In Progress | Completed counts
        │
        └── Pickup Workflow (per pickup card):
                │
                ▼
            [PENDING]
                │  Tap "Accept Pickup"
                ▼
            [ACCEPTED]
                │  Optionally: Tap "Scan QR" → camera opens
                │              Point at site QR → validated against DB
                │  Tap "Start"
                ▼
            [IN PROGRESS]
                │
                ├── Tap "Mark as Completed"
                │       ▼
                │   [COMPLETED]
                │   Contractor notified (email + DB alert)
                │   BMC notified (DB alert)
                │   "Proof" button appears → upload disposal photo
                │
                └── Tap "Mark as Failed"
                        Enter reason text
                        ▼
                    [FAILED]
                    Contractor notified (email + DB alert)
```

---

### BMC Official

```
Login (pre-seeded account: admin / admin123)
        │
        ▼
/bmc/dashboard
        │
        ├── Stats: Total Sites | Total Pickups | Active Penalties
        │
        ├── Scan Site QR
        │       Camera scans site QR → fetches site details + penalties
        │       Option to issue penalty (amount + reason)
        │       Contractor notified (email + DB alert)
        │
        ├── Truck Approvals
        │       List of pickups pending approval
        │       Approve / Reject each truck
        │
        ├── Citizen Complaints
        │       All complaints from all citizens
        │
        └── Alerts
                All system alerts (penalties, pickups, complaints)
```

---

## Project Structure

```
BMC-Construction-Waste-Management/
│
├── lib/                          Flutter frontend
│   ├── main.dart                 Entry point, providers, route guards
│   ├── models/                   Data models (User, Site, Pickup, Complaint)
│   ├── providers/                State (AuthProvider, RoleProvider, PickupProvider)
│   ├── screens/
│   │   ├── auth/                 Login, Signup, RoleSelection
│   │   ├── contractor/           Dashboard, SiteReg, QR, Schedule, Upload
│   │   ├── citizen/              Complaints, Report, Awareness
│   │   ├── driver/               Pickups, QRScanner, UploadDisposal
│   │   └── bmc/                  Dashboard, Alerts, QRScanner, TruckApproval
│   ├── services/                 API, Pickup, Location, Image, Notification
│   ├── utils/                    Route guard
│   └── widgets/                  AppScaffold, StatusChip, LoadingButton
│
├── routers/                      FastAPI route handlers
│   ├── auth.py                   Contractor + Driver signup/login
│   ├── citizen.py                Citizen signup/login/complaints
│   ├── sites.py                  Site registration + proof upload
│   ├── pickups.py                Pickup CRUD + status updates
│   ├── bmc.py                    BMC login, QR scan, penalties, dashboard
│   └── alerts.py                 Alert fetch endpoints
│
├── models/                       Pydantic models (Python)
├── utils/
│   ├── notify.py                 Email + DB alert writer
│   ├── security.py               JWT + bcrypt helpers
│   ├── deps.py                   FastAPI auth dependencies
│   ├── qr_generator.py           QR code image generation
│   └── scheduler.py              24h background penalty alert job
│
├── database/                     MongoDB setup helpers
├── scripts/                      Seed scripts
├── main.py                       FastAPI app entry point
├── database.py                   Motor async DB connection
├── requirements.txt              Python dependencies
├── pubspec.yaml                  Flutter dependencies
└── .env                          Environment variables (not committed)
```

---

## Prerequisites

### Both Platforms

| Tool | Version | Download |
|---|---|---|
| Flutter SDK | 3.x+ | https://docs.flutter.dev/get-started/install |
| Python | 3.10+ | https://www.python.org/downloads/ |
| MongoDB Community | 6.x+ | https://www.mongodb.com/try/download/community |
| Git | any | https://git-scm.com/downloads |

---

## Setup — macOS

### Step 1 — Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2 — Install Flutter
```bash
brew install --cask flutter
flutter doctor
```
Fix any issues reported by `flutter doctor` before continuing.

### Step 3 — Install Python 3
```bash
brew install python@3.11
python3 --version   # should print 3.11.x or higher
```

### Step 4 — Install and Start MongoDB
```bash
brew tap mongodb/brew
brew install mongodb-community@7.0
brew services start mongodb-community@7.0

# Verify MongoDB is running
mongosh --eval "db.runCommand({ connectionStatus: 1 })"
```

### Step 5 — Clone the Repository
```bash
git clone <repository-url>
cd BMC-Construction-Waste-Management
```

### Step 6 — Set Up Python Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Step 7 — Configure Environment Variables
```bash
cp .env .env.local   # optional backup
```
Edit `.env` and fill in your SMTP credentials (see [Environment Configuration](#environment-configuration)).

### Step 8 — Seed the BMC Admin Account
```bash
source venv/bin/activate
python3 -c "
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext

pwd = CryptContext(schemes=['bcrypt'], deprecated='auto')

async def seed():
    client = AsyncIOMotorClient('mongodb://localhost:27017')
    db = client.bmc_waste_management
    await db.officials.delete_many({})
    await db.officials.insert_one({
        'username': 'admin',
        'hashed_password': pwd.hash('admin123'),
        'role': 'bmc_official',
        'name': 'BMC Admin',
        'email': 'admin@bmc.gov'
    })
    print('BMC admin seeded.')
    client.close()

asyncio.run(seed())
"
```

### Step 9 — Install Flutter Dependencies
```bash
flutter pub get
```

---

## Setup — Windows

### Step 1 — Install Flutter
1. Download the Flutter SDK zip from https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to your system PATH:
   - Search "Environment Variables" → Edit System Environment Variables
   - Under "System variables" → Path → Edit → New → `C:\flutter\bin`
4. Open a new terminal and run:
```cmd
flutter doctor
```
Fix any issues before continuing.

### Step 2 — Install Python 3
1. Download from https://www.python.org/downloads/windows/
2. During install, check **"Add Python to PATH"**
3. Verify:
```cmd
python --version
pip --version
```

### Step 3 — Install MongoDB
1. Download MongoDB Community from https://www.mongodb.com/try/download/community
2. Run the installer (choose "Complete" setup)
3. MongoDB runs as a Windows Service automatically after install
4. Verify:
```cmd
mongosh --eval "db.runCommand({ connectionStatus: 1 })"
```

### Step 4 — Clone the Repository
```cmd
git clone <repository-url>
cd BMC-Construction-Waste-Management
```

### Step 5 — Set Up Python Virtual Environment
```cmd
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### Step 6 — Configure Environment Variables
Edit `.env` in the project root (see [Environment Configuration](#environment-configuration)).

### Step 7 — Seed the BMC Admin Account
```cmd
venv\Scripts\activate
python -c "
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext

pwd = CryptContext(schemes=['bcrypt'], deprecated='auto')

async def seed():
    client = AsyncIOMotorClient('mongodb://localhost:27017')
    db = client.bmc_waste_management
    await db.officials.delete_many({})
    await db.officials.insert_one({
        'username': 'admin',
        'hashed_password': pwd.hash('admin123'),
        'role': 'bmc_official',
        'name': 'BMC Admin',
        'email': 'admin@bmc.gov'
    })
    print('BMC admin seeded.')
    client.close()

asyncio.run(seed())
"
```

### Step 8 — Install Flutter Dependencies
```cmd
flutter pub get
```

---

## Environment Configuration

Edit the `.env` file in the project root:

```env
# MongoDB connection
MONGO_URI=mongodb://localhost:27017/

# SMTP Email (optional — notifications print to console if not set)
# For Gmail: generate an App Password at https://myaccount.google.com/apppasswords
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_16_char_app_password
SMTP_FROM=BMC Waste Monitor <your_email@gmail.com>
```

> Email notifications work without SMTP configured — they just print to the backend console instead of sending.

---

## Running the Project

You need **two terminals** running simultaneously.

### Terminal 1 — Start the Backend

**macOS:**
```bash
cd BMC-Construction-Waste-Management
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Windows:**
```cmd
cd BMC-Construction-Waste-Management
venv\Scripts\activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

API docs available at: http://localhost:8000/docs

### Terminal 2 — Start the Flutter App

**Run on Chrome (recommended for development):**
```bash
flutter run -d chrome
```

**Run on macOS desktop:**
```bash
flutter run -d macos
```

**Run on Android emulator:**
```bash
# First start an emulator from Android Studio, then:
flutter run -d android
```

**Run on iOS simulator (macOS only):**
```bash
open -a Simulator
flutter run -d ios
```

### Configure the API Base URL

Open `lib/services/api_service.dart` and set `_base` to match your target:

```dart
// Chrome / macOS desktop / iOS simulator
static const String _base = 'http://localhost:8000';

// Android emulator
static const String _base = 'http://10.0.2.2:8000';

// Real device (replace with your machine's LAN IP)
static const String _base = 'http://192.168.x.x:8000';
```

Also update `lib/services/pickup_service.dart` with the same base URL.

---

## Default Credentials

| Role | Username | Password | Notes |
|---|---|---|---|
| BMC Official | `admin` | `admin123` | Pre-seeded via seed script |
| Contractor | *(register)* | *(your choice)* | Use /signup, select Contractor |
| Citizen | *(register)* | *(your choice)* | Use /signup, select Citizen |
| Driver | *(register)* | *(your choice)* | Use /signup, select Driver |

> BMC Official accounts cannot self-register. Only the admin account exists by default.

---

## API Reference

Base URL: `http://localhost:8000`
Interactive docs: `http://localhost:8000/docs`

### Authentication

| Method | Endpoint | Role | Description |
|---|---|---|---|
| POST | `/auth/signup` | Contractor | Register contractor account |
| POST | `/auth/signup/driver` | Driver | Register driver account |
| POST | `/auth/login` | Contractor / Driver | Login, returns JWT + role |
| POST | `/citizen/signup` | Citizen | Register citizen account |
| POST | `/citizen/login` | Citizen | Login, returns JWT |
| POST | `/bmc/login` | BMC | Login, returns JWT |

### Sites (Contractor)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/sites/register` | Register new site, generates QR |
| GET | `/sites/all` | Get all sites for logged-in contractor |
| POST | `/sites/upload-proof` | Upload waste disposal proof image |

### Pickups

| Method | Endpoint | Description |
|---|---|---|
| POST | `/pickups/request` | Schedule a pickup for a site |
| GET | `/pickups/driver` | Get all pickups (driver view) |
| GET | `/pickups/contractor` | Get pickups for contractor's sites |
| PATCH | `/pickups/{id}/status` | Update pickup status |
| POST | `/pickups/upload-proof` | Upload disposal proof (driver) |

### Citizen

| Method | Endpoint | Description |
|---|---|---|
| POST | `/citizen/query` | Submit a complaint |
| GET | `/citizen/queries` | Get logged-in citizen's complaints |
| GET | `/citizen/queries/all` | Get all complaints (BMC view) |

### BMC

| Method | Endpoint | Description |
|---|---|---|
| GET | `/bmc/dashboard` | Stats: sites, pickups, penalties |
| GET | `/bmc/qr-scan/{site_id}` | Fetch site details by QR |
| POST | `/bmc/penalties/{site_id}` | Issue penalty to contractor |
| POST | `/bmc/trucks/{pickup_id}/approve` | Approve or reject truck |
| GET | `/bmc/penalties/by-site` | Penalties grouped by site |

### Alerts

| Method | Endpoint | Description |
|---|---|---|
| GET | `/alerts/contractor` | Alerts for logged-in contractor |
| GET | `/alerts/bmc` | All BMC alerts |

---

## Notification System

Every key event triggers two things simultaneously:

1. **DB Alert** — written to the `alerts` MongoDB collection, visible in the app's Alerts screen
2. **Email** — sent to the user's registered email (if SMTP is configured)

| Event | Who gets notified |
|---|---|
| Complaint submitted | Citizen (email) + BMC (DB alert) |
| Site registered | Contractor (email + DB alert) |
| Pickup scheduled | Contractor (email + DB alert) + BMC (DB alert) |
| Pickup status changed | Contractor (email + DB alert) + BMC (DB alert) |
| Penalty issued | Contractor (email + DB alert) |

Without SMTP configured, all notifications are printed to the backend console with `[NOTIFY]` prefix.

---

## Troubleshooting

**`flutter: command not found`**
Add Flutter to PATH. On macOS: `export PATH="$PATH:/path/to/flutter/bin"` in `~/.zshrc`.

**`venv/bin/activate: No such file`**
Run `python3 -m venv venv` first, then activate.

**`Connection timed out` in the app**
- Confirm the backend is running: `curl http://localhost:8000/`
- Check `_base` URL in `lib/services/api_service.dart` matches your target platform
- Android emulator needs `http://10.0.2.2:8000`, not `localhost`

**`422 Unprocessable Content` on signup**
- Contractor signup requires a valid email address
- Driver signup uses `/auth/signup/driver` (no email required)

**`NO BMC official found` / can't login as BMC**
Re-run the seed script from [Step 8 of Setup](#step-8--seed-the-bmc-admin-account).

**MongoDB connection refused**
- macOS: `brew services start mongodb-community@7.0`
- Windows: Open Services → find "MongoDB" → Start

**`bcrypt` warning on startup**
The `(trapped) error reading bcrypt version` warning is harmless — bcrypt still works correctly.

**Role badge shows wrong role after login**
Do a full app restart (not hot reload). Hot reload does not re-run `initState` or provider constructors.
