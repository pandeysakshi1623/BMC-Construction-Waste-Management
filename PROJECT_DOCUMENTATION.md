# Smart Waste Monitor — Complete Project Documentation

---

## 1. PROJECT OVERVIEW

**App Name:** Smart Waste Monitor
**Platform:** Flutter (Android / iOS / Web)
**Purpose:** A real-world construction waste management system connecting three user roles — Contractors who manage construction sites, Citizens who report waste complaints, and Drivers who execute waste pickups.
**Package Name:** `com.example.smart_waste_monitor`
**Version:** 1.0.0+1

---

## 2. TECH STACK

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| UI Framework | Flutter | >=3.0.0 | Cross-platform mobile UI |
| Language | Dart | >=3.0.0 | App logic |
| State Management | Provider | ^6.1.2 | Reactive state across widgets |
| HTTP Client | http | ^1.2.1 | REST API calls |
| Image Picker | image_picker | ^1.1.2 | Camera and gallery access |
| GPS / Location | geolocator | ^12.0.0 | Device location services |
| QR Scanner | mobile_scanner | ^5.2.3 | Camera-based QR code scanning |
| Local Storage | shared_preferences | ^2.3.2 | Session persistence |
| Phone Calls | url_launcher | ^6.3.0 | Launch phone dialer |
| Design System | Material Design 3 | built-in | UI components and theming |

---

## 3. ANDROID PERMISSIONS (AndroidManifest.xml)

```
CAMERA                  — Image capture for proof uploads and QR scanning
READ_EXTERNAL_STORAGE   — Access gallery images (Android < 13)
READ_MEDIA_IMAGES       — Access gallery images (Android 13+)
ACCESS_FINE_LOCATION    — Precise GPS for complaint geo-tagging
ACCESS_COARSE_LOCATION  — Fallback location accuracy
CALL_PHONE              — Direct phone call to assigned driver
```

Additional manifest entries:
- `android:launchMode="singleTop"` — prevents duplicate activity instances
- `flutterEmbedding v2` — required for modern Flutter embedding
- `PROCESS_TEXT` query intent — supports text selection features

---

## 4. COMPLETE FOLDER STRUCTURE

```
smart_waste_monitor/
├── lib/
│   ├── main.dart                          Entry point, providers, routes
│   ├── models/
│   │   ├── user_model.dart                Authenticated user data
│   │   ├── site_model.dart                Construction site data
│   │   ├── complaint_model.dart           Citizen complaint data
│   │   ├── pickup_model.dart              Pickup + status workflow
│   │   └── driver_model.dart              Driver profile + location
│   ├── providers/
│   │   ├── auth_provider.dart             Login, logout, session
│   │   ├── role_provider.dart             Active role + switching
│   │   └── pickup_provider.dart           Pickup list + status updates
│   ├── services/
│   │   ├── api_service.dart               All HTTP/dummy API calls
│   │   ├── pickup_service.dart            Driver-specific pickup API
│   │   ├── location_service.dart          GPS permission + position
│   │   ├── image_service.dart             Image picker bottom sheet
│   │   ├── call_service.dart              Phone dialer via url_launcher
│   │   └── notification_service.dart      Global snackbar notifications
│   ├── screens/
│   │   ├── splash_screen.dart             Auto-login check on startup
│   │   ├── auth/
│   │   │   ├── login_screen.dart          Email + password login
│   │   │   └── role_selection_screen.dart Role picker after login
│   │   ├── contractor/
│   │   │   ├── contractor_dashboard_screen.dart  Site list + actions
│   │   │   ├── site_registration_screen.dart     Register new site
│   │   │   ├── qr_display_screen.dart            Show site QR code
│   │   │   ├── pickup_scheduling_screen.dart      Date picker + submit
│   │   │   └── upload_proof_screen.dart           Image + quantity upload
│   │   ├── citizen/
│   │   │   ├── complaints_screen.dart     Complaint list with status
│   │   │   ├── report_complaint_screen.dart  Image + GPS + description
│   │   │   └── awareness_screen.dart      Waste tips + recycling guide
│   │   └── driver/
│   │       ├── pickups_screen.dart        Tabbed pickup list + workflow
│   │       ├── qr_scanner_screen.dart     Camera QR scanner + validation
│   │       └── upload_disposal_screen.dart  Disposal photo upload
│   └── widgets/
│       ├── app_scaffold.dart              Shared scaffold + role switcher
│       ├── status_chip.dart               Color-coded status badge
│       ├── loading_button.dart            Button with loading spinner
│       ├── image_picker_box.dart          Tap-to-pick image container
│       └── driver_info_card.dart          Driver details + call button
├── android/
│   └── app/src/main/AndroidManifest.xml  Permissions + activity config
└── pubspec.yaml                           Dependencies + metadata
```

