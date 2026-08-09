from fastapi.responses import FileResponse
from PyPDF2 import PdfReader
import os
import requests

from openai import OpenAI
from dotenv import load_dotenv

from fastapi.middleware.cors import CORSMiddleware
from fastapi import UploadFile, File
from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm

from pydantic import BaseModel, EmailStr
import mysql.connector

from security import hash_password, verify_password
from auth import create_access_token, verify_token


def extract_pdf_text(file_path):
    reader = PdfReader(file_path)
    text = ""

    for page in reader.pages:
        page_text = page.extract_text()

        if page_text:
            text += page_text + "\n"

    return text


load_dotenv()


client = OpenAI(
    api_key=os.getenv("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1"
)


app = FastAPI()


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")


@app.get("/weather")
def get_weather(
    lat: float,
    lon: float,
    token: str = Depends(oauth2_scheme)
):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid token"
        )

    api_key = os.getenv("OPENWEATHER_API_KEY")

    response = requests.get(
        "https://api.openweathermap.org/data/2.5/weather",
        params={
            "lat": lat,
            "lon": lon,
            "appid": api_key,
            "units": "metric",
        },
    )

    if response.status_code != 200:
        raise HTTPException(
            status_code=response.status_code,
            detail="Unable to get weather"
        )

    return response.json()


db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Root@123",
    database="lifeos_ai"
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Root@123",
    database="lifeos_ai"
)

cursor = db.cursor(buffered=True)

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
    email: str


class ChangePassword(BaseModel):
    old_password: str
    new_password: str

@app.get("/")
def home():
    return {"message": "Welcome to LifeOS AI"}

@app.post("/register")
def register(user: User):

    cursor.execute(
        "SELECT * FROM users WHERE email=%s",
        (user.email,)
    )

    existing_user = cursor.fetchone()

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    hashed_password = hash_password(user.password)

    cursor.execute(
        "INSERT INTO users (name, email, password) VALUES (%s, %s, %s)",
        (user.name, user.email, hashed_password)
    )

    db.commit()

    return {
        "message": "User registered successfully"
    }

@app.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends()):

    cursor.execute(
        "SELECT password FROM users WHERE email=%s",
        (form_data.username,)
    )

    result = cursor.fetchone()

    if result is None:
        raise HTTPException(status_code=401, detail="User not found")

    if not verify_password(form_data.password, result[0]):
        raise HTTPException(status_code=401, detail="Wrong password")

    token = create_access_token({"sub": form_data.username})

    return {
        "access_token": token,
        "token_type": "bearer"
    }

@app.post("/tasks")
def create_task(task: Task, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "INSERT INTO tasks (title, description, user_email) VALUES (%s, %s, %s)",
        (task.title, task.description, payload["sub"])
    )

    db.commit()

    return {"message": "Task created successfully"}

