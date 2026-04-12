from pymongo import MongoClient

def get_db():
    # This is your connection string for a local MongoDB server
    connection_string = "mongodb://localhost:27017/"
    
    try:
        client = MongoClient(connection_string, serverSelectionTimeoutMS=2000)
        # Testing the connection
        client.server_info() 
        print("✅ Successfully connected to MongoDB local server")
        return client["BMC_Waste_DB"]
    except Exception as e:
        print(f"❌ Could not connect to MongoDB: {e}")
        return None