---

## 5. ARCHITECTURAL DIAGRAM

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                                  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                        main.dart                             │    │
│  │   MultiProvider                                              │    │
│  │   ├── AuthProvider                                           │    │
│  │   ├── RoleProvider                                           │    │
│  │   └── PickupProvider                                         │    │
│  │   MaterialApp (routes, theme, scaffoldMessengerKey)          │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                              │                                        │
│              ┌───────────────┼───────────────┐                       │
│              ▼               ▼               ▼                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │  PROVIDERS   │  │   SCREENS    │  │   SERVICES   │              │
│  │              │  │              │  │              │              │
│  │ AuthProvider │  │ SplashScreen │  │ ApiService   │              │
│  │  - login()   │  │ LoginScreen  │  │ PickupSvc    │              │
│  │  - logout()  │  │ RoleSelect   │  │ LocationSvc  │              │
│  │  - setRole() │  │              │  │ ImageService │              │
│  │  - prefs     │  │ Contractor:  │  │ CallService  │              │
│  │              │  │  Dashboard   │  │ Notif.Svc    │              │
│  │ RoleProvider │  │  SiteReg     │  └──────┬───────┘              │
│  │  - AppRole   │  │  QrDisplay   │         │                       │
│  │    enum      │  │  Scheduling  │         │ HTTP / Device APIs    │
│  │  - switch()  │  │  UploadProof │         ▼                       │
│  │  - prefs     │  │              │  ┌──────────────┐              │
│  │              │  │ Citizen:     │  │   BACKEND    │              │
│  │PickupProvider│  │  Complaints  │  │  (REST API)  │              │
│  │  - pickups[] │  │  Report      │  │              │              │
│  │  - load()    │  │  Awareness   │  │ /login       │              │
│  │  - update()  │  │              │  │ /register-   │              │
│  │  - optimistic│  │ Driver:      │  │   site       │              │
│  │    rollback  │  │  Pickups     │  │ /complaints  │              │
│  └──────────────┘  │  QrScanner   │  │ /pickups     │              │
│                    │  UploadDisp  │  │ /schedule    │              │
│  ┌──────────────┐  └──────────────┘  │ /upload-     │              │
│  │   MODELS     │                    │   proof      │              │
│  │              │  ┌──────────────┐  └──────────────┘              │
│  │ UserModel    │  │   WIDGETS    │                                  │
│  │ SiteModel    │  │              │  ┌──────────────┐              │
│  │ ComplaintMdl │  │ AppScaffold  │  │ DEVICE APIs  │              │
│  │ PickupModel  │  │ StatusChip   │  │              │              │
│  │  + enum      │  │ LoadingBtn   │  │ Camera       │              │
│  │  + copyWith  │  │ ImgPickerBox │  │ GPS          │              │
│  │ DriverModel  │  │ DriverInfo   │  │ Phone Dialer │              │
│  └──────────────┘  │   Card       │  │ SharedPrefs  │              │
│                    └──────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 6. NAVIGATION FLOW DIAGRAM

