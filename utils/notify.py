"""
Notification utility — writes alerts to DB and sends email.

Email config via environment variables (.env):
  SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, SMTP_FROM

If SMTP_USER is not set, email is printed to console (dev mode).
"""
import os
import smtplib
import asyncio
from datetime import datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
SMTP_FROM = os.getenv("SMTP_FROM", SMTP_USER)


# ── DB alert writer ───────────────────────────────────────────────────────────

async def _write_alert(
    recipient_type: str,
    recipient_id: str,
    message: str,
    site_id: str = "",
):
    """Insert an alert document into MongoDB."""
    from database import alert_collection  # lazy import to avoid circular
    await alert_collection.insert_one({
        "recipient_type": recipient_type,
        "recipient_id": recipient_id,
        "message": message,
        "site_id": site_id,
        "is_read": False,
        "created_at": datetime.now().isoformat(),
        "timestamp": datetime.now().isoformat(),
    })


# ── Email sender ──────────────────────────────────────────────────────────────

def _send_email_sync(to: str, subject: str, body: str) -> bool:
    if not SMTP_USER or not SMTP_PASSWORD:
        print(f"[NOTIFY] (no SMTP) To: {to} | {subject}")
        return False
    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = SMTP_FROM or SMTP_USER
        msg["To"] = to
        msg.attach(MIMEText(body, "plain"))
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as s:
            s.ehlo(); s.starttls()
            s.login(SMTP_USER, SMTP_PASSWORD)
            s.sendmail(SMTP_USER, to, msg.as_string())
        print(f"[NOTIFY] Email sent → {to}: {subject}")
        return True
    except Exception as e:
        print(f"[NOTIFY] Email failed → {to}: {e}")
        return False


async def _send_email(to: str, subject: str, body: str):
    if not to or "@" not in to:
        return
    loop = asyncio.get_event_loop()
    await loop.run_in_executor(None, _send_email_sync, to, subject, body)


# ── Notification templates ────────────────────────────────────────────────────

async def notify_complaint_received(
    citizen_contact: str, description: str, query_id: str, citizen_id: str = ""
):
    msg = f'Complaint received: "{description}" (ID: {query_id}). Status: Pending.'
    await _write_alert("Citizen", citizen_id or citizen_contact, msg)
    await _write_alert("BMC", "BMC_MASTER",
                       f"New citizen complaint submitted: {description} (ID: {query_id})")
    await _send_email(
        citizen_contact,
        "BMC Waste Monitor — Complaint Received",
        f"Your complaint has been received.\n\n"
        f"Complaint ID : {query_id}\n"
        f"Description  : {description}\n"
        f"Status       : Pending\n\n"
        f"You will be notified when the status changes.\n— BMC Smart Waste Monitor",
    )


async def notify_complaint_status_changed(
    citizen_contact: str, description: str, query_id: str,
    new_status: str, citizen_id: str = ""
):
    msg = f'Complaint "{description}" status updated to {new_status} (ID: {query_id}).'
    await _write_alert("Citizen", citizen_id or citizen_contact, msg)
    await _send_email(
        citizen_contact,
        f"BMC Waste Monitor — Complaint {new_status}",
        f"Your complaint status has been updated.\n\n"
        f"Complaint ID : {query_id}\n"
        f"Description  : {description}\n"
        f"New Status   : {new_status}\n\n— BMC Smart Waste Monitor",
    )


async def notify_pickup_scheduled(
    contractor_email: str, contractor_name: str, site_name: str,
    pickup_id: str, scheduled_date: str, contractor_id: str = "", site_id: str = ""
):
    msg = f"Pickup scheduled for site '{site_name}' on {scheduled_date} (ID: {pickup_id})."
    await _write_alert("Contractor", contractor_id or contractor_email, msg, site_id)
    await _write_alert("BMC", "BMC_MASTER",
                       f"New pickup scheduled: {site_name} on {scheduled_date} (ID: {pickup_id})",
                       site_id)
    await _send_email(
        contractor_email,
        "BMC Waste Monitor — Pickup Scheduled",
        f"Dear {contractor_name},\n\n"
        f"A waste pickup has been scheduled.\n\n"
        f"Pickup ID : {pickup_id}\nSite      : {site_name}\nDate      : {scheduled_date}\n\n"
        f"— BMC Smart Waste Monitor",
    )


async def notify_penalty_issued(
    contractor_email: str, contractor_name: str,
    site_id: str, amount: float, reason: str, penalty_id: str,
    contractor_id: str = ""
):
    msg = f"Penalty ₹{amount} issued for site {site_id}. Reason: {reason or 'QR Scanned Issue'} (ID: {penalty_id})."
    await _write_alert("Contractor", contractor_id or contractor_email, msg, site_id)
    await _send_email(
        contractor_email,
        "BMC Waste Monitor — Penalty Issued",
        f"Dear {contractor_name},\n\n"
        f"A penalty has been issued.\n\n"
        f"Penalty ID : {penalty_id}\nSite ID    : {site_id}\n"
        f"Amount     : ₹{amount}\nReason     : {reason or 'QR Scanned Issue'}\n\n"
        f"— BMC Smart Waste Monitor",
    )


async def notify_site_registered(
    contractor_email: str, contractor_name: str,
    site_name: str, site_id: str, contractor_id: str = ""
):
    msg = f"Site '{site_name}' registered successfully (ID: {site_id}). QR code generated."
    await _write_alert("Contractor", contractor_id or contractor_email, msg, site_id)
    await _send_email(
        contractor_email,
        "BMC Waste Monitor — Site Registered",
        f"Dear {contractor_name},\n\n"
        f"Your site has been registered.\n\n"
        f"Site Name : {site_name}\nSite ID   : {site_id}\n\n"
        f"Display the QR code at the site entrance.\n— BMC Smart Waste Monitor",
    )


async def notify_pickup_status_changed(
    contractor_email: str, contractor_name: str,
    site_name: str, pickup_id: str, new_status: str,
    contractor_id: str = "", site_id: str = ""
):
    msg = f"Pickup for '{site_name}' is now {new_status} (ID: {pickup_id})."
    await _write_alert("Contractor", contractor_id or contractor_email, msg, site_id)
    await _write_alert("BMC", "BMC_MASTER", msg, site_id)
    await _send_email(
        contractor_email,
        f"BMC Waste Monitor — Pickup {new_status}",
        f"Dear {contractor_name},\n\n"
        f"Pickup status updated.\n\n"
        f"Pickup ID : {pickup_id}\nSite      : {site_name}\nStatus    : {new_status}\n\n"
        f"— BMC Smart Waste Monitor",
    )
