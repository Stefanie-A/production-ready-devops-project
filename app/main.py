import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, Response, Depends, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.routers import todos
from app.database import Base, engine, get_db
from prometheus_client import Counter, generate_latest
from dotenv import load_dotenv

load_dotenv()

METRICS_API_KEY = os.environ["METRICS_API_KEY"]
REQUEST_COUNT = Counter("request_count", "Total number of requests received")


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Todo API",
    description="A simple Todo REST API built with FastAPI",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def count_requests(request: Request, call_next):
    REQUEST_COUNT.inc()
    return await call_next(request)


app.include_router(todos.router, prefix="/api/v1", tags=["todos"])


@app.get("/health", tags=["health"])
def health_check(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))
    return {"status": "healthy", "service": "todo-api", "version": "1.0.0"}


@app.get("/", tags=["root"])
def root():
    return {"message": "Welcome to the Todo API", "docs": "/docs"}


@app.get("/metrics", tags=["metrics"])
def get_metrics(
    request: Request,
    x_api_key: str = Header(default=None),
    authorization: str = Header(default=None)
):
    token = x_api_key
    if not token and authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
    
    if token != METRICS_API_KEY:
        raise HTTPException(status_code=403, detail="Forbidden")
    
    return Response(generate_latest(), media_type="text/plain")