```
App Start
    │
    ▼
[SplashScreen]
    │
    ├── SharedPrefs has valid session?
    │       YES ──► role == 'contractor' ──► /contractor/dashboard
    │               role == 'citizen'    ──► /citizen/complaints
    │               role == 'driver'     ──► /driver/pickups
    │
    └── NO ──► [LoginScreen]
                    │
                    ▼ (login success)
              [RoleSelectionScreen]
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
    Contractor   Citizen    Driver
          │         │         │
          ▼         ▼         ▼
    /contractor  /citizen  /driver
    /dashboard  /complaints /pickups
          │         │         │
    ┌─────┤    ┌────┤    ┌────┤
    │     │    │    │    │    │
    ▼     ▼    ▼    ▼    ▼    ▼
  Site   QR  Report Aware QR  Upload
  Reg  Display Comp  ness Scan Disp
    │
    ▼
  Schedule
  Pickup
    │
    ▼
  Upload
  Proof

  [AppScaffold Role Switcher] — available on ALL home screens
  Switches between any role WITHOUT logout, persists to SharedPrefs
```

---

## 7. PICKUP STATUS WORKFLOW (Driver State Machine)

```
  ┌─────────┐
  │ PENDING │  ◄── Initial state when assigned by system
  └────┬────┘
       │ Driver taps "Accept Pickup"
       ▼
  ┌──────────┐
  │ ACCEPTED │  ◄── Driver has acknowledged the job
  └────┬─────┘
       │ Driver taps "Start" (optionally scans QR first)
       ▼
  ┌─────────────┐
  │ IN PROGRESS │  ◄── Driver is actively collecting waste
  └──────┬──────┘
         │
    ┌────┴────┐
    ▼         ▼
┌─────────┐ ┌────────┐
│COMPLETED│ │ FAILED │  ◄── Failed requires reason text input
└─────────┘ └────────┘

Color coding:
  PENDING     → Grey
  ACCEPTED    → Blue
  IN PROGRESS → Indigo
  COMPLETED   → Green
  FAILED      → Red
```

---

## 8. DATA MODELS — DETAILED

### UserModel (user_model.dart)
```
id       String   Unique user identifier from backend
email    String   Login email address
role     String   'contractor' | 'citizen' | 'driver'
token    String   Auth token for API requests
```
Used by: AuthProvider, SplashScreen, RoleSelectionScreen

---

### SiteModel (site_model.dart)
```
id             String   Unique site ID
name           String   Site display name
location       String   Address / description
area           double   Site area in square metres
expectedWaste  double   Estimated waste in tonnes
qrCode         String   QR code string for driver scanning
pickupStatus   String   Current pickup status (plain string)
actualWaste    double   Recorded waste after pickup
```
Used by: ContractorDashboard, SiteRegistration, QrDisplay, Scheduling, UploadProof

---

### ComplaintModel (complaint_model.dart)
```
id           String   Unique complaint ID
description  String   Text description of the issue
latitude     double   GPS latitude of complaint location
longitude    double   GPS longitude of complaint location
status       String   'Pending' | 'Under Review' | 'Resolved'
createdAt    String   Submission date string
imageUrl     String   URL of uploaded complaint photo
```
Used by: ComplaintsScreen, ReportComplaintScreen

---

### PickupModel (pickup_model.dart)
```
id             String         Unique pickup ID
siteId         String         Reference to site
siteName       String         Display name
location       String         Site address
scheduledDate  String         Planned pickup date
status         PickupStatus   Enum: pending/accepted/inProgress/completed/failed
qrCode         String         QR code to validate at site
wasteType      String         Type of waste (Construction Debris, etc.)
driverId       String?        Assigned driver ID (nullable)
driverName     String?        Driver display name (nullable)
driverPhone    String?        Driver phone number (nullable)
driverVehicle  String?        Vehicle description (nullable)
notes          String?        Failure reason or additional notes (nullable)
```
Key methods:
- `copyWith({status, notes})` — returns new instance with updated fields, used for optimistic updates
- `PickupStatusExt.fromString(s)` — parses string to enum safely

---

### DriverModel (driver_model.dart)
```
id         String    Unique driver ID
name       String    Full name
phone      String    Contact number
vehicle    String    Vehicle description
latitude   double?   Current GPS latitude (nullable)
longitude  double?   Current GPS longitude (nullable)
```
Used by: DriverInfoCard widget (ready for map integration)

