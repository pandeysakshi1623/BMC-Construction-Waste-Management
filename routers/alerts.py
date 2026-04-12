from fastapi import APIRouter, Depends
from database import alert_collection
from utils.deps import get_current_user
from models.alert import AlertResponse

router = APIRouter(prefix="/alerts", tags=["Alerts"])

@router.get("/contractor", response_model=list[AlertResponse])
async def get_contractor_alerts(current_user: dict = Depends(get_current_user)):
    """Fetch alerts for the logged-in contractor."""
    contractor_id = current_user.get("contractor_id")
    alerts_cursor = alert_collection.find({"recipient_type": "Contractor", "recipient_id": contractor_id})
    alerts = []
    async for a in alerts_cursor:
        a["alert_id"] = str(a["_id"])
        alerts.append(a)
    return alerts

@router.get("/bmc", response_model=list[AlertResponse])
async def get_bmc_alerts():
    """Fetch all alerts assigned to BMC Officials."""
    # Since BMC auth isn't fully required for all test apps currently, we allow this without token,
    # or you can add BMC official dependency later.
    alerts_cursor = alert_collection.find({"recipient_type": "BMC"})
    alerts = []
    async for a in alerts_cursor:
        a["alert_id"] = str(a["_id"])
        alerts.append(a)
    return alerts
