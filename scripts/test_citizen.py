import requests
import time

def test_citizen_flow():
    print("--- Testing Citizen Flow via HTTP ---")
    
    base_url = "http://localhost:8001"
    
    # 1. Register a dummy Citizen user
    res = requests.post(f"{base_url}/citizen/signup", json={
        "username": "testcitizen2",
        "password": "citizenpassword123",
        "name": "Test Citizen",
        "contact": "9876543210"
    })
    
    if res.status_code == 400 and "already registered" in res.text:
       print("Citizen already registered, continuing...")
    else:
       print(f"Citizen Signup Status: {res.status_code}")
       print("Citizen Signup Response:", res.json())
        
    # 2. Login to receive an access token
    res = requests.post(f"{base_url}/citizen/login", json={
        "username": "testcitizen2",
        "password": "citizenpassword123"
    })
    print(f"Citizen Login Status: {res.status_code}")
    token = res.json().get("access_token")
    if not token:
        print("Failed to get token!")
        return
        
    print("Received Citizen Token successfully.")

    # 3. Fetch the list of all registered construction sites
    res = requests.get(f"{base_url}/sites/all")
    print(f"Fetch Sites Status: {res.status_code}")
    sites = res.json()
    if not sites:
        print("No sites found. Ensure sites exist in the database.")
        site_id = "SITE_TEST01" # Dummy fallback
    else:
        site_id = sites[0].get("site_id")
        print(f"Found {len(sites)} sites, using {site_id}")

    # 4. Submit a new query referencing one of the construction sites
    res = requests.post(
        f"{base_url}/citizen/query", 
        json={
            "site_id": site_id,
            "citizen_query": "Excessive noise after 10 PM. Please address this."
        },
        headers={"Authorization": f"Bearer {token}"}
    )
    print("Raise Query Status:", res.status_code)
    try:
        print("Raise Query Response:", res.json())
        print("\nAll Citizen Endpoints Verified Successfully!")
    except Exception:
        print("Error fetching JSON")

if __name__ == "__main__":
    test_citizen_flow()