---

## 9. PROVIDERS — DETAILED

### AuthProvider (auth_provider.dart)
State manager for authentication. Extends ChangeNotifier.

```
State:
  _user          UserModel?   Currently logged-in user
  _isLoading     bool         Login API in progress
  _initialized   bool         Session restore complete
  _error         String?      Last login error message

Getters:
  user           UserModel?   Public user access
  isLoading      bool
  isLoggedIn     bool         true if user != null AND role is set
  initialized    bool         Used by SplashScreen to wait for prefs load
  error          String?

Methods:
  login(email, password)      Calls ApiService.login(), stores to prefs
  setRole(role)               Updates user role, saves to prefs
  logout()                    Clears user + all SharedPreferences
  _loadFromPrefs()            Called in constructor, restores session
  _saveToPrefs(user)          Persists user_id, email, role, token
  _clearPrefs()               Wipes all stored keys
```

SharedPreferences keys: `user_id`, `user_email`, `user_role`, `user_token`

---

### RoleProvider (role_provider.dart)
Manages the active role independently of auth. Enables role switching without logout.

```
Enum AppRole: contractor | citizen | driver

AppRoleExt (extension):
  .name        String    'contractor' | 'citizen' | 'driver'
  .label       String    'Contractor' | 'Citizen' | 'Driver'
  .icon        IconData  engineering | person | local_shipping
  .color       Color     Colors.blue | green | deepOrange
  .homeRoute   String    '/contractor/dashboard' | etc.
  .fromString  static    Parses string to AppRole enum

State:
  _currentRole   AppRole   Active role (default: contractor)
  _initialized   bool

Methods:
  switchRole(role)   Updates role, saves to SharedPreferences
  _loadRole()        Restores from prefs on startup
```

SharedPreferences key: `current_role`

---

### PickupProvider (pickup_provider.dart)
Manages the driver's pickup list with optimistic state updates.

```
State:
  _pickups   List<PickupModel>   All loaded pickups
  _loading   bool
  _error     String?

Getters:
  pickups          List<PickupModel>
  loading          bool
  error            String?
  countByStatus(s) int   Counts pickups matching a given PickupStatus

Methods:
  loadPickups()
    - Sets loading = true
    - Calls PickupService.getAssignedPickups()
    - Populates _pickups list
    - Handles errors gracefully

  updateStatus(pickupId, newStatus, {notes})
    - Finds pickup by ID
    - Saves old state
    - Applies new status immediately (optimistic update)
    - Calls PickupService.updatePickupStatus()
    - On failure: rolls back to old state
    - Returns bool success
```

---

## 10. SERVICES — DETAILED

### ApiService (api_service.dart)
Central HTTP service. All methods are static. Currently uses dummy data with `Future.delayed` to simulate network latency. Every method has a `// TODO` comment showing the real API call to replace it with.

```
Base URL: https://your-api-base-url.com/api

CONTRACTOR methods:
  registerSite({name, location, area, expectedWaste})
    → POST /register-site
    → Returns Map with site data including generated qr_code

  getContractorSites()
    → GET /contractor/sites
    → Returns List of 2 dummy sites

  schedulePickup(siteId, date)
    → POST /schedule-pickup
    → Returns bool

  uploadProof(siteId, imagePath, quantity)
    → POST /upload-proof (multipart)
    → Returns bool

AUTH methods:
  login(email, password)
    → POST /login
    → Returns {id, email, token, role}

CITIZEN methods:
  submitComplaint({description, latitude, longitude, imagePath})
    → POST /complaints (multipart)
    → Returns bool

  getComplaints()
    → GET /complaints
    → Returns List of 3 dummy complaints with statuses:
      'Under Review', 'Resolved', 'Pending'

DRIVER methods:
  getAssignedPickups()
    → GET /driver/pickups
    → Returns List (legacy, now superseded by PickupService)

  validateQrCode(qrCode)
    → POST /validate-qr
    → Returns bool (true if starts with 'QR_SITE_')

  uploadDisposalProof(pickupId, imagePath)
    → POST /disposal-proof (multipart)
    → Returns bool
```

