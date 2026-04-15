from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.openapi.utils import get_openapi
from routers import auth, sites, pickups, bmc, citizen, alerts
from utils.scheduler import generate_penalty_alerts
from dotenv import load_dotenv
from contextlib import asynccontextmanager
import asyncio
import os

load_dotenv()

@asynccontextmanager
async def lifespan(app: FastAPI):
    asyncio.create_task(generate_penalty_alerts())
    yield

app = FastAPI(
    title="BMC Construction Waste Management App",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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


def custom_openapi():
    """Add HTTPBearer security scheme so Swagger 'Authorize' accepts raw tokens."""
    if app.openapi_schema:
        return app.openapi_schema

    schema = get_openapi(
        title=app.title,
        version=app.version,
        routes=app.routes,
    )

    # Replace OAuth2 flow with simple HTTP Bearer — lets you paste token directly
    schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
            "description": (
                "Paste your JWT token here (without 'Bearer ' prefix).\n\n"
                "Get a token from POST /auth/login, POST /citizen/login, or POST /bmc/login."
            ),
        }
    }

    # Apply BearerAuth globally to all operations
    for path in schema.get("paths", {}).values():
        for operation in path.values():
            operation["security"] = [{"BearerAuth": []}]

    app.openapi_schema = schema
    return app.openapi_schema


app.openapi = custom_openapi