from motor.motor_asyncio import AsyncIOMotorClient
import os

MONGO_DETAILS = os.getenv("MONGO_DETAILS", "mongodb://localhost:27017")

client = AsyncIOMotorClient(
    MONGO_DETAILS,
    maxPoolSize=10,        # connection pool — reuse sockets
    minPoolSize=2,
    serverSelectionTimeoutMS=5000,
)
database = client.bmc_waste_management

# Collections
contractor_collection = database.get_collection("contractors")
site_collection = database.get_collection("sites")
pickup_collection = database.get_collection("pickups")
penalty_collection = database.get_collection("penalties")
bmc_master_collection = database.get_collection("bmc_master")
citizen_collection = database.get_collection("citizens")
citizen_query_collection = database.get_collection("citizen_queries")
official_collection = database.get_collection("officials")
alert_collection = database.get_collection("alerts")
proof_history_collection = database.get_collection("proof_history")
driver_location_collection = database.get_collection("driver_locations")
driver_rating_collection = database.get_collection("driver_ratings")


async def create_indexes():
    """Create indexes on startup for fast queries."""
    # Contractors / Drivers
    await contractor_collection.create_index("username", unique=True, background=True)
    await contractor_collection.create_index("contractor_id", background=True)

    # Sites
    await site_collection.create_index("contractor_id", background=True)
    await site_collection.create_index("site_id", unique=True, background=True)

    # Pickups
    await pickup_collection.create_index("pickup_id", unique=True, background=True)
    await pickup_collection.create_index("contractor_id", background=True)
    await pickup_collection.create_index("status", background=True)
    await pickup_collection.create_index("disposal_proof_url", background=True)

    # Penalties
    await penalty_collection.create_index("site_id", background=True)
    await penalty_collection.create_index("contractor_id", background=True)

    # Citizens
    await citizen_collection.create_index("username", unique=True, background=True)
    await citizen_collection.create_index("citizen_id", background=True)

    # Citizen queries
    await citizen_query_collection.create_index("citizen_id", background=True)
    await citizen_query_collection.create_index("status", background=True)

    # Driver locations — upsert by driver_id
    await driver_location_collection.create_index("driver_id", unique=True, background=True)

    # Alerts
    await alert_collection.create_index("contractor_id", background=True)
    await alert_collection.create_index("timestamp", background=True)