---

### PickupService (pickup_service.dart)
Dedicated service for driver pickup operations. Separated from ApiService for cleaner architecture.

```
Methods:
  getAssignedPickups()
    → Returns List<PickupModel> (3 dummy pickups)
    → Includes full driver info: name, phone, vehicle
    → Statuses: Pending, Completed, Accepted

  updatePickupStatus(pickupId, status, {notes})
    → PATCH /pickups/{id}/status
    → Body: {status, notes}
    → Returns bool

  uploadDisposalProof(pickupId, imagePath)
    → POST multipart
    → Returns bool
```

---

### LocationService (location_service.dart)
Wraps geolocator with full permission handling. Returns a clean result object.

```
LocationResult class:
  latitude   double?   null if failed
  longitude  double?   null if failed
  error      String?   Human-readable error message
  success    bool      true if both lat/lng are non-null

Methods:
  getCurrentLocation() → LocationResult
    Flow:
    1. Check if location service is enabled
    2. Check current permission status
    3. Request permission if denied
    4. Return error if permanently denied
    5. Get position with LocationAccuracy.high
    6. Wrap in try/catch for unexpected errors

  format(lat, lng) → String
    Returns "24.71360, 46.67530" formatted string
```

---

### ImageService (image_service.dart)
Centralized image picking with a polished bottom sheet UI.

```
Methods:
  pickImage(context) → Future<File?>
    - Shows modal bottom sheet with drag handle
    - Two options: Camera (blue icon) | Gallery (green icon)
    - imageQuality: 75 (compression applied)
    - Returns File or null if cancelled
    - Uses static ImagePicker instance
```

---

### CallService (call_service.dart)
Phone dialer integration via url_launcher.

```
Methods:
  call(context, phone) → Future<void>
    - Builds tel: URI
    - Checks canLaunchUrl() first
    - Launches phone dialer
    - Shows error snackbar if launch fails
```

---

### NotificationService (notification_service.dart)
Global notification system using a scaffoldMessengerKey. Works without BuildContext.

```
Static key: GlobalKey<ScaffoldMessengerState>
  → Attached to MaterialApp.scaffoldMessengerKey
  → Allows showing snackbars from anywhere in the app

Notification methods (all show floating SnackBar, 3s duration):
  complaintResolved(description)  → Green snackbar with check_circle icon
  pickupAssigned(siteName)        → Blue snackbar with local_shipping icon
  pickupCompleted(siteName)       → Green snackbar with check_circle_outline
  pickupFailed(siteName)          → Red snackbar with warning_amber icon

Upgrade path: Replace _show() body with flutter_local_notifications
```

---

## 11. SCREENS — DETAILED

### SplashScreen
- Orange background with construction icon and app name
- On init: polls AuthProvider.initialized (50ms intervals)
- After 800ms delay: routes based on saved role
- If not logged in: goes to /login
- Prevents back navigation (pushReplacementNamed)

---

### LoginScreen
- Email + password form with GlobalKey<FormState>
- Email validator: must contain '@'
- Password validator: minimum 6 characters
- Password visibility toggle (eye icon)
- Shows AuthProvider.error in red text
- Login button disabled during loading, shows CircularProgressIndicator
- On success: navigates to /role-selection

---

### RoleSelectionScreen
- Three role cards (Contractor, Citizen, Driver)
- Each card: CircleAvatar icon + title + subtitle + chevron
- On tap: calls AuthProvider.setRole() + RoleProvider.switchRole()
- Then navigates to role's homeRoute
- No back button (automaticallyImplyLeading: false)

---

### ContractorDashboardScreen
Uses AppScaffold. Loads sites from ApiService on init.

Site cards show:
- Site name + StatusChip
- Location with pin icon
- Stats row: Expected waste | Actual waste | Area
- Three action buttons: QR | Schedule | Proof
- Pull-to-refresh supported
- Empty state with construction icon