@app.get("/tasks")
def get_tasks(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute("""
        SELECT id, title, description, status
        FROM tasks
        WHERE user_email=%s
        ORDER BY id DESC
    """, (payload["sub"],))

    tasks = cursor.fetchall()

    return {
        "tasks": [
            {
                "id": row[0],
                "title": row[1],
                "description": row[2],
                "status": row[3]
            }
            for row in tasks
        ]
    }

    return {"tasks": tasks}
@app.delete("/tasks/{task_id}")
def delete_task(task_id: int, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        DELETE FROM tasks
        WHERE id=%s AND user_email=%s
        """,
        (task_id, payload["sub"])
    )

    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="Task not found")

    db.commit()

    return {"message": "Task deleted successfully"}

@app.put("/tasks/{task_id}")
def update_task(task_id: int, task: UpdateTask, token: str = Depends(oauth2_scheme)):
    ...
    return {"message": "Task updated successfully"}


# ADD THE DASHBOARD CODE BELOW THIS LINE
@app.get("/dashboard")
def dashboard(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "SELECT COUNT(*) FROM tasks WHERE user_email=%s",
        (payload["sub"],)
    )
    total = cursor.fetchone()[0]

    cursor.execute(
        "SELECT COUNT(*) FROM tasks WHERE user_email=%s AND status='Completed'",
        (payload["sub"],)
    )
    completed = cursor.fetchone()[0]

    cursor.execute(
        "SELECT COUNT(*) FROM tasks WHERE user_email=%s AND status='Pending'",
        (payload["sub"],)
    )
    pending = cursor.fetchone()[0]

    return {
        "total_tasks": total,
        "completed_tasks": completed,
        "pending_tasks": pending
    }

@app.post("/notes")
def create_note(note: Note, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "INSERT INTO notes (title, content, user_email) VALUES (%s, %s, %s)",
        (note.title, note.content, payload["sub"])
    )

    db.commit()

    return {"message": "Note created successfully"}

@app.get("/notes")
def get_notes(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "SELECT id, title, content FROM notes WHERE user_email=%s",
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    notes = []
    for row in rows:
        notes.append({
            "id": row[0],
            "title": row[1],
            "content": row[2]
        })

    return {"notes": notes}

@app.delete("/notes/{note_id}")
def delete_note(note_id: int, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "DELETE FROM notes WHERE id=%s AND user_email=%s",
        (note_id, payload["sub"])
    )

    db.commit()

    return {
        "message": "Note deleted successfully"
    }

@app.put("/notes/{note_id}")
def update_note(
    note_id: int,
    note: UpdateNote,
    token: str = Depends(oauth2_scheme)
):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        UPDATE notes
        SET title=%s, content=%s
        WHERE id=%s AND user_email=%s
        """,
        (
            note.title,
            note.content,
            note_id,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Note updated successfully"
    }

@app.post("/reminders")
def create_reminder(reminder: Reminder, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "INSERT INTO reminders (title, reminder_time, user_email) VALUES (%s, %s, %s)",
        (reminder.title, reminder.reminder_time, payload["sub"])
    )

    db.commit()

    return {"message": "Reminder created successfully"}

@app.get("/reminders")
def get_reminders(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "SELECT id, title, reminder_time FROM reminders WHERE user_email=%s",
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    reminders = []
    for row in rows:
        reminders.append({
            "id": row[0],
            "title": row[1],
            "reminder_time": str(row[2])
        })

    return {"reminders": reminders}
@app.delete("/reminders/{reminder_id}")
def delete_reminder(
    reminder_id: int,
    token: str = Depends(oauth2_scheme)
):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        DELETE FROM reminders
        WHERE id=%s AND user_email=%s
        """,
        (reminder_id, payload["sub"])
    )

    db.commit()

    return {
        "message": "Reminder deleted successfully"
    }

@app.post("/expenses")
def create_expense(expense: Expense, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

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

    return {"message": "Expense added successfully"}

@app.get("/expenses")
def get_expenses(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        SELECT id, title, amount, category, expense_date
        FROM expenses
        WHERE user_email=%s
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    expenses = []

    for row in rows:
        expenses.append({
            "id": row[0],
            "title": row[1],
            "amount": float(row[2]),
            "category": row[3],
            "expense_date": str(row[4])
        })

    return {"expenses": expenses}
@app.put("/expenses/{expense_id}")
def update_expense(
    expense_id: int,
    expense: Expense,
    token: str = Depends(oauth2_scheme)
    ):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        UPDATE expenses
        SET title=%s,
            amount=%s,
            category=%s,
            expense_date=%s
        WHERE id=%s AND user_email=%s
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

    db.commit()

    return {
        "message": "Expense updated successfully"
    }
@app.delete("/expenses/{expense_id}")
def delete_expense(
    expense_id: int,
    token: str = Depends(oauth2_scheme)
    ):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        DELETE FROM expenses
        WHERE id=%s AND user_email=%s
        """,
        (
            expense_id,
            payload["sub"]
        )
    )

    db.commit()

    return {
        "message": "Expense deleted successfully"
    }

@app.post("/chat")
def chat(chat: ChatMessage, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    try:
        response = model.generate_content(chat.message)

        ai_response = response.text

        cursor.execute(
            """
            INSERT INTO chat_history
            (user_message, ai_response, user_email)
            VALUES (%s, %s, %s)
            """,
            (
                chat.message,
                ai_response,
                payload["sub"]
            )
        )

        db.commit()

        return {
            "user_message": chat.message,
            "ai_response": ai_response
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
@app.get("/chat")
def get_chat_history(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        SELECT id, user_message, ai_response, created_at
        FROM chat_history
        WHERE user_email=%s
        ORDER BY created_at DESC
        """,
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    history = []

    for row in rows:
        history.append({
            "id": row[0],
            "user_message": row[1],
            "ai_response": row[2],
            "created_at": str(row[3])
        })

    return {"chat_history": history}

@app.post("/goals")
def create_goal(goal: Goal, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "INSERT INTO goals(title, target_date, user_email) VALUES (%s,%s,%s)",
        (goal.title, goal.target_date, payload["sub"])
    )

    db.commit()

    return {"message": "Goal created successfully"}

@app.get("/goals")
def get_goals(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "SELECT id, title, target_date, status FROM goals WHERE user_email=%s",
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    goals = []

    for row in rows:
        goals.append({
            "id": row[0],
            "title": row[1],
            "target_date": str(row[2]),
            "status": row[3]
        })

    return {"goals": goals}
@app.put("/goals/{goal_id}/complete")
def complete_goal(goal_id: int, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        UPDATE goals
        SET status='Completed'
        WHERE id=%s AND user_email=%s
        """,
        (goal_id, payload["sub"])
    )

    db.commit()

    return {"message": "Goal completed successfully"}
@app.delete("/goals/{goal_id}")
def delete_goal(goal_id: int, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "DELETE FROM goals WHERE id=%s AND user_email=%s",
        (goal_id, payload["sub"])
    )

    db.commit()

    return {"message": "Goal deleted successfully"}

@app.post("/habits")
def create_habit(habit: Habit, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "INSERT INTO habits(title, user_email) VALUES (%s, %s)",
        (habit.title, payload["sub"])
    )

    db.commit()

    return {"message": "Habit created successfully"}

@app.get("/habits")
def get_habits(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "SELECT id, title, streak, completed_today FROM habits WHERE user_email=%s",
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    habits = []

    for row in rows:
        habits.append({
            "id": row[0],
            "title": row[1],
            "streak": row[2],
            "completed_today": bool(row[3])
        })

    return {"habits": habits}

@app.put("/habits/{habit_id}/complete")
def complete_habit(habit_id: int, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        UPDATE habits
        SET completed_today=TRUE,
            streak=streak+1
        WHERE id=%s AND user_email=%s
        """,
        (habit_id, payload["sub"])
    )

    db.commit()

    return {"message": "Habit marked as completed"}
@app.delete("/habits/{habit_id}")
def delete_habit(habit_id: int, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "DELETE FROM habits WHERE id=%s AND user_email=%s",
        (habit_id, payload["sub"])
    )

    db.commit()

    return {
        "message": "Habit deleted successfully"
    }
@app.put("/habits/{habit_id}/reset")
def reset_habit(habit_id: int, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        UPDATE habits
        SET completed_today=FALSE
        WHERE id=%s AND user_email=%s
        """,
        (habit_id, payload["sub"])
    )

    db.commit()

    return {
        "message": "Habit reset successfully"
    }

@app.post("/events")
def create_event(event: Event, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

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

    return {"message": "Event created successfully"}

@app.get("/events")
def get_events(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

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

    events = []

    for row in rows:
        events.append({
            "id": row[0],
            "title": row[1],
            "description": row[2],
            "event_date": str(row[3]),
            "event_time": str(row[4])
        })

    return {"events": events}
@app.delete("/events/{event_id}")
def delete_event(
    event_id: int,
    token: str = Depends(oauth2_scheme)
):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        DELETE FROM events
        WHERE id=%s AND user_email=%s
        """,
        (event_id, payload["sub"])
    )

    db.commit()

    return {
        "message": "Event deleted successfully"
    }

@app.post("/upload")
def upload_file(
    file: UploadFile = File(...),
    token: str = Depends(oauth2_scheme)
):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    os.makedirs("uploads", exist_ok=True)

    file_path = f"uploads/{file.filename}"

    with open(file_path, "wb") as f:
        f.write(file.file.read())

    # Extract PDF text
    pdf_text = ""

    if file.filename.lower().endswith(".pdf"):
        pdf_text = extract_pdf_text(file_path)

    cursor.execute(
        """
        INSERT INTO files(filename, filepath, user_email, pdf_text)
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


def get_latest_pdf(user_email):
    cursor.execute(
        """
        SELECT pdf_text
        FROM documents
        WHERE user_email=%s
        ORDER BY uploaded_at DESC
        LIMIT 1
        """,
        (user_email,)
    )

    result = cursor.fetchone()

    if result and result[0]:
        return result[0]

    return ""

@app.get("/files")
def get_files(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "SELECT id, filename, filepath, uploaded_at FROM files WHERE user_email=%s",
        (payload["sub"],)
    )

    rows = cursor.fetchall()

    files = []

    for row in rows:
        files.append({
            "id": row[0],
            "filename": row[1],
            "filepath": row[2],
            "uploaded_at": str(row[3])
        })

    return {"files": files}
@app.get("/files/{file_id}/view")
def view_file(
    file_id: int,
    token: str = Depends(oauth2_scheme)
):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        SELECT filepath, filename
        FROM files
        WHERE id=%s AND user_email=%s
        """,
        (file_id, payload["sub"])
    )

    result = cursor.fetchone()

    if result is None:
        raise HTTPException(status_code=404, detail="File not found")

    file_path = result[0]
    filename = result[1]

    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File does not exist")

    return FileResponse(
        path=file_path,
        filename=filename
    )

@app.post("/notifications")
def create_notification(
    notification: Notification,
    token: str = Depends(oauth2_scheme)
):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        INSERT INTO notifications(title, message, user_email)
        VALUES (%s, %s, %s)
        """,
        (
            notification.title,
            notification.message,
            payload["sub"]
        )
    )

    db.commit()

    return {"message": "Notification created successfully"}

@app.get("/notifications")
def get_notifications(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

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

    notifications = []

    for row in rows:
        notifications.append({
            "id": row[0],
            "title": row[1],
            "message": row[2],
            "is_read": bool(row[3]),
            "created_at": str(row[4])
        })

    return {"notifications": notifications}

@app.delete("/notifications/{notification_id}")
def delete_notification(
    notification_id: int,
    token: str = Depends(oauth2_scheme)
):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        "DELETE FROM notifications WHERE id=%s AND user_email=%s",
        (notification_id, payload["sub"])
    )

    db.commit()

    return {
        "message": "Notification deleted successfully"
    }
def save_memory(user_email, key, value):
    cursor.execute(
        """
        INSERT INTO ai_memory(user_email, memory_key, memory_value)
        VALUES(%s, %s, %s)
        ON DUPLICATE KEY UPDATE memory_value=%s
        """,
        (user_email, key, value, value)
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
@app.post("/ai")
def ai_assistant(chat: ChatMessage, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    text = chat.message.lower()
    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    pdf_text = get_latest_pdf(payload["sub"])
    memory = get_memory(payload["sub"])

    cursor.execute("""
        SELECT role, message
        FROM ai_chat_history
        WHERE user_email=%s
        ORDER BY created_at ASC
        LIMIT 10
    """, (payload["sub"],))

    history = cursor.fetchall()

    messages = [
    {
        "role": "system",
        "content": f"""
You are LifeOS AI.

User Memory:
{memory}

PDF Context:
{pdf_text}

Use the memory whenever the user asks about themselves.
If the information is not in memory, politely say you don't know.
"""
    }
]

    # Previous chat history
    for row in history:
        messages.append({
            "role": row[0],
            "content": row[1]
        })

    # Current user message
    messages.append({
        "role": "user",
        "content": chat.message
    })

    try:
        response = client.chat.completions.create(
            model="openai/gpt-oss-20b:free",
            messages=messages
        )

        reply = response.choices[0].message.content

        # Save user message
        cursor.execute("""
            INSERT INTO ai_chat_history(user_email, role, message)
            VALUES(%s, %s, %s)
        """, (payload["sub"], "user", chat.message))

        # Save AI reply
        cursor.execute("""
            INSERT INTO ai_chat_history(user_email, role, message)
            VALUES(%s, %s, %s)
        """, (payload["sub"], "assistant", reply))

        db.commit()

    except Exception as e:
        print("OpenRouter Error:", e)
        reply = "Sorry, AI is temporarily unavailable."

    if "my name is" in text:
        name = text.split("my name is", 1)[1].strip()
        save_memory(
            payload["sub"],
            "name",
            name
        )

    if "my favorite language is" in text:
        language = text.split("my favorite language is", 1)[1].strip()
        save_memory(
            payload["sub"],
            "favorite_language",
            language
        )

    return {"reply": reply}
@app.get("/analytics")
def analytics(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    email = payload["sub"]

    # Tasks
    cursor.execute(
        "SELECT COUNT(*) FROM tasks WHERE user_email=%s",
        (email,)
    )
    total_tasks = cursor.fetchone()[0]

    cursor.execute(
        "SELECT COUNT(*) FROM tasks WHERE user_email=%s AND status='Completed'",
        (email,)
    )
    completed_tasks = cursor.fetchone()[0]

    # Goals
    cursor.execute(
        "SELECT COUNT(*) FROM goals WHERE user_email=%s",
        (email,)
    )
    total_goals = cursor.fetchone()[0]

    cursor.execute(
        "SELECT COUNT(*) FROM goals WHERE user_email=%s AND status='Completed'",
        (email,)
    )
    completed_goals = cursor.fetchone()[0]

    # Expenses
    cursor.execute(
        "SELECT IFNULL(SUM(amount),0) FROM expenses WHERE user_email=%s",
        (email,)
    )
    total_expense = float(cursor.fetchone()[0])

    return {
        "total_tasks": total_tasks,
        "completed_tasks": completed_tasks,
        "pending_tasks": total_tasks - completed_tasks,
        "total_goals": total_goals,
        "completed_goals": completed_goals,
        "total_expense": total_expense
    }
@app.get("/search")
def search(query: str, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    email = payload["sub"]
    results = []

    # Search Tasks
    cursor.execute(
        """
        SELECT title FROM tasks
        WHERE user_email=%s
        AND title LIKE %s
        """,
        (email, f"%{query}%")
    )

    for row in cursor.fetchall():
        results.append({
            "type": "Task",
            "title": row[0]
        })

    # Search Notes
    cursor.execute(
        """
        SELECT title FROM notes
        WHERE user_email=%s
        AND title LIKE %s
        """,
        (email, f"%{query}%")
    )

    for row in cursor.fetchall():
        results.append({
            "type": "Note",
            "title": row[0]
        })

    # Search Goals
    cursor.execute(
        """
        SELECT title FROM goals
        WHERE user_email=%s
        AND title LIKE %s
        """,
        (email, f"%{query}%")
    )

    for row in cursor.fetchall():
        results.append({
            "type": "Goal",
            "title": row[0]
        })

    return results
@app.get("/profile")
def get_profile(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

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
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "name": user[0],
        "email": user[1]
    }
@app.put("/settings/profile")
def update_profile(data: UpdateProfile, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    current_email = payload["sub"]

    cursor.execute(
        "UPDATE users SET name=%s, email=%s WHERE email=%s",
        (data.name, data.email, current_email)
    )

    db.commit()

    return {
        "message": "Profile updated successfully"
    }
@app.get("/settings/profile")
def get_profile(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    email = payload["sub"]

    cursor.execute(
        "SELECT name, email FROM users WHERE email=%s",
        (email,)
    )

    user = cursor.fetchone()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "name": user[0],
        "email": user[1]
    }
@app.put("/settings/password")
def change_password(data: ChangePassword, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    email = payload["sub"]

    cursor.execute(
        "SELECT password FROM users WHERE email=%s",
        (email,)
    )

    user = cursor.fetchone()

    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    if not verify_password(data.old_password, user[0]):
        raise HTTPException(status_code=400, detail="Old password is incorrect")

    new_hash = hash_password(data.new_password)

    cursor.execute(
        "UPDATE users SET password=%s WHERE email=%s",
        (new_hash, email)
    )

    db.commit()

    return {
        "message": "Password changed successfully"
    }
    from fastapi import UploadFile, File
import shutil
import os

@app.post("/documents")
def upload_document(
    file: UploadFile = File(...),
    token: str = Depends(oauth2_scheme)
):
    print("UPLOAD API CALLED")
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    email = payload["sub"]

    upload_folder = "uploads"

    if not os.path.exists(upload_folder):
        os.makedirs(upload_folder)

    file_path = os.path.join(upload_folder, file.filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    pdf_text = ""

    if file.filename.lower().endswith(".pdf"):
        pdf_text = extract_pdf_text(file_path)

    cursor.execute(
        """
        INSERT INTO documents(file_name, file_path, user_email, pdf_text)
        VALUES(%s,%s,%s,%s)
        """,
        (
            file.filename,
            file_path,
            email,
            pdf_text
        )
    )

    db.commit()

    return {
        "message": "File uploaded successfully",
        "file": file.filename
    }
@app.get("/documents")
def get_documents(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    email = payload["sub"]

    cursor.execute(
        """
        SELECT id, file_name, file_path, uploaded_at
        FROM documents
        WHERE user_email=%s
        ORDER BY uploaded_at DESC
        """,
        (email,)
    )

    docs = cursor.fetchall()

    return {
        "documents": [
            {
                "id": row[0],
                "file_name": row[1],
                "file_path": row[2],
                "uploaded_at": str(row[3])
            }
            for row in docs
        ]
    }
@app.get("/documents/{doc_id}/download")
def download_document(
    doc_id: int,
    token: str = Depends(oauth2_scheme)
):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid token"
        )

    email = payload["sub"]

    cursor.execute(
        """
        SELECT file_name, file_path
        FROM documents
        WHERE id=%s AND user_email=%s
        """,
        (doc_id, email)
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
def delete_document(doc_id: int, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    email = payload["sub"]

    cursor.execute(
        "SELECT file_path FROM documents WHERE id=%s AND user_email=%s",
        (doc_id, email)
    )

    result = cursor.fetchone()

    if result is None:
        raise HTTPException(status_code=404, detail="Document not found")

    file_path = result[0]

    if os.path.exists(file_path):
        os.remove(file_path)

    cursor.execute(
        "DELETE FROM documents WHERE id=%s AND user_email=%s",
        (doc_id, email)
    )

    db.commit()

    return {
        "message": "Document deleted successfully"
    }
class ChatRequest(BaseModel):
    message: str


@app.post("/chat")
def chat(data: ChatRequest, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    try:
        response = model.generate_content(data.message)

        return {
            "ai_response": response.text
        }

    except Exception as e:
        print("ERROR:", e)
    raise HTTPException(status_code=500, detail=str(e))
@app.post("/tasks")
def add_task(task: Task, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        INSERT INTO tasks(user_email, title, description)
        VALUES(%s, %s, %s)
        """,
        (
            payload["sub"],
            task.title,
            task.description
        )
    )

    db.commit()

    return {"message": "Task added successfully"}
@app.get("/tasks")
@app.delete("/tasks/{task_id}")
def delete_task(task_id: int, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    cursor.execute(
        """
        DELETE FROM tasks
        WHERE id=%s AND user_email=%s
        """,
        (task_id, payload["sub"])
    )

    conn.commit()

    return {"message": "Task deleted successfully"}