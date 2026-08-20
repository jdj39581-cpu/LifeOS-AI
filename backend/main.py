import os
import shutil

import psycopg2
import requests

from dotenv import load_dotenv
from openai import OpenAI
from PyPDF2 import PdfReader

from fastapi import (
    FastAPI,
    Depends,
    HTTPException,
    UploadFile,
    File,
)
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm

from pydantic import BaseModel, EmailStr

from security import hash_password, verify_password
from auth import create_access_token, verify_token


# ============================================================
# ENVIRONMENT
# ============================================================

load_dotenv()


# ============================================================
# DATABASE
# ============================================================

db = psycopg2.connect(os.getenv("DATABASE_URL"))
db.autocommit = True
cursor = db.cursor()    


# ============================================================
# OPENROUTER / AI
# ============================================================

client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1"
)


# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI(
    title="LifeOS AI",
    description="LifeOS AI Backend API",
    version="1.0.0"
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# AUTHENTICATION
# ============================================================

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="login"
)


def get_current_user(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid token"
        )

    return payload


# ============================================================
# PDF TEXT EXTRACTION
# ============================================================

def extract_pdf_text(file_path):
    reader = PdfReader(file_path)

    text = ""

    for page in reader.pages:
        page_text = page.extract_text()

        if page_text:
            text += page_text + "\n"

    return text


# ============================================================
# PYDANTIC MODELS
# ============================================================

class User(BaseModel):
    name: str
    email: EmailStr
    password: str


class Task(BaseModel):
    title: str
    description: str


class TaskUpdate(BaseModel):
    status: str


class UpdateTask(BaseModel):
    title: str
    description: str
    status: str


class Note(BaseModel):
    title: str
    content: str


class UpdateNote(BaseModel):
    title: str
    content: str


class Reminder(BaseModel):
    title: str
    reminder_time: str


class Expense(BaseModel):
    title: str
    amount: float
    category: str
    expense_date: str


class ChatMessage(BaseModel):
    message: str


class ChatRequest(BaseModel):
    message: str


class Goal(BaseModel):
    title: str
    target_date: str


class Habit(BaseModel):
    title: str


class Event(BaseModel):
    title: str
    description: str
    event_date: str
    event_time: str


class Notification(BaseModel):
    title: str
    message: str


class UpdateProfile(BaseModel):
    name: str
    email: EmailStr


class ChangePassword(BaseModel):
    old_password: str
    new_password: str


# ============================================================
# HOME
# ============================================================

@app.get("/")
def home():
    return {
        "message": "Welcome to LifeOS AI"
    }


# ============================================================
# REGISTER
# ============================================================

@app.post("/register")
def register(user: User):

    cursor.execute(
        """
        SELECT *
        FROM users
        WHERE email=%s
        """,
        (user.email,)
    )

    existing_user = cursor.fetchone()

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    hashed_password = hash_password(
        user.password
    )

    cursor.execute(
        """
        INSERT INTO users
        (name, email, password)
        VALUES (%s, %s, %s)
        """,
        (
            user.name,
            user.email,
            hashed_password
        )
    )

    db.commit()

    return {
        "message": "User registered successfully"
    }


# ============================================================
# LOGIN
# ============================================================

@app.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends()
):

    cursor.execute(
        """
        SELECT password
        FROM users
        WHERE email=%s
        """,
        (form_data.username,)
    )

    result = cursor.fetchone()

    if result is None:
        raise HTTPException(
            status_code=401,
            detail="User not found"
        )

    if not verify_password(
        form_data.password,
        result[0]
    ):
        raise HTTPException(
            status_code=401,
            detail="Wrong password"
        )

    token = create_access_token(
        {
            "sub": form_data.username
        }
    )

    return {
        "access_token": token,
        "token_type": "bearer"
    }
class GoogleLogin(BaseModel):
    email: str
    name: str

