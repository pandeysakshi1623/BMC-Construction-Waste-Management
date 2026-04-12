from motor.motor_asyncio import AsyncIOMotorClient
import os

# Get Mongo URI from environment variable or use default local connection
MONGO_DETAILS = os.getenv("MONGO_DETAILS", "mongodb://localhost:27017")

client = AsyncIOMotorClient(MONGO_DETAILS)
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
