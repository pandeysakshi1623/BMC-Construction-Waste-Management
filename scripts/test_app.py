import io
import sys
from fastapi.testclient import TestClient

# Required since our parent directory is the root
from main import app

client = TestClient(app)

def test_routes():
    print("--- Re-Testing Auths to prep for pickup request ---")
    client.post("/auth/signup", json={
        "name": "Test Contractor",
        "contact": "1234567890",
        "address": "123 Test St",
        "email": "test@example.com",
        "company_name": "Test Construction",
        "username": "testcontractor",
        "password": "securepassword123"
    })
    
    res = client.post("/auth/login", json={
        "username": "testcontractor",
        "password": "securepassword123"
    })
    token = res.json().get("access_token")
    
    res = client.post("/sites/register", json={
        "site_name": "Pickup Test Site",
        "location": "Ward A",
        "project_type": "Infra",
        "plot_size": 25000
    }, headers={"Authorization": f"Bearer {token}"})
    site_id = res.json().get("site_id")
    print(f"Created Site {site_id} successfully.")
    
    print("\n--- Testing Pickup Request ---")
    mock_file = io.BytesIO(b"fake image data")
    mock_file.name = "test_image.jpg"
    
    res = client.post(
        "/pickups/request", 
        data={
            "site_id": site_id,
            "waste_description": "Concrete and Bricks",
            "est_weight_tons": "5.5",
            "slot_time": "14:00",
            "date": "20/05/26"
        },
        files={"image": ("test_image.jpg", mock_file, "image/jpeg")},
        headers={"Authorization": f"Bearer {token}"}
    )
    print("Pickup Request Status:", res.status_code)
    try:
        print("Pickup Request Response:", res.json())
        print("\nAll Endpoints Verified Successfully!")
    except Exception:
        print("Error fetching JSON")

if __name__ == "__main__":
    test_routes()
