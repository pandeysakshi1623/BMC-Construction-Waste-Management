from fastapi import APIRouter, HTTPException, status
from database import contractor_collection
from models.contractor import ContractorCreate, DriverCreate, ContractorLogin, Contractor
from models.token import Token
from utils.security import verify_password, get_password_hash, create_access_token
import uuid

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/signup", response_model=Contractor)
async def signup_contractor(contractor_data: ContractorCreate):
    existing = await contractor_collection.find_one({"username": contractor_data.username})
    if existing:
        raise HTTPException(status_code=400, detail="Username already registered")

    d = contractor_data.model_dump()
    d["hashed_password"] = get_password_hash(d.pop("password"))
    d["contractor_id"] = str(uuid.uuid4())
    d["role"] = "contractor"

    result = await contractor_collection.insert_one(d)
    created = await contractor_collection.find_one({"_id": result.inserted_id})
    return Contractor(**created)


@router.post("/signup/driver", response_model=Contractor)
async def signup_driver(driver_data: DriverCreate):
    existing = await contractor_collection.find_one({"username": driver_data.username})
    if existing:
        raise HTTPException(status_code=400, detail="Username already registered")

    d = driver_data.model_dump()
    d["hashed_password"] = get_password_hash(d.pop("password"))
    d["contractor_id"] = str(uuid.uuid4())
    d["address"] = ""
    d["email"] = ""
    d["company_name"] = ""
    d["role"] = "driver"

    result = await contractor_collection.insert_one(d)
    created = await contractor_collection.find_one({"_id": result.inserted_id})
    return Contractor(**created)


@router.post("/login", response_model=Token)
async def login(login_data: ContractorLogin):
    user = await contractor_collection.find_one({"username": login_data.username})

    print(f"Login attempt — username: {login_data.username}")
    print(f"User from DB: {user}")

    if not user:
        print("ERROR: User not found in DB")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    password_match = verify_password(login_data.password, user["hashed_password"])
    print(f"Password match: {password_match}")

    if not password_match:
        print("ERROR: Password mismatch")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    role = user.get("role", "contractor")
    access_token = create_access_token(
        data={"sub": user["username"], "contractor_id": user["contractor_id"], "role": role}
    )
    print(f"Login successful — role: {role}")
    return {"access_token": access_token, "token_type": "bearer", "role": role}


@router.post("/seed-test-user", tags=["Debug"])
async def seed_test_user():
    """
    Creates a test contractor account (username: testuser, password: test123).
    Use this endpoint ONLY for development/debugging.
    """
    username = "testuser"
    existing = await contractor_collection.find_one({"username": username})
    if existing:
        # Re-hash password in case it was stored incorrectly
        await contractor_collection.update_one(
            {"username": username},
            {"$set": {"hashed_password": get_password_hash("test123")}},
        )
        return {"message": f"User '{username}' already exists — password re-hashed to 'test123'"}

    await contractor_collection.insert_one({
        "username": username,
        "hashed_password": get_password_hash("test123"),
        "name": "Test Contractor",
        "contact": "9999999999",
        "address": "Test Address",
        "email": "test@example.com",
        "company_name": "Test Co",
        "contractor_id": str(uuid.uuid4()),
        "role": "contractor",
    })
    return {"message": f"Test user created — username: '{username}', password: 'test123'"}