FAB: "New Site" → /contractor/register-site → refreshes on return

---

### SiteRegistrationScreen
Four validated fields:
- Site Name (required)
- Location/Address (required)
- Area in m² (required, must be valid double)
- Expected Waste in tonnes (required, must be valid double)

On submit: calls ApiService.registerSite() → navigates to QR display with site as argument

---

### QrDisplayScreen
Receives SiteModel via route arguments.
- Shows site name + location
- QR placeholder (200x200 container with qr_code_2 icon)
- Displays raw QR code string
- Share button (TODO: implement share/download)
- Dashboard button → /contractor/dashboard
- TODO comment: replace with QrImageView from qr_flutter package

---

### PickupSchedulingScreen
Receives SiteModel via route arguments.
- Site details card at top
- Date picker (today+1 to today+60 days)
- Formats date as YYYY-MM-DD
- Submit calls ApiService.schedulePickup()
- Success snackbar + Navigator.pop()

---

### UploadProofScreen (Contractor)
Receives SiteModel via route arguments.
- Site name card
- Image picker box (200px height) using ImageService
- Edit overlay button on selected image
- Waste quantity text field (numeric)
- LoadingButton for submit
- Calls ApiService.uploadProof()

---

### ComplaintsScreen (Citizen)
Uses AppScaffold with extra Awareness icon in AppBar.
- Loads complaints from ApiService on init
- Pull-to-refresh
- Each card: description + StatusChip + location + date
- Empty state with report_off icon
- FAB: "Report" → /citizen/report → refreshes on return

---

### ReportComplaintScreen
Three-part form:
1. Image picker (190px, tap to open ImageService sheet, edit overlay)
2. Description text field (3 lines)
3. GPS location row with Fetch/Refresh button

Validation: all three required before submit
Uses LocationService for GPS with full permission flow
Uses ImageService for photo selection
Calls ApiService.submitComplaint()

---

### AwarenessScreen
Static educational content screen.
- Green gradient hero banner
- 7 tip cards (icon + title + body text):
  Segregate Waste, Reduce Single-Use, Construction Tips,
  Composting, Hazardous Disposal, Protect Water, Report Dumping
- Waste Segregation Guide with 5 color-coded badges:
  Organic (green), Paper (blue), Plastic (teal), Metal (orange), Hazardous (red)

---

### PickupsScreen (Driver)
Uses AppScaffold + PickupProvider via Consumer.

Structure:
- _SummaryBar: shows Pending / In Progress / Completed counts (deepOrange background)
- TabBar: Active | Completed | All
- TabBarView: filtered lists per tab
- Pull-to-refresh on each tab
- Error view with Retry button

Each pickup card (_PickupCard):
- Site name + StatusChip
- Location, date, waste type, notes (if any)
- _WorkflowButtons based on current status

_WorkflowButtons state machine:
- PENDING    → "Accept Pickup" (blue, full width)
- ACCEPTED   → "Scan QR" (outlined) + "Start" (indigo)
- IN PROGRESS → "Mark as Completed" (green) + "Mark as Failed" (red outlined)
- COMPLETED  → Read-only green text + "Proof" upload button
- FAILED     → Read-only red text

"Mark as Failed" opens AlertDialog asking for failure reason text.
All transitions use PickupProvider.updateStatus() with optimistic rollback.

---

### QrScannerScreen (Driver)
Receives PickupModel via route arguments.
- Full-screen MobileScanner camera view
- Orange 250x250 scan frame overlay
- Torch toggle button in AppBar
- Validates scanned code via ApiService.validateQrCode()
- Valid: AlertDialog with site name + "Upload Proof" button
- Invalid: AlertDialog with "Try Again" option
- Prevents double-scan with _scanned flag

---

### UploadDisposalScreen (Driver)
Receives PickupModel via route arguments.
- Pickup details card (site, location, waste type)
- Image picker (220px) using ImageService
- Edit overlay on selected image
- LoadingButton submit
- On success: pushReplacementNamed to /driver/pickups

---

