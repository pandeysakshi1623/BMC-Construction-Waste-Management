from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routers import auth, sites, pickups, bmc, citizen, alerts
from utils.scheduler import generate_penalty_alerts
from dotenv import load_dotenv
from contextlib import asynccontextmanager
import asyncio
import os

load_dotenv()  # Load .env variables before anything else

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    asyncio.create_task(generate_penalty_alerts())
    yield
    # Shutdown
    pass

app = FastAPI(title="BMC Construction Waste Management App", version="1.0.0", lifespan=lifespan)

# CORS Setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Uploads Directory for Images
os.makedirs("uploads", exist_ok=True)
app.mount("/static", StaticFiles(directory="uploads"), name="static")

app.include_router(auth.router)
app.include_router(sites.router)
app.include_router(pickups.router)
app.include_router(bmc.router)
app.include_router(citizen.router)
app.include_router(alerts.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the BMC Waste Management API"}