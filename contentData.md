# Smart Waste Monitor — Complete Project Explanation
## For Viva, Technical Presentation & System Design

---

# SECTION 1 — INTRODUCTION (FROM SCRATCH)

## 1.1 What Problem Are We Solving?

Construction sites in cities like Mumbai generate massive amounts of waste — broken bricks, cement, steel rods, wood, plastic, and hazardous materials. This waste is often:

- Dumped illegally on roadsides or in water bodies
- Not tracked or documented by any authority
- Managed without any accountability between contractors and the government
- Invisible to citizens who live near these sites

The **Brihanmumbai Municipal Corporation (BMC)** is responsible for regulating construction waste disposal in Mumbai. But with hundreds of active construction sites, manual inspection is impossible. There is no digital system to:

1. Know which contractor is responsible for which site
2. Track whether waste was actually collected and disposed of
3. Allow citizens to report violations
4. Issue penalties automatically when rules are broken

## 1.2 Why Is This System Needed?

| Problem | Without System | With Our System |
|---|---|---|
| Site identification | Manual paperwork | QR code at every site |
| Waste tracking | No record | Proof photos + timestamps |
| Citizen complaints | Phone calls, ignored | Digital complaints linked to site |
| Penalty enforcement | Manual, slow | Automated via BMC dashboard |
| Driver accountability | No verification | QR scan before pickup |
| Contractor visibility | No dashboard | Real-time site + penalty view |

## 1.3 Real-World Relevance

- India generates over **150 million tonnes** of construction waste per year
- Mumbai alone has thousands of active construction sites at any time
- BMC spends crores annually on illegal dump cleanup
- Citizens have no formal channel to report construction waste violations
- This system directly addresses **Swachh Bharat Mission** goals for urban waste management

## 1.4 What Makes This System Different?

1. **QR-based site identity** — every site gets a unique scannable code, no manual entry needed
2. **Four-role architecture** — Contractor, Citizen, Driver, BMC each have their own app experience
3. **Proof-based compliance** — waste disposal must be photographically documented
4. **Automated penalty alerts** — a background job runs every 24 hours and generates alerts for unpaid penalties
5. **Email notifications** — contractors get emails on site registration, pickup scheduling, penalty issuance
6. **End-to-end digital trail** — from site registration to complaint to penalty, everything is recorded

---

# SECTION 2 — COMPLETE TECH STACK

## 2.1 Frontend — Flutter

**What is Flutter?**
Flutter is Google's open-source UI framework for building natively compiled mobile applications from a single codebase using the Dart programming language.

**Why Flutter over React Native or native Android/iOS?**
- Single codebase runs on Android and iOS — saves 50% development time
- Dart compiles to native ARM code — performance close to native apps
- Rich widget library with Material 3 design system built-in
- Hot reload — see UI changes instantly during development
- Strong typing in Dart catches bugs at compile time, not runtime

**How it is used here:**
The entire mobile app — all 4 role dashboards, QR scanner, image upload, GPS, forms — is built in Flutter. The app communicates with the backend exclusively through HTTP REST API calls.

## 2.2 Backend — FastAPI (Python)

**What is FastAPI?**
FastAPI is a modern Python web framework for building REST APIs. It is built on top of Starlette (for async HTTP) and Pydantic (for data validation).

**Why FastAPI over Django or Node.js?**

| Feature | FastAPI | Django | Node.js |
|---|---|---|---|
| Speed | Very fast (async) | Slower (sync by default) | Fast |
| Auto docs | Yes (Swagger UI built-in) | No | No |
| Data validation | Pydantic (automatic) | Manual forms | Manual |
| Async support | Native (async/await) | Added later | Native |
| Learning curve | Low | High | Medium |

**Async benefit explained simply:**
When a request comes in to upload an image, a synchronous server would WAIT doing nothing until the file is saved. FastAPI uses `async/await` — while one request is waiting for the database, it handles another request simultaneously. This means the server can handle many users at once without slowing down.

**How it is used here:**
FastAPI runs on `uvicorn` (an ASGI server) at port 8000. It has 7 routers: auth, sites, pickups, bmc, citizen, alerts, profile. Each router handles a specific domain of the application.

## 2.3 Database — MongoDB