## 12. WIDGETS — DETAILED

### AppScaffold (app_scaffold.dart)
Drop-in Scaffold replacement used on all module home screens.

```
Props:
  title              String         AppBar title
  body               Widget         Main content
  floatingActionButton Widget?      Optional FAB
  extraActions       List<Widget>?  Additional AppBar icons
  showRoleSwitcher   bool           Default true

AppBar color: dynamically set from RoleProvider.currentRole.color
  Contractor → Colors.blue
  Citizen    → Colors.green
  Driver     → Colors.deepOrange

_RoleSwitcherButton:
  - PopupMenuButton showing all 3 roles
  - Active role shown with bold text + check icon
  - On select: calls RoleProvider.switchRole() + AuthProvider.setRole()
  - Navigates to new role's homeRoute

_LogoutButton:
  - Shows confirmation AlertDialog
  - On confirm: AuthProvider.logout() + pushNamedAndRemoveUntil to /login
```

---

### StatusChip (status_chip.dart)
Reusable colored badge for any status string.

```
Input: status String

Color mapping:
  completed / resolved  → Colors.green
  accepted              → Colors.blue
  inprogress            → Colors.indigo
  scheduled             → Colors.teal
  underreview           → Colors.orange
  failed                → Colors.red
  default               → Colors.grey

Icon mapping:
  completed/resolved → check_circle
  accepted           → thumb_up
  inprogress         → directions_car
  scheduled          → schedule
  underreview        → hourglass_top
  failed             → cancel
  default            → pending

Style: pill shape, colored border, semi-transparent background fill
```

---

### LoadingButton (loading_button.dart)
ElevatedButton that shows a spinner when loading.

```
Props:
  isLoading   bool          Disables button + shows spinner
  label       String        Button text
  onPressed   VoidCallback? Null when loading
  color       Color         Background (default: orange)
  icon        IconData?     Optional leading icon

When loading: 20x20 white CircularProgressIndicator (strokeWidth 2)
When idle: icon (if provided) + label text
```

---

### ImagePickerBox (image_picker_box.dart)
Reusable tap-to-pick image container widget.

```
Props:
  image   File?        Currently selected image (null = placeholder)
  onTap   VoidCallback Called when tapped

States:
  null image: grey placeholder with add_a_photo icon
  has image:  full-cover Image.file display

Also exports: pickImageFromSheet(context) → Future<File?>
  Helper function showing camera/gallery bottom sheet
  (Note: ImageService.pickImage() is the newer preferred version)
```

---

### DriverInfoCard (driver_info_card.dart)
Shows assigned driver details on contractor-facing screens.

```
Props:
  pickup   PickupModel   Source of driver data

Renders nothing if pickup.driverName is null.

Shows:
  - "Assigned Driver" label + StatusChip (live pickup status)
  - CircleAvatar with person icon
  - Driver name + vehicle description
  - Phone button → CallService.call() → opens phone dialer

Styling: blue-tinted container with border
```

---

## 13. ROUTE TABLE

| Route | Screen | Auth Required | Passes Argument |
|---|---|---|---|
| /splash | SplashScreen | No | — |
| /login | LoginScreen | No | — |
| /role-selection | RoleSelectionScreen | Yes | — |
| /contractor/dashboard | ContractorDashboardScreen | Yes | — |
| /contractor/register-site | SiteRegistrationScreen | Yes | — |
| /contractor/qr-display | QrDisplayScreen | Yes | SiteModel |
| /contractor/schedule-pickup | PickupSchedulingScreen | Yes | SiteModel |
| /contractor/upload-proof | UploadProofScreen | Yes | SiteModel |
| /citizen/complaints | ComplaintsScreen | Yes | — |
| /citizen/report | ReportComplaintScreen | Yes | — |
| /citizen/awareness | AwarenessScreen | Yes | — |
| /driver/pickups | PickupsScreen | Yes | — |
| /driver/qr-scanner | QrScannerScreen | Yes | PickupModel |
| /driver/upload-disposal | UploadDisposalScreen | Yes | PickupModel |