@app.post("/google-login")
def google_login(data: GoogleLogin):
    cursor.execute(
        "SELECT id, name, email FROM users WHERE email=%s",
        (data.email,)
    )
    user = cursor.fetchone()

    if not user:
        cursor.execute(
            "INSERT INTO users (name, email, password) VALUES (%s, %s, %s)",
            (data.name, data.email, "google_account")
        )
        db.commit()

        cursor.execute(
            "SELECT id, name, email FROM users WHERE email=%s",
            (data.email,)
        )
        user = cursor.fetchone()

    token = create_access_token({"sub": user[2]})

    return {
        "access_token": token,
        "token_type": "bearer",
        "name": user[1]
    }


# ============================================================
# WEATHER
# ============================================================

@app.get("/weather")
def get_weather(
    lat: float,
    lon: float,
    payload=Depends(get_current_user)
):

    api_key = os.getenv(
        "OPENWEATHER_API_KEY"
    )

    if not api_key:
        raise HTTPException(
            status_code=500,
            detail="OpenWeather API key not configured"
        )

    response = requests.get(
        "https://api.openweathermap.org/data/2.5/weather",
        params={
            "lat": lat,
            "lon": lon,
            "appid": api_key,
            "units": "metric"
        },
        timeout=10
    )

    if response.status_code != 200:
        raise HTTPException(
            status_code=response.status_code,
            detail="Unable to get weather"
        )

    return response.json()


# ============================================================
# TASKS
# ============================================================

@app.post("/tasks")
def create_task(
    task: Task,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        INSERT INTO tasks
        (title, description, user_email)
        VALUES (%s, %s, %s)
        """,
        (
            task.title,
            task.description,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Task created successfully"
    }


@app.get("/tasks")
def get_tasks(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, title, description, status
        FROM tasks
        WHERE user_email=%s
        ORDER BY id DESC
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "tasks": [
            {
                "id": row[0],
                "title": row[1],
                "description": row[2],
                "status": row[3]
            }
            for row in rows
        ]
    }


@app.put("/tasks/{task_id}")
def update_task(
    task_id: int,
    task: UpdateTask,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        UPDATE tasks
        SET title=%s,
            description=%s,
            status=%s
        WHERE id=%s
        AND user_email=%s
        """,
        (
            task.title,
            task.description,
            task.status,
            task_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    db.commit()

    return {
        "message": "Task updated successfully"
    }


@app.delete("/tasks/{task_id}")
def delete_task(
    task_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        DELETE FROM tasks
        WHERE id=%s
        AND user_email=%s
        """,
        (
            task_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    db.commit()

    return {
        "message": "Task deleted successfully"
    }


# ============================================================
# DASHBOARD
# ============================================================

@app.get("/dashboard")
def dashboard(
    payload=Depends(get_current_user)
):

    email = payload["sub"]

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM tasks
        WHERE user_email=%s
        """,
        (email,)
    )

    total = cursor.fetchone()[0]

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM tasks
        WHERE user_email=%s
        AND status='Completed'
        """,
        (email,)
    )

    completed = cursor.fetchone()[0]

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM tasks
        WHERE user_email=%s
        AND status='Pending'
        """,
        (email,)
    )

    pending = cursor.fetchone()[0]

    return {
        "total_tasks": total,
        "completed_tasks": completed,
        "pending_tasks": pending
    }


# ============================================================
# NOTES
# ============================================================

@app.post("/notes")
def create_note(
    note: Note,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        INSERT INTO notes
        (title, content, user_email)
        VALUES (%s, %s, %s)
        """,
        (
            note.title,
            note.content,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Note created successfully"
    }


@app.get("/notes")
def get_notes(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, title, content
        FROM notes
        WHERE user_email=%s
        ORDER BY id DESC
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "notes": [
            {
                "id": row[0],
                "title": row[1],
                "content": row[2]
            }
            for row in rows
        ]
    }


@app.put("/notes/{note_id}")
def update_note(
    note_id: int,
    note: UpdateNote,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        UPDATE notes
        SET title=%s,
            content=%s
        WHERE id=%s
        AND user_email=%s
        """,
        (
            note.title,
            note.content,
            note_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Note not found"
        )

    db.commit()

    return {
        "message": "Note updated successfully"
    }


@app.delete("/notes/{note_id}")
def delete_note(
    note_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        DELETE FROM notes
        WHERE id=%s
        AND user_email=%s
        """,
        (
            note_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Note not found"
        )

    db.commit()

    return {
        "message": "Note deleted successfully"
    }


# ============================================================
# REMINDERS
# ============================================================

@app.post("/reminders")
def create_reminder(
    reminder: Reminder,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        INSERT INTO reminders
        (title, reminder_time, user_email)
        VALUES (%s, %s, %s)
        """,
        (
            reminder.title,
            reminder.reminder_time,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Reminder created successfully"
    }


@app.get("/reminders")
def get_reminders(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, title, reminder_time
        FROM reminders
        WHERE user_email=%s
        ORDER BY reminder_time
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "reminders": [
            {
                "id": row[0],
                "title": row[1],
                "reminder_time": str(row[2])
            }
            for row in rows
        ]
    }


@app.delete("/reminders/{reminder_id}")
def delete_reminder(
    reminder_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        DELETE FROM reminders
        WHERE id=%s
        AND user_email=%s
        """,
        (
            reminder_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Reminder not found"
        )

    db.commit()

    return {
        "message": "Reminder deleted successfully"
    }


# ============================================================
# EXPENSES
# ============================================================

@app.post("/expenses")
def create_expense(
    expense: Expense,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        INSERT INTO expenses
        (title, amount, category, expense_date, user_email)
        VALUES (%s, %s, %s, %s, %s)
        """,
        (
            expense.title,
            expense.amount,
            expense.category,
            expense.expense_date,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Expense added successfully"
    }


@app.get("/expenses")
def get_expenses(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, title, amount, category, expense_date
        FROM expenses
        WHERE user_email=%s
        ORDER BY expense_date DESC
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "expenses": [
            {
                "id": row[0],
                "title": row[1],
                "amount": float(row[2]),
                "category": row[3],
                "expense_date": str(row[4])
            }
            for row in rows
        ]
    }


@app.put("/expenses/{expense_id}")
def update_expense(
    expense_id: int,
    expense: Expense,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        UPDATE expenses
        SET title=%s,
            amount=%s,
            category=%s,
            expense_date=%s
        WHERE id=%s
        AND user_email=%s
        """,
        (
            expense.title,
            expense.amount,
            expense.category,
            expense.expense_date,
            expense_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Expense not found"
        )

    db.commit()

    return {
        "message": "Expense updated successfully"
    }


@app.delete("/expenses/{expense_id}")
def delete_expense(
    expense_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        DELETE FROM expenses
        WHERE id=%s
        AND user_email=%s
        """,
        (
            expense_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Expense not found"
        )

    db.commit()

    return {
        "message": "Expense deleted successfully"
    }


# ============================================================
# GOALS
# ============================================================

@app.post("/goals")
def create_goal(
    goal: Goal,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        INSERT INTO goals
        (title, target_date, user_email)
        VALUES (%s, %s, %s)
        """,
        (
            goal.title,
            goal.target_date,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Goal created successfully"
    }


@app.get("/goals")
def get_goals(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, title, target_date, status
        FROM goals
        WHERE user_email=%s
        ORDER BY target_date
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "goals": [
            {
                "id": row[0],
                "title": row[1],
                "target_date": str(row[2]),
                "status": row[3]
            }
            for row in rows
        ]
    }


@app.put("/goals/{goal_id}/complete")
def complete_goal(
    goal_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        UPDATE goals
        SET status='Completed'
        WHERE id=%s
        AND user_email=%s
        """,
        (
            goal_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Goal not found"
        )

    db.commit()

    return {
        "message": "Goal completed successfully"
    }


@app.delete("/goals/{goal_id}")
def delete_goal(
    goal_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        DELETE FROM goals
        WHERE id=%s
        AND user_email=%s
        """,
        (
            goal_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Goal not found"
        )

    db.commit()

    return {
        "message": "Goal deleted successfully"
    }


# ============================================================
# HABITS
# ============================================================

@app.post("/habits")
def create_habit(
    habit: Habit,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        INSERT INTO habits
        (title, user_email)
        VALUES (%s, %s)
        """,
        (
            habit.title,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Habit created successfully"
    }


@app.get("/habits")
def get_habits(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, title, streak, completed_today
        FROM habits
        WHERE user_email=%s
        ORDER BY id DESC
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "habits": [
            {
                "id": row[0],
                "title": row[1],
                "streak": row[2],
                "completed_today": bool(row[3])
            }
            for row in rows
        ]
    }


@app.put("/habits/{habit_id}/complete")
def complete_habit(
    habit_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        UPDATE habits
        SET completed_today=TRUE,
            streak=streak+1
        WHERE id=%s
        AND user_email=%s
        """,
        (
            habit_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Habit not found"
        )

    db.commit()

    return {
        "message": "Habit marked as completed"
    }


@app.put("/habits/{habit_id}/reset")
def reset_habit(
    habit_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        UPDATE habits
        SET completed_today=FALSE
        WHERE id=%s
        AND user_email=%s
        """,
        (
            habit_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Habit not found"
        )

    db.commit()

    return {
        "message": "Habit reset successfully"
    }


@app.delete("/habits/{habit_id}")
def delete_habit(
    habit_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        DELETE FROM habits
        WHERE id=%s
        AND user_email=%s
        """,
        (
            habit_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Habit not found"
        )

    db.commit()

    return {
        "message": "Habit deleted successfully"
    }


# ============================================================
# EVENTS
# ============================================================

@app.post("/events")
def create_event(
    event: Event,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        INSERT INTO events
        (title, description, event_date, event_time, user_email)
        VALUES (%s, %s, %s, %s, %s)
        """,
        (
            event.title,
            event.description,
            event.event_date,
            event.event_time,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Event created successfully"
    }


@app.get("/events")
def get_events(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, title, description, event_date, event_time
        FROM events
        WHERE user_email=%s
        ORDER BY event_date, event_time
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "events": [
            {
                "id": row[0],
                "title": row[1],
                "description": row[2],
                "event_date": str(row[3]),
                "event_time": str(row[4])
            }
            for row in rows
        ]
    }


@app.delete("/events/{event_id}")
def delete_event(
    event_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        DELETE FROM events
        WHERE id=%s
        AND user_email=%s
        """,
        (
            event_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Event not found"
        )

    db.commit()

    return {
        "message": "Event deleted successfully"
    }


# ============================================================
# FILE UPLOAD
# ============================================================

@app.post("/upload")
def upload_file(
    file: UploadFile = File(...),
    payload=Depends(get_current_user)
):

    os.makedirs(
        "uploads",
        exist_ok=True
    )

    file_path = os.path.join(
        "uploads",
        file.filename
    )

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(
            file.file,
            buffer
        )

    pdf_text = ""

    if file.filename.lower().endswith(".pdf"):
        pdf_text = extract_pdf_text(
            file_path
        )

    cursor.execute(
        """
        INSERT INTO files
        (filename, filepath, user_email, pdf_text)
        VALUES (%s, %s, %s, %s)
        """,
        (
            file.filename,
            file_path,
            payload["sub"],
            pdf_text
        )
    )

    db.commit()

    return {
        "message": "File uploaded successfully",
        "filename": file.filename
    }


@app.get("/files")
def get_files(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, filename, filepath, uploaded_at
        FROM files
        WHERE user_email=%s
        ORDER BY uploaded_at DESC
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "files": [
            {
                "id": row[0],
                "filename": row[1],
                "filepath": row[2],
                "uploaded_at": str(row[3])
            }
            for row in rows
        ]
    }


@app.get("/files/{file_id}/view")
def view_file(
    file_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT filepath, filename
        FROM files
        WHERE id=%s
        AND user_email=%s
        """,
        (
            file_id,
            payload["sub"]
        )
    )

    result = cursor.fetchone()

    if result is None:
        raise HTTPException(
            status_code=404,
            detail="File not found"
        )

    file_path = result[0]
    filename = result[1]

    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=404,
            detail="File does not exist"
        )

    return FileResponse(
        path=file_path,
        filename=filename
    )


# ============================================================
# DOCUMENTS
# ============================================================

@app.post("/documents")
def upload_document(
    file: UploadFile = File(...),
    payload=Depends(get_current_user)
):

    os.makedirs(
        "uploads",
        exist_ok=True
    )

    file_path = os.path.join(
        "uploads",
        file.filename
    )

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(
            file.file,
            buffer
        )

    pdf_text = ""

    if file.filename.lower().endswith(".pdf"):
        pdf_text = extract_pdf_text(
            file_path
        )

    cursor.execute(
        """
        INSERT INTO documents
        (file_name, file_path, user_email, pdf_text)
        VALUES (%s, %s, %s, %s)
        """,
        (
            file.filename,
            file_path,
            payload["sub"],
            pdf_text
        )
    )

    db.commit()

    return {
        "message": "File uploaded successfully",
        "file": file.filename
    }


@app.get("/documents")
def get_documents(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, file_name, file_path, uploaded_at
        FROM documents
        WHERE user_email=%s
        ORDER BY uploaded_at DESC
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "documents": [
            {
                "id": row[0],
                "file_name": row[1],
                "file_path": row[2],
                "uploaded_at": str(row[3])
            }
            for row in rows
        ]
    }


@app.get("/documents/{doc_id}/download")
def download_document(
    doc_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT file_name, file_path
        FROM documents
        WHERE id=%s
        AND user_email=%s
        """,
        (
            doc_id,
            payload["sub"]
        )
    )

    result = cursor.fetchone()

    if result is None:
        raise HTTPException(
            status_code=404,
            detail="Document not found"
        )

    file_name = result[0]
    file_path = result[1]

    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=404,
            detail="File not found on server"
        )

    return FileResponse(
        path=file_path,
        filename=file_name,
        media_type="application/octet-stream"
    )


@app.delete("/documents/{doc_id}")
def delete_document(
    doc_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT file_path
        FROM documents
        WHERE id=%s
        AND user_email=%s
        """,
        (
            doc_id,
            payload["sub"]
        )
    )

    result = cursor.fetchone()

    if result is None:
        raise HTTPException(
            status_code=404,
            detail="Document not found"
        )

    file_path = result[0]

    if os.path.exists(file_path):
        os.remove(file_path)

    cursor.execute(
        """
        DELETE FROM documents
        WHERE id=%s
        AND user_email=%s
        """,
        (
            doc_id,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Document deleted successfully"
    }


# ============================================================
# AI MEMORY
# ============================================================

def save_memory(
    user_email,
    key,
    value
):

    cursor.execute(
        """
        INSERT INTO ai_memory
        (user_email, memory_key, memory_value)
        VALUES (%s, %s, %s)
        ON CONFLICT
        (user_email, memory_key)
        DO UPDATE SET
        memory_value = EXCLUDED.memory_value
        """,
        (
            user_email,
            key,
            value
        )
    )

    db.commit()


def get_memory(user_email):

    cursor.execute(
        """
        SELECT memory_key, memory_value
        FROM ai_memory
        WHERE user_email=%s
        """,
        (user_email,)
    )

    rows = cursor.fetchall()

    memory = {}

    for row in rows:
        memory[row[0]] = row[1]

    return memory


def get_latest_pdf(user_email):

    cursor.execute(
        """
        SELECT pdf_text
        FROM documents
        WHERE user_email=%s
        AND pdf_text IS NOT NULL
        AND pdf_text != ''
        ORDER BY uploaded_at DESC
        LIMIT 1
        """,
        (user_email,)
    )

    result = cursor.fetchone()

    if result and result[0]:
        return result[0]

    return ""


# ============================================================
# AI ASSISTANT
# ============================================================

@app.post("/ai")
async def ai_chat(data: dict):
    try:
        response = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}",
                "Content-Type": "application/json",
            },
            json={
                "model": "openrouter/auto",
                "messages": [
                    {
                        "role": "system",
                        "content": "You are LifeOS AI, a smart and friendly assistant. Answer any question clearly.",
                    },
                    {
                        "role": "user",
                        "content": data["message"],
                    },
                ],
            },
            timeout=60,
        )

        result = response.json()
        return {"reply": result["choices"][0]["message"]["content"]}

    except Exception as e:
        return {"reply": f"Error: {str(e)}"}


# ============================================================
# CHAT
# ============================================================

@app.post("/chat")
def chat(
    data: ChatRequest,
    payload=Depends(get_current_user)
):

    email = payload["sub"]

    try:

        response = client.chat.completions.create(
            model="openai/gpt-oss-20b:free",
            messages=[
                {
                    "role": "user",
                    "content": data.message
                }
            ]
        )

        reply = response.choices[0].message.content

        return {
            "ai_response": reply
        }

    except Exception as e:

        print(
            "Chat Error:",
            e
        )

        raise HTTPException(
            status_code=500,
            detail="AI is temporarily unavailable"
        )


# ============================================================
# CHAT HISTORY
# ============================================================

@app.get("/chat")
def get_chat_history(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, role, message, created_at
        FROM ai_chat_history
        WHERE user_email=%s
        ORDER BY created_at ASC
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "chat_history": [
            {
                "id": row[0],
                "role": row[1],
                "message": row[2],
                "created_at": str(row[3])
            }
            for row in rows
        ]
    }


# ============================================================
# ANALYTICS
# ============================================================

@app.get("/analytics")
def analytics(
    payload=Depends(get_current_user)
):

    email = payload["sub"]

    # Tasks
    cursor.execute(
        """
        SELECT COUNT(*)
        FROM tasks
        WHERE user_email=%s
        """,
        (email,)
    )

    total_tasks = cursor.fetchone()[0]

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM tasks
        WHERE user_email=%s
        AND status='Completed'
        """,
        (email,)
    )

    completed_tasks = cursor.fetchone()[0]

    # Goals
    cursor.execute(
        """
        SELECT COUNT(*)
        FROM goals
        WHERE user_email=%s
        """,
        (email,)
    )

    total_goals = cursor.fetchone()[0]

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM goals
        WHERE user_email=%s
        AND status='Completed'
        """,
        (email,)
    )

    completed_goals = cursor.fetchone()[0]

    # Expenses
    cursor.execute(
        """
        SELECT COALESCE(SUM(amount), 0)
        FROM expenses
        WHERE user_email=%s
        """,
        (email,)
    )

    total_expense = float(
        cursor.fetchone()[0]
    )

    return {
        "total_tasks": total_tasks,
        "completed_tasks": completed_tasks,
        "pending_tasks": total_tasks - completed_tasks,
        "total_goals": total_goals,
        "completed_goals": completed_goals,
        "total_expense": total_expense
    }


# ============================================================
# SEARCH
# ============================================================

@app.get("/search")
def search(
    query: str,
    payload=Depends(get_current_user)
):

    email = payload["sub"]

    results = []

    # Tasks
    cursor.execute(
        """
        SELECT title
        FROM tasks
        WHERE user_email=%s
        AND title ILIKE %s
        """,
        (
            email,
            f"%{query}%"
        )
    )

    for row in cursor.fetchall():

        results.append(
            {
                "type": "Task",
                "title": row[0]
            }
        )

    # Notes
    cursor.execute(
        """
        SELECT title
        FROM notes
        WHERE user_email=%s
        AND title ILIKE %s
        """,
        (
            email,
            f"%{query}%"
        )
    )

    for row in cursor.fetchall():

        results.append(
            {
                "type": "Note",
                "title": row[0]
            }
        )

    # Goals
    cursor.execute(
        """
        SELECT title
        FROM goals
        WHERE user_email=%s
        AND title ILIKE %s
        """,
        (
            email,
            f"%{query}%"
        )
    )

    for row in cursor.fetchall():

        results.append(
            {
                "type": "Goal",
                "title": row[0]
            }
        )

    return results


# ============================================================
# PROFILE
# ============================================================

@app.get("/profile")
def get_profile(
    payload=Depends(get_current_user)
):

    email = payload["sub"]

    cursor.execute(
        """
        SELECT name, email
        FROM users
        WHERE email=%s
        """,
        (email,)
    )

    user = cursor.fetchone()

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    return {
        "name": user[0],
        "email": user[1]
    }


# ============================================================
# UPDATE PROFILE
# ============================================================

@app.put("/settings/profile")
def update_profile(
    data: UpdateProfile,
    payload=Depends(get_current_user)
):

    current_email = payload["sub"]

    cursor.execute(
        """
        UPDATE users
        SET name=%s,
            email=%s
        WHERE email=%s
        """,
        (
            data.name,
            data.email,
            current_email
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    db.commit()

    return {
        "message": "Profile updated successfully"
    }


# ============================================================
# GET SETTINGS PROFILE
# ============================================================

@app.get("/settings/profile")
def get_settings_profile(
    payload=Depends(get_current_user)
):

    email = payload["sub"]

    cursor.execute(
        """
        SELECT name, email
        FROM users
        WHERE email=%s
        """,
        (email,)
    )

    user = cursor.fetchone()

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    return {
        "name": user[0],
        "email": user[1]
    }


# ============================================================
# CHANGE PASSWORD
# ============================================================

@app.put("/settings/password")
def change_password(
    data: ChangePassword,
    payload=Depends(get_current_user)
):

    email = payload["sub"]

    cursor.execute(
        """
        SELECT password
        FROM users
        WHERE email=%s
        """,
        (email,)
    )

    user = cursor.fetchone()

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    if not verify_password(
        data.old_password,
        user[0]
    ):
        raise HTTPException(
            status_code=400,
            detail="Old password is incorrect"
        )

    new_hash = hash_password(
        data.new_password
    )

    cursor.execute(
        """
        UPDATE users
        SET password=%s
        WHERE email=%s
        """,
        (
            new_hash,
            email
        )
    )

    db.commit()

    return {
        "message": "Password changed successfully"
    }


# ============================================================
# NOTIFICATIONS
# ============================================================

@app.post("/notifications")
def create_notification(
    notification: Notification,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        INSERT INTO notifications
        (title, message, user_email)
        VALUES (%s, %s, %s)
        """,
        (
            notification.title,
            notification.message,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Notification created successfully"
    }


@app.get("/notifications")
def get_notifications(
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        SELECT id, title, message, is_read, created_at
        FROM notifications
        WHERE user_email=%s
        ORDER BY created_at DESC
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    return {
        "notifications": [
            {
                "id": row[0],
                "title": row[1],
                "message": row[2],
                "is_read": bool(row[3]),
                "created_at": str(row[4])
            }
            for row in rows
        ]
    }


@app.delete("/notifications/{notification_id}")
def delete_notification(
    notification_id: int,
    payload=Depends(get_current_user)
):

    cursor.execute(
        """
        DELETE FROM notifications
        WHERE id=%s
        AND user_email=%s
        """,
        (
            notification_id,
            payload["sub"]
        )
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=404,
            detail="Notification not found"
        )

    db.commit()

    return {
        "message": "Notification deleted successfully"
    }