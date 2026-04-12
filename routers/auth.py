from fastapi import APIRouter, HTTPException, status
from database import contractor_collection
from models.contractor import ContractorCreate, ContractorLogin, Contractor
from models.token import Token
from utils.security import verify_password, get_password_hash, create_access_token
import uuid

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/signup", response_model=Contractor)
async def signup(contractor_data: ContractorCreate):
    existing_user = await contractor_collection.find_one({"username": contractor_data.username})
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already registered")
        
    contractor_dict = contractor_data.dict()
    contractor_dict["hashed_password"] = get_password_hash(contractor_dict.pop("password"))
    # Only generate ID if it isn't passed (which normally it won't be from the endpoint)
    contractor_dict["contractor_id"] = str(uuid.uuid4())
    
    new_contractor = await contractor_collection.insert_one(contractor_dict)
    created_contractor = await contractor_collection.find_one({"_id": new_contractor.inserted_id})
    return Contractor(**created_contractor)

@router.post("/login", response_model=Token)
async def login(login_data: ContractorLogin):
    user = await contractor_collection.find_one({"username": login_data.username})
    if not user or not verify_password(login_data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": user["username"], "contractor_id": user["contractor_id"]})
    return {"access_token": access_token, "token_type": "bearer"}
