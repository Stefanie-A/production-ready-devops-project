from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import todos
from app.database import Base, engine

# Create tables on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Todo API",
    description="A simple Todo REST API built with FastAPI",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(todos.router, prefix="/api/v1", tags=["todos"])


@app.get("/health", tags=["health"])
def health_check():
    return {"status": "healthy", "service": "todo-api", "version": "1.0.0"}


@app.get("/", tags=["root"])
def root():
    return {"message": "Welcome to the Todo API", "docs": "/docs"}