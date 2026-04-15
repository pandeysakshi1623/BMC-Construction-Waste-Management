import asyncio
from datetime import datetime
from database import penalty_collection, alert_collection
import uuid

async def generate_penalty_alerts():
    """
    Background job that runs every 24 hours.
    It checks for Active penalties and spawns alerts to both the Contractor and BMC.
    """
    while True:
        # Run alert logic
        print("Starting 24h penalty alert generation cycle...")
        cursor = penalty_collection.find({"penalty_status": "Active"})
        
        alerts_to_insert = []
        async for penalty in cursor:
            penalty_id = penalty.get("penalty_id", "UNKNOWN")
            site_id = penalty.get("site_id", "UNKNOWN")
            contractor_id = penalty.get("contractor_id", "UNKNOWN")
            cost = penalty.get("penalty_cost_rupees", 0)
            
            message = f"URGENT: Unpaid penalty {penalty_id} for site {site_id}. Amount: Rs {cost}."
            
            # Contractor Alert
            alerts_to_insert.append({
                "recipient_type": "Contractor",
                "recipient_id": contractor_id,
                "message": message,
                "is_read": False,
                "created_at": datetime.now().isoformat()
            })
            
            # BMC Master Alert
            alerts_to_insert.append({
                "recipient_type": "BMC",
                "recipient_id": "BMC_MASTER",
                "message": f"Contractor {contractor_id} has unpaid penalty {penalty_id} for site {site_id}. Amount: Rs {cost}.",
                "is_read": False,
                "created_at": datetime.now().isoformat()
            })
        
        if alerts_to_insert:
            await alert_collection.insert_many(alerts_to_insert)
            print(f"Generated {len(alerts_to_insert)} penalty alerts.")
        
        # Sleep for 24 hours (86400 seconds)
        await asyncio.sleep(86400)