**What is MongoDB?**
MongoDB is a NoSQL document database. Instead of tables and rows (like SQL), it stores data as JSON-like documents in collections.

**Why MongoDB over MySQL or PostgreSQL?**

| Feature | MongoDB | SQL (MySQL/PostgreSQL) |
|---|---|---|
| Schema | Flexible, no fixed columns | Rigid, must define all columns upfront |
| Data format | JSON documents | Tables with rows |
| Scaling | Horizontal (easy) | Vertical (harder) |
| Nested data | Natural (embed arrays/objects) | Requires JOIN queries |
| Speed for reads | Very fast | Fast with indexes |

**Why it fits this project:**
- A site document can embed its QR code URL, waste estimates, and status all in one document — no JOINs needed
- A complaint document can optionally have a `site_id` field — MongoDB handles optional fields naturally
- Proof history entries have varying fields (some have driver name, some don't) — flexible schema handles this perfectly

**Async driver — Motor:**
The project uses `motor`, which is the async version of PyMongo. This means database queries use `await` and don't block the server while waiting for MongoDB to respond.

## 2.4 Other Tools and Libraries

### QR Code Generation — `qrcode` (Python) + `qr_flutter` (Flutter)
- **Backend**: Python `qrcode` library generates a PNG image of the QR code and saves it to the `uploads/` folder
- **Frontend**: `qr_flutter` renders the QR code directly on screen from a string — no image needed
- **Why two libraries?** Backend generates a permanent QR image file (for printing/sharing). Frontend renders it live for display.

### QR Scanning — `mobile_scanner`
- Uses Android CameraX + TFLite (TensorFlow Lite) for real-time barcode detection
- `DetectionSpeed.noDuplicates` prevents the same QR from being processed twice
- `formats: [BarcodeFormat.qrCode]` limits TFLite to only QR format — reduces CPU/memory load

### Image Picker — `image_picker`
- Opens device gallery or camera to select a photo
- Returns `XFile` — works on both web and mobile
- Image bytes are read with `readAsBytes()` for multipart upload

### Multipart Upload — `http.MultipartRequest`
- Images cannot be sent as JSON — they are binary data
- Multipart form data sends both text fields (site_id, actual_waste) and binary file (image) in one HTTP request
- Backend receives it with FastAPI's `UploadFile` + `File(...)` + `Form(...)` parameters

### JWT Authentication — `python-jose` + `passlib`
- `passlib` with `bcrypt` hashes passwords before storing in MongoDB
- `python-jose` creates and verifies JWT tokens
- Token contains: `sub` (username), `role`, `contractor_id`, `exp` (expiry)
- Token expires in 30 minutes (configurable)

### GPS + Geocoding — `geolocator` + `geocoding`
- `geolocator` gets device GPS coordinates (latitude, longitude)
- `geocoding` converts coordinates to a human-readable address ("Main St, Mumbai")
- Used in complaint submission to auto-fill location

### Email Notifications — `smtplib` (Python standard library)
- Sends emails via Gmail SMTP (configured in `.env` file)
- Used for: site registration, pickup scheduled, penalty issued, complaint received
- Falls back to console print if SMTP credentials are not configured

### Background Scheduler — `asyncio`
- `generate_penalty_alerts()` runs as an infinite async loop
- Every 24 hours it scans all active penalties and inserts alert documents for both the contractor and BMC
- Started at app startup using FastAPI's `lifespan` context manager

### State Management — `provider`
- Flutter's recommended state management solution
- Three providers: `AuthProvider` (session), `PickupProvider` (driver pickups), `RoleProvider` (role badge)
- Uses `ChangeNotifier` — widgets rebuild automatically when `notifyListeners()` is called

---

# SECTION 3 — SYSTEM ARCHITECTURE

## 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP                        │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │Contractor│ │ Citizen  │ │  Driver  │ │ BMC Official │  │
│  │Dashboard │ │Dashboard │ │Dashboard │ │  Dashboard   │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘  │
│       │             │             │               │          │
│       └─────────────┴─────────────┴───────────────┘         │
│                           │                                  │
│                    ApiService.dart                           │
│              (HTTP calls with JWT Bearer token)              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                   HTTP/REST (port 8000)
                   JSON request/response
                   Multipart for images
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                  FASTAPI BACKEND (Python)                    │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │  /auth   │ │  /sites  │ │/pickups  │ │    /bmc      │  │
│  │  router  │ │  router  │ │  router  │ │    router    │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                    │
│  │/citizen  │ │ /alerts  │ │/profile  │  Background:        │
│  │  router  │ │  router  │ │  router  │  Penalty Alert Job  │
│  └──────────┘ └──────────┘ └──────────┘  (every 24h)       │
│                                                              │
│  Middleware: CORS, JWT verification, Pydantic validation     │
│  Static files: /static → uploads/ folder (images)           │
└───────────────────────────┬─────────────────────────────────┘
                            │
                   Motor (async driver)
                   mongodb://localhost:27017
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                  MONGODB DATABASE                            │
│              (bmc_waste_management)                          │
│                                                              │
│  contractors    sites         pickups      penalties         │
│  citizens       citizen_queries  alerts   proof_history      │
│  bmc_master     officials                                    │
└─────────────────────────────────────────────────────────────┘
```

## 3.2 Request-Response Data Flow

```
User taps button in Flutter
        │
        ▼
Screen calls ApiService method
  e.g. ApiService.registerSite(name, location, area, token)
        │
        ▼
http.post() sends JSON to http://192.168.x.x:8000/sites/register
  Headers: { Authorization: Bearer <JWT> }
  Body:    { site_name, location, project_type, plot_size }
        │
        ▼
FastAPI receives request
  → CORS middleware checks origin
  → Depends(get_current_user) decodes JWT → gets contractor from MongoDB
  → Pydantic validates request body (SiteCreate model)
  → Router function executes business logic
        │
        ▼
Business logic runs
  → Generates unique site_id (SITE_XXXXXXXX)
  → Calls qr_generator.generate_qr_file() → saves PNG to uploads/
  → Inserts site document into MongoDB sites collection
  → Sends email notification to contractor
        │
        ▼
FastAPI returns JSON response
  { site_id, site_name, location, qr_code_url, ... }
        │
        ▼
Flutter receives response
  → SiteModel.fromJson() parses JSON
  → Navigator pushes QrDisplayScreen with SiteModel
  → QrImageView renders QR code on screen
```

## 3.3 Authentication Flow

```
Flutter Login Screen
        │
        ▼
POST /auth/login  { username, password }
        │
        ▼
FastAPI: find user in MongoDB → verify bcrypt password
        │
        ▼
Create JWT token:
  payload = { sub: username, role: contractor, contractor_id: xxx, exp: +30min }
  token = jwt.encode(payload, SECRET_KEY, HS256)
        │
        ▼
Return { access_token, role, contractor_id }
        │
        ▼
Flutter stores token in SharedPreferences
Every future API call adds: Authorization: Bearer <token>
        │
        ▼
FastAPI get_current_user():
  → Decode JWT → extract username
  → Find user in MongoDB
  → Return user dict to route handler
```

## 3.4 Layer Responsibilities

| Layer | Responsibility |
|---|---|
| Flutter Screens | UI rendering, user input, navigation |
| Flutter Providers | State management, data caching |
| Flutter ApiService | HTTP calls, JSON parsing, error handling |
| FastAPI Routers | Route handling, business logic |
| FastAPI Utils | Security, QR generation, notifications, auth deps |
| Pydantic Models | Request/response validation and serialization |
| MongoDB | Persistent data storage |
| Motor | Async bridge between FastAPI and MongoDB |

---

# SECTION 4 — MODULE-WISE BREAKDOWN

## 4.1 Contractor Module

### What It Does
A contractor is a construction company that registers sites, manages waste pickups, uploads disposal proof, and views penalties.

### A. Site Registration
**Screen:** `site_registration_screen.dart`
**API:** `POST /sites/register`

How it works internally:
1. Contractor fills form: site name, location, plot area (m²)
2. Flutter sends JSON to backend with JWT token
3. Backend verifies contractor identity from JWT
4. Backend generates unique `site_id` = `SITE_` + 8 random uppercase chars (e.g. `SITE_A3F9B2C1`)
5. Backend calls `generate_qr_file()` — creates QR PNG encoding the string `SITE_ID:SITE_A3F9B2C1|CONTRACTOR:xxx|NAME:Tower A`
6. QR image saved to `uploads/` folder, URL stored in MongoDB
7. Site document inserted into `sites` collection
8. Email sent to contractor confirming registration
9. Flutter receives `SiteModel` and navigates to QR display screen

Why needed: Without site registration, there is no identity for the site. The QR code is the digital identity card of the site.

### B. QR Code Display
**Screen:** `qr_display_screen.dart`
**Library:** `qr_flutter`

How it works:
- `QrImageView(data: site.qrCode)` renders the QR code as a widget — no image file needed on Flutter side
- The QR data is just the `site_id` string (e.g. `SITE_A3F9B2C1`)
- Share button uses `share_plus` to share site details as text
- Contractor prints this QR and displays it at the site entrance

### C. Pickup Scheduling
**Screen:** `pickup_scheduling_screen.dart`
**API:** `POST /pickups/request`

How it works:
1. Contractor selects a date (today to +60 days) using Flutter's `showDatePicker`
2. Backend creates a pickup document with status `Pending`
3. Pickup gets a unique `pickup_id` = `PKUP_` + 8 chars
4. Email notification sent to contractor confirming schedule
5. Alert written to MongoDB for both contractor and BMC

### D. Upload Proof
**Screen:** `upload_proof_screen.dart`
**API:** `POST /sites/upload-proof` (multipart)

Three-state verification system:
```
notStarted → (Driver clicks "Start Collection") → inProgress → (Contractor uploads) → completed
```

How multipart upload works:
1. Flutter reads image as bytes: `await _image!.readAsBytes()`
2. Creates `http.MultipartRequest` with fields: `site_id`, `actual_waste`, `driver_verified`
3. Adds image as `MultipartFile.fromBytes()`
4. Backend receives `UploadFile` object, reads bytes, saves to `uploads/` folder
5. Updates site's `actual_waste` field in MongoDB
6. Creates entry in `proof_history` collection with image URL, timestamp, waste amount

Why driver verification? To prevent contractors from uploading fake proof photos taken at any time. The driver must physically be present and confirm collection is in progress before the upload form is unlocked.

### E. Proof History
**Screen:** `proof_history_screen.dart`
**API:** `GET /sites/proof-history/{site_id}`

- Timeline UI showing all past uploads for a site
- Each entry: proof photo, waste collected, timestamp, driver name
- Backend queries `proof_history` collection filtered by `site_id` and `contractor_id`, sorted by timestamp descending

### F. Penalties View
**Screen:** Penalties tab in `contractor_dashboard_screen.dart`
**API:** `GET /bmc/penalties/contractor/{contractor_id}`

- Shows all penalties issued against the contractor
- Total amount summary card
- Each penalty: amount (₹), reason, site ID, date issued, status

## 4.2 Citizen Module

### What It Does
A citizen is a member of the public who can report waste violations at construction sites and track the status of their complaints.

### A. QR Scanner
**Screen:** `citizen_qr_scanner_screen.dart`
**API:** `GET /sites/by-qr/{site_id}` (NO auth required)

How it works internally:
1. Camera opens with `MobileScannerController`
2. TFLite processes camera frames in real-time looking for QR patterns
3. On detection: `_onDetect(BarcodeCapture capture)` fires
4. `_extractSiteId()` parses the raw QR string:
   - If format is `SITE_ID:SITE_ABC|CONTRACTOR:...|NAME:...` → split on `|`, strip `SITE_ID:` prefix
   - If format is plain `SITE_ABC` → use as-is
5. Validates that result starts with `SITE_`
6. Calls public API (no login needed) to fetch site details
7. Navigates to complaint form with site pre-filled

Why public endpoint? Citizens should not need to create an account just to look up a site. The QR scan is a public action.

### B. Report Complaint
**Screen:** `report_complaint_screen.dart`
**API:** `POST /citizen/query`

Two modes:
- **QR mode**: site_id, site_name, location all pre-filled from QR scan
- **Manual mode**: citizen enters site ID manually, clicks "Look Up" to validate

Steps in complaint submission:
1. Citizen writes description of the violation
2. Taps "Get GPS Location" → `LocationService.getCurrentLocation()` → `reverseGeocode()` → fills address
3. Taps image box → `ImageService.pickImage()` → selects photo from gallery
4. Taps Submit → `POST /citizen/query` with description, location, site_id, image
5. Backend creates complaint with `query_id`, `citizen_id`, status `Pending`
6. Email sent to citizen confirming receipt

### C. Complaints List
**Screen:** `complaints_screen.dart`
**API:** `GET /citizen/queries`

- Shows all complaints submitted by this citizen
- On each load, checks if any complaint changed to `Resolved` → fires in-app notification
- Status chip shows: Pending (grey), Resolved (green), Rejected (red)

### D. Awareness Screen
**Screen:** `awareness_screen.dart`
No API calls — static educational content.

7 tips covering: waste segregation, single-use reduction, construction tips, composting, hazardous disposal, water protection, reporting illegal dumping. Plus a visual waste segregation guide with color-coded categories.

## 4.3 Driver Module

### What It Does
A driver is a waste collection truck driver who accepts pickup assignments, scans site QR codes to verify location, and uploads disposal proof.

### A. Pickups Screen
**Screen:** `pickups_screen.dart`
**API:** `GET /pickups/driver`, `PATCH /pickups/{id}/status`

Pickup state machine:
```
Pending ──► Accept ──► Accepted ──► Start ──► In Progress ──► Complete ──► Completed
                          │                                        │
                          └──► Scan QR (verify site)              └──► Failed (with reason)
```

How optimistic UI works:
1. Driver taps "Accept" button
2. Flutter immediately updates local state: `_pickups[index] = old.copyWith(status: accepted)`
3. UI rebuilds instantly — no waiting
4. API call happens in background
5. If API fails → revert to old state and show error
6. This makes the app feel fast even on slow networks

### B. QR Scanner (Driver)
**Screen:** `qr_scanner_screen.dart`
**API:** `GET /bmc/qr-scan/{qrCode}`

Purpose: Driver scans the QR at the site to VERIFY they are at the correct location before starting collection.

How it works:
1. Camera opens, driver points at site QR
2. QR value extracted
3. API call to `/bmc/qr-scan/{qrCode}` — returns site details if valid
4. Success dialog shows site name + "Upload Proof" button
5. Invalid QR shows error with retry option

### C. Upload Disposal Proof
**Screen:** `upload_disposal_screen.dart`
**API:** `POST /pickups/upload-proof` (multipart)

Driver takes a photo of the disposal site (landfill/processing center) as proof that waste was properly disposed of. Uploaded as multipart with `pickup_id` and image bytes.

## 4.4 BMC Module

### What It Does
BMC (Brihanmumbai Municipal Corporation) officials monitor all sites, review citizen complaints, approve/reject truck pickups, issue penalties, and view system-wide alerts.

### A. Dashboard
**Screen:** `bmc_dashboard_screen.dart`
**API:** `GET /bmc/dashboard`

Stats shown: Total Sites, Total Pickups, Active Penalties, Total Complaints. Auto-refreshes every 30 seconds. Shows top 5 pending complaints with badge count.

### B. Complaints Management
**Screen:** `bmc_complaints_screen.dart`
**API:** `GET /citizen/queries/all`, `POST /citizen/complaints/resolve/{id}`

How complaint resolution works:
1. BMC sees all pending complaints from all citizens
2. Clicks "Approve" → dialog asks for penalty amount (₹)
3. Backend: marks complaint as `Resolved`, creates penalty document in `penalties` collection, sends email to contractor
4. Clicks "Reject" → backend marks complaint as `Rejected`
5. Citizen's app will show updated status on next load

### C. QR Scanner (BMC)
**Screen:** `bmc_qr_scanner_screen.dart`
**API:** `GET /bmc/qr-scan/{siteId}`, `POST /bmc/penalties/{siteId}`

BMC official visits a site physically, scans the QR, sees full site details (contractor, waste estimates, actual waste, status, active penalties). Can immediately issue a penalty from the bottom sheet.

### D. Truck Approval
**Screen:** `bmc_truck_approval_screen.dart`
**API:** `GET /pickups/contractor`, `POST /bmc/trucks/{id}/approve`

BMC reviews all scheduled pickups and approves or rejects them. This gives BMC control over which trucks are authorized to collect waste from which sites.

### E. Alerts
**Screen:** `bmc_alerts_screen.dart`
**API:** `GET /alerts/bmc`

Shows all system alerts: unpaid penalties (generated by 24h background job), new complaints, pickup status changes.

---
