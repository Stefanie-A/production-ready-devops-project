import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.database import Base, get_db

# Use in-memory SQLite for tests
TEST_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def setup_database():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_root():
    response = client.get("/")
    assert response.status_code == 200


def test_create_todo():
    payload = {"title": "Test Todo", "description": "A test item"}
    response = client.post("/api/v1/todos", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Todo"
    assert data["completed"] is False
    assert "id" in data


def test_list_todos_empty():
    response = client.get("/api/v1/todos")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 0
    assert data["items"] == []


def test_list_todos_with_items():
    client.post("/api/v1/todos", json={"title": "Todo 1"})
    client.post("/api/v1/todos", json={"title": "Todo 2"})
    response = client.get("/api/v1/todos")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 2


def test_get_todo_by_id():
    create_resp = client.post("/api/v1/todos", json={"title": "Find me"})
    todo_id = create_resp.json()["id"]
    response = client.get(f"/api/v1/todos/{todo_id}")
    assert response.status_code == 200
    assert response.json()["title"] == "Find me"


def test_get_todo_not_found():
    response = client.get("/api/v1/todos/9999")
    assert response.status_code == 404


def test_update_todo():
    create_resp = client.post("/api/v1/todos", json={"title": "Old title"})
    todo_id = create_resp.json()["id"]
    response = client.patch(f"/api/v1/todos/{todo_id}", json={"title": "New title", "completed": True})
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "New title"
    assert data["completed"] is True


def test_update_todo_not_found():
    response = client.patch("/api/v1/todos/9999", json={"title": "Ghost"})
    assert response.status_code == 404


def test_delete_todo():
    create_resp = client.post("/api/v1/todos", json={"title": "Delete me"})
    todo_id = create_resp.json()["id"]
    response = client.delete(f"/api/v1/todos/{todo_id}")
    assert response.status_code == 204
    # Confirm it's gone
    get_resp = client.get(f"/api/v1/todos/{todo_id}")
    assert get_resp.status_code == 404


def test_delete_todo_not_found():
    response = client.delete("/api/v1/todos/9999")
    assert response.status_code == 404


def test_filter_by_completed():
    client.post("/api/v1/todos", json={"title": "Done"})
    create_resp = client.post("/api/v1/todos", json={"title": "Not done"})
    todo_id = create_resp.json()["id"]
    client.patch(f"/api/v1/todos/{todo_id}", json={"completed": False})

    response = client.get("/api/v1/todos?completed=false")
    assert response.status_code == 200
    for item in response.json()["items"]:
        assert item["completed"] is False


def test_create_todo_missing_title():
    response = client.post("/api/v1/todos", json={"description": "No title"})
    assert response.status_code == 422