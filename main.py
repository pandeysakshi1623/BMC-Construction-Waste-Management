from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routers import auth, sites, pickups, bmc, citizen, alerts
from utils.scheduler import generate_penalty_alerts
import asyncio
import os

app = FastAPI(title="BMC Construction Waste Management App", version="1.0.0")

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

@app.on_event("startup")
async def startup_event():
    # Start the 24h background alert job
    asyncio.create_task(generate_penalty_alerts())

@app.get("/")
def read_root():
    return {"message": "Welcome to the BMC Waste Management API"}