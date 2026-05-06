from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class TodoBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, example="Buy groceries")
    description: Optional[str] = Field(None, max_length=1000, example="Milk, eggs, bread")


class TodoCreate(TodoBase):
    pass


class TodoUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=1000)
    completed: Optional[bool] = None


class TodoResponse(TodoBase):
    id: int
    completed: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class TodoListResponse(BaseModel):
    total: int
    items: list[TodoResponse]