from sqlalchemy.orm import Session
from app.models import Todo
from app.schemas import TodoCreate, TodoUpdate


def get_todo(db: Session, todo_id: int):
    return db.query(Todo).filter(Todo.id == todo_id).first()


def get_todos(db: Session, skip: int = 0, limit: int = 100, completed: bool = None):
    query = db.query(Todo)
    if completed is not None:
        query = query.filter(Todo.completed == completed)
    total = query.count()
    items = query.offset(skip).limit(limit).all()
    return total, items


def create_todo(db: Session, todo: TodoCreate):
    db_todo = Todo(**todo.model_dump())
    db.add(db_todo)
    db.commit()
    db.refresh(db_todo)
    return db_todo


def update_todo(db: Session, todo_id: int, todo_update: TodoUpdate):
    db_todo = get_todo(db, todo_id)
    if not db_todo:
        return None
    update_data = todo_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_todo, field, value)
    db.commit()
    db.refresh(db_todo)
    return db_todo


def delete_todo(db: Session, todo_id: int):
    db_todo = get_todo(db, todo_id)
    if not db_todo:
        return False
    db.delete(db_todo)
    db.commit()
    return True