from fastapi import APIRouter, Depends
from database import alert_collection
from utils.deps import get_current_user
from models.alert import AlertResponse

router = APIRouter(prefix="/alerts", tags=["Alerts"])


def _serialize_alert(a: dict) -> dict:
    a["alert_id"] = str(a.pop("_id"))
    # Expose created_at as timestamp too (Flutter reads 'timestamp')
    a.setdefault("timestamp", a.get("created_at"))
    a.setdefault("is_read", False)
    return a


@router.get("/contractor", response_model=list[AlertResponse])
async def get_contractor_alerts(current_user: dict = Depends(get_current_user)):
    """Fetch alerts for the logged-in contractor."""
    contractor_id = current_user.get("contractor_id")
    alerts = []
    async for a in alert_collection.find(
        {"recipient_type": "Contractor", "recipient_id": contractor_id}
    ):
        alerts.append(_serialize_alert(a))
    return alerts


@router.get("/bmc", response_model=list[AlertResponse])
async def get_bmc_alerts():
    """Fetch all alerts assigned to BMC Officials."""
    alerts = []
    async for a in alert_collection.find({"recipient_type": "BMC"}):
        alerts.append(_serialize_alert(a))
    return alerts