Total routes: 14

---

## 14. SESSION PERSISTENCE STRATEGY

```
On Login:
  AuthProvider.login() → stores user_id, email, role, token to SharedPreferences
  RoleProvider.switchRole() → stores current_role to SharedPreferences

On App Start:
  SplashScreen waits for AuthProvider.initialized
  AuthProvider constructor calls _loadFromPrefs()
  If all 4 keys exist AND role is non-empty → restores UserModel
  SplashScreen routes directly to role's home screen

On Role Switch (no logout):
  RoleProvider.switchRole() → updates current_role in prefs
  AuthProvider.setRole() → updates user_role in prefs
  Navigator.pushReplacementNamed() → goes to new home screen

On Logout:
  AuthProvider.logout() → SharedPreferences.clear() → user = null
  Navigator.pushNamedAndRemoveUntil('/login') → clears back stack
```

---

## 15. ERROR HANDLING PATTERNS

| Location | Pattern |
|---|---|
| Login | try/catch → sets _error string → displayed in UI |
| Site loading | try/catch → snackbar error message |
| Pickup status update | Optimistic update → rollback on failure |
| GPS fetch | LocationResult.error string → snackbar |
| Image pick | Returns null if cancelled → UI stays unchanged |
| Phone call | canLaunchUrl check → snackbar if fails |
| QR validation | Invalid dialog with Try Again option |
| All async submits | try/catch/finally → loading state always reset |

---

## 16. WHAT IS DUMMY / WHAT NEEDS REAL API

| Feature | Current State | What to Replace |
|---|---|---|
| Login | Returns dummy token | POST /login with real credentials |
| Site registration | Returns hardcoded site_001 | POST /register-site |
| Contractor sites | 2 hardcoded sites | GET /contractor/sites |
| Schedule pickup | Always returns true | POST /schedule-pickup |
| Upload proof | Always returns true | POST multipart /upload-proof |
| Complaints list | 3 hardcoded complaints | GET /complaints |
| Submit complaint | Always returns true | POST multipart /complaints |
| Driver pickups | 3 hardcoded pickups | GET /driver/pickups |
| Update pickup status | Always returns true | PATCH /pickups/{id}/status |
| QR validation | Checks prefix 'QR_SITE_' | POST /validate-qr |
| Upload disposal | Always returns true | POST multipart /disposal-proof |
| QR code display | Icon placeholder | Add qr_flutter package |
| Notifications | SnackBar only | Add flutter_local_notifications |
| Driver location | Static in DriverModel | Real-time GPS stream |

---

## 17. PACKAGES SUMMARY

```
provider: ^6.1.2
  Used for: AuthProvider, RoleProvider, PickupProvider
  Pattern: ChangeNotifier + Consumer + context.read/watch

http: ^1.2.1
  Used for: ApiService (imported but calls are stubbed)
  Ready for: GET, POST, PATCH, multipart requests

image_picker: ^1.1.2
  Used for: ImageService.pickImage(), ImagePickerBox
  Sources: ImageSource.camera, ImageSource.gallery
  Quality: 75% compression applied

geolocator: ^12.0.0
  Used for: LocationService.getCurrentLocation()
  Accuracy: LocationAccuracy.high
  Handles: service check, permission request, deniedForever

mobile_scanner: ^5.2.3
  Used for: QrScannerScreen
  Features: MobileScannerController, torch toggle, BarcodeCapture

shared_preferences: ^2.3.2
  Used for: AuthProvider (4 keys), RoleProvider (1 key)
  Keys: user_id, user_email, user_role, user_token, current_role

url_launcher: ^6.3.0
  Used for: CallService.call()
  Scheme: tel:
```

---

## 18. TOTAL FILE COUNT

| Category | Count |
|---|---|
| Models | 5 |
| Providers | 3 |
| Services | 6 |
| Screens | 14 |
| Widgets | 5 |
| Config files | 2 (pubspec.yaml, AndroidManifest.xml) |
| Entry point | 1 (main.dart) |
| **Total** | **36 files** |
