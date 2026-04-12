import asyncio
import pandas as pd
import os
from passlib.context import CryptContext
from motor.motor_asyncio import AsyncIOMotorClient

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
def get_password_hash(password):
    return pwd_context.hash(password)

async def seed_data():
    print("Starting data seeding...")
    MONGO_DETAILS = os.getenv("MONGO_DETAILS", "mongodb://localhost:27017")
    client = AsyncIOMotorClient(MONGO_DETAILS)
    database = client.bmc_waste_management
    
    contractor_collection = database.get_collection("contractors")
    site_collection = database.get_collection("sites")
    pickup_collection = database.get_collection("pickups")

    # Clear existing generic data to prevent duplicates on re-runs
    await contractor_collection.delete_many({})
    await site_collection.delete_many({})

    # Seed Contractors
    try:
        contractor_df = pd.read_csv('data_source/1_Contractor_Details.csv')
        contractor_data = contractor_df.to_dict(orient='records')
        
        default_hash = get_password_hash("Password123!")
        
        for i, c in enumerate(contractor_data):
            c['username'] = c['email'].split('@')[0]
            c['hashed_password'] = default_hash
            c['contact'] = str(c['contact'])

        if contractor_data:
            await contractor_collection.insert_many(contractor_data)
            print(f"✅ Loaded {len(contractor_data)} Contractors into MongoDB.")
    except Exception as e:
        print(f"❌ Error loading Contractors CSV: {e}")

    # Seed Sites
    try:
        site_df = pd.read_csv('data_source/2_Site_Onboarding.csv')
        site_data = site_df.to_dict(orient='records')

        if site_data:
            await site_collection.insert_many(site_data)
            print(f"✅ Loaded {len(site_data)} Sites into MongoDB.")
    except Exception as e:
        print(f"❌ Error loading Sites CSV: {e}")
        
    # Seed Pickups
    await pickup_collection.delete_many({})
    try:
        pickup_df = pd.read_csv('data_source/3_Truck_Schedules.csv')
        pickup_data = pickup_df.to_dict(orient='records')
        
        # Vehicle number in CSV handles "N/A" as string or NaN, ensure it's coerced to string where needed
        for p in pickup_data:
            if pd.isna(p.get("vehicle_number")):
                p["vehicle_number"] = "N/A"

        if pickup_data:
            await pickup_collection.insert_many(pickup_data)
            print(f"✅ Loaded {len(pickup_data)} Pickups into MongoDB.")
    except Exception as e:
        print(f"❌ Error loading Pickups CSV: {e}")

    penalty_collection = database.get_collection("penalties")
    bmc_master_collection = database.get_collection("bmc_master")
    citizen_collection = database.get_collection("citizens")
    official_collection = database.get_collection("officials")

    # Clear existing
    await penalty_collection.delete_many({})
    await bmc_master_collection.delete_many({})
    await citizen_collection.delete_many({})
    await official_collection.delete_many({})

    # Seed Admin Official
    await official_collection.insert_one({
        "username": "admin",
        "password": get_password_hash("password123"),
        "role": "admin"
    })
    print("✅ Seeded default BMC Admin Official (admin / password123).")

    # Seed Penalties
    try:
        penalty_df = pd.read_csv('data_source/4_Penalties_Master.csv')
        penalty_data = penalty_df.to_dict(orient='records')
        if penalty_data:
            await penalty_collection.insert_many(penalty_data)
            print(f"✅ Loaded {len(penalty_data)} Penalties into MongoDB.")
    except Exception as e:
        print(f"❌ Error loading Penalties CSV: {e}")

    # Seed BMC Master
    try:
        bmc_df = pd.read_csv('data_source/5_BMC_Master_Database.csv')
        # fix NaN in citizen_query handling
        bmc_df['citizen_query'] = bmc_df['citizen_query'].fillna('N/A')
        bmc_df['citizen_id'] = bmc_df['citizen_id'].fillna('N/A')
        bmc_data = bmc_df.to_dict(orient='records')
        if bmc_data:
            await bmc_master_collection.insert_many(bmc_data)
            print(f"✅ Loaded {len(bmc_data)} BMC Master records into MongoDB.")
    except Exception as e:
        print(f"❌ Error loading BMC Master CSV: {e}")

    # Seed Citizen Queries and Dummy Citizens
    citizen_query_collection = database.get_collection("citizen_queries")
    await citizen_query_collection.delete_many({})
    
    try:
        citizen_df = pd.read_csv('data_source/6_Citizen_Module.csv')
        citizen_data = citizen_df.to_dict(orient='records')
        
        # Create unique dummy citizens for the citizen accounts
        unique_citizen_ids = list(set([c["citizen_id"] for c in citizen_data]))
        dummy_citizens = []
        default_citizen_hash = get_password_hash("citizen123")
        for cid in unique_citizen_ids:
            dummy_citizens.append({
                "citizen_id": cid,
                "username": f"user_{cid.lower()}",
                "hashed_password": default_citizen_hash,
                "contact": "9999999999"
            })
            
        if dummy_citizens:
            await citizen_collection.insert_many(dummy_citizens)
            print(f"✅ Loaded {len(dummy_citizens)} dummy Citizen Users into MongoDB.")
            
        if citizen_data:
            # Generate random query IDs mapping
            import uuid
            for q in citizen_data:
                q['query_id'] = str(uuid.uuid4())
            await citizen_query_collection.insert_many(citizen_data)
            print(f"✅ Loaded {len(citizen_data)} Citizen Queries into MongoDB.")
    except Exception as e:
        print(f"❌ Error loading Citizens CSV: {e}")

    client.close()

if __name__ == "__main__":
    asyncio.run(seed_data())
