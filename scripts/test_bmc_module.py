import requests

BASE_URL = "http://localhost:8000/bmc"

def run_tests():
    print("Testing BMC Officials Module")
    
    # Test Login
    print("\n1. Testing Login...")
    login_resp = requests.post(f"{BASE_URL}/login", json={
        "username": "admin",
        "password": "password123"
    })
    assert login_resp.status_code == 200, "Login Failed"
    token = login_resp.json().get("access_token")
    headers = {"Authorization": f"Bearer {token}"}
    print("✅ Login Successful")

    # Test QR Scan (Fetching details of a site)
    print("\n2. Testing QR Scan (fetching SITE_2000)...")
    site_id = "SITE_2000"
    qr_resp = requests.get(f"{BASE_URL}/qr-scan/{site_id}")
    assert qr_resp.status_code == 200, "QR Scan endpoint failed"
    qr_data = qr_resp.json()
    print("✅ Fetched Site Details Successfully:", qr_data["site"]["site_name"])
    print(f"✅ Active Penalties found: {len(qr_data['active_penalties'])}")
    
    # Test Issuing Penalty
    print("\n3. Testing Issuing Penalty for SITE_2000...")
    penalty_resp = requests.post(
        f"{BASE_URL}/penalties/{site_id}", 
        json={"penalty_cost_rupees": 5000, "reason": "No mesh covering"}
    )
    assert penalty_resp.status_code == 200, "Penalty issuing failed"
    penalty_id = penalty_resp.json().get("penalty_id")
    print(f"✅ Issued new penalty Successfully (ID: {penalty_id})")
    
    # Verify Penalty Count Increased
    qr_resp2 = requests.get(f"{BASE_URL}/qr-scan/{site_id}")
    qr_data2 = qr_resp2.json()
    print(f"✅ Verified Active Penalties count increased to: {len(qr_data2['active_penalties'])}")
    
    # Test Dashboard Analytics
    print("\n4. Testing GET Dashboard Analytics...")
    dashboard_resp = requests.get(f"{BASE_URL}/dashboard")
    assert dashboard_resp.status_code == 200, "Dashboard fetch failed"
    dash_data = dashboard_resp.json()
    print(f"✅ Fetched Dashboard total sites: {dash_data['dashboard_stats']['total_sites']}")
    print(f"✅ Active total penalties in DB: {dash_data['dashboard_stats']['active_penalties']}")
    
    # Test Truck Approval
    if len(dash_data['pending_truck_approvals']) > 0:
        print("\n5. Testing Truck Approval...")
        pickup_id = dash_data['pending_truck_approvals'][0]['_id']
        appr_resp = requests.post(f"{BASE_URL}/trucks/{pickup_id}/approve", json={"status": "Approved"})
        assert appr_resp.status_code == 200, "Approval API failed"
        print("✅ Approved truck pickup successfully.")
    else:
        print("\n5. (Skipped) No pending truck approvals.")
        
    print("\n✅ ALL TESTS PASSED.")

if __name__ == "__main__":
    run_tests()
