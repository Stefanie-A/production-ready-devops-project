from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.schemas import TodoCreate, TodoUpdate, TodoResponse, TodoListResponse
from app import crud

router = APIRouter()


@router.get("/todos", response_model=TodoListResponse)
def list_todos(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=500, description="Max records to return"),
    completed: Optional[bool] = Query(None, description="Filter by completion status"),
    db: Session = Depends(get_db),
):
    """List all todos with optional filtering and pagination."""
    total, items = crud.get_todos(db, skip=skip, limit=limit, completed=completed)
    return TodoListResponse(total=total, items=items)


@router.post("/todos", response_model=TodoResponse, status_code=201)
def create_todo(todo: TodoCreate, db: Session = Depends(get_db)):
    """Create a new todo item."""
    return crud.create_todo(db, todo)


@router.get("/todos/{todo_id}", response_model=TodoResponse)
def get_todo(todo_id: int, db: Session = Depends(get_db)):
    """Get a single todo by ID."""
    todo = crud.get_todo(db, todo_id)
    if not todo:
        raise HTTPException(status_code=404, detail=f"Todo with id {todo_id} not found")
    return todo


@router.patch("/todos/{todo_id}", response_model=TodoResponse)
def update_todo(todo_id: int, todo_update: TodoUpdate, db: Session = Depends(get_db)):
    """Partially update a todo item."""
    todo = crud.update_todo(db, todo_id, todo_update)
    if not todo:
        raise HTTPException(status_code=404, detail=f"Todo with id {todo_id} not found")
    return todo


@router.delete("/todos/{todo_id}", status_code=204)
def delete_todo(todo_id: int, db: Session = Depends(get_db)):
    """Delete a todo item."""
    deleted = crud.delete_todo(db, todo_id)
    if not deleted:
        raise HTTPException(status_code=404, detail=f"Todo with id {todo_id} not found")