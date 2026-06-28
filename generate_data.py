import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
random.seed(42)
np.random.seed(42)

N_ORDERS = 20000
N_USERS = 5000
N_WORKERS = 1800

FIRST_NAMES = ["Ahmed", "Mohamed", "Mahmoud", "Ali", "Hassan", "Hussein", "Karim", "Tarek",
    "Amr", "Khaled", "Youssef", "Ibrahim", "Omar", "Mostafa", "Hany", "Emad", "Sherif",
    "Maha", "Aya", "Mona", "Laila", "Samar", "Ghada", "Mariam", "Nadia", "Sara", "Yasmin",
    "Amany", "Fatma", "Dina", "Rania", "Shaimaa", "Hend", "Noha", "Reem", "Salma"]
LAST_NAMES = ["Ali", "Hassan", "Ibrahim", "Youssef", "Ahmed", "Mohamed", "Hussein", "Khaled",
    "Omar", "Fahmy", "Shaker", "Mostafa", "Naguib", "Tawfik", "Hamdy", "Fouad", "Adel",
    "Yasser", "Kamel", "Said", "Gamal", "Hatem", "Rashad", "Nabil"]

def random_name():
    return f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"

CATEGORIES = [
    ("كهرباء", "كهرباء", "Electrical services", "خدمات الكهرباء والإضاءة", "⚡"),
    ("سباكه", "سباكه", "Plumbing services", "تركيب وإصلاح السباكة", "🔧"),
    ("نجاره", "نجاره", "Carpentry services", "أعمال النجارة والأثاث", "🪚"),
    ("خدمات منزليه", "خدمات منزليه", "Home maintenance", "صيانة عامة للمنزل", "🏠"),
]

GOVS = ["cairo", "alexandria", "giza", "dakahlia", "sharqia", "qalyubia",
        "beheira", "gharbia", "menofia", "ismailia", "aswan", "luxor",
        "asyut", "sohag", "qena", "minya", "beni_suef", "fayoum",
        "matrouh", "port_said", "suez", "damietta", "kafr_el_sheikh", "north_sinai"]
CITIES = {g: [f"{g}_city_{i}" for i in range(1, 4)] for g in GOVS}

STATUSES = ["COMPLETED", "CANCELLED", "PENDING", "IN_PROGRESS"]
STATUS_W = [0.55, 0.15, 0.15, 0.15]

def rand_date(start="2024-06", end="2026-06"):
    s = datetime.strptime(start, "%Y-%m")
    e = datetime.strptime(end, "%Y-%m")
    return s + timedelta(seconds=random.randint(0, int((e - s).total_seconds())))

# ── Generate Users ──
print("Generating users...")
users = []
roles_pool = ["client"] * 7 + ["worker"] * 3
for i in range(1, N_USERS + 1):
    role = random.choice(roles_pool)
    gov = random.choice(GOVS)
    city = random.choice(CITIES[gov])
    dj = rand_date("2024-01", "2026-05")
    users.append({
        "id": i,
        "username": f"user{i}",
        "name": random_name(),
        "email": f"user{i}@example.com" if random.random() > 0.3 else "",
        "phone": f"010{random.randint(10000000, 99999999)}",
        "role": role,
        "governorate": gov,
        "city": city,
        "address": f"{random.randint(1, 200)} {city} st" if random.random() > 0.2 else "",
        "is_active": True,
        "is_staff": False,
        "date_joined": dj.strftime("%Y-%m-%d %H:%M:%S"),
        "last_login": (dj + timedelta(days=random.randint(1, 365))).strftime("%Y-%m-%d %H:%M:%S") if random.random() > 0.1 else "",
    })
df_users = pd.DataFrame(users)
df_users.to_csv("data/users.csv", index=False)
print(f"  {len(df_users)} users saved")

# ── Generate Workers ──
print("Generating workers...")
worker_users = df_users[df_users["role"] == "worker"].sample(n=min(N_WORKERS, (df_users["role"] == "worker").sum())).copy()
workers = []
professions_ar = [c[1] for c in CATEGORIES]
for _, u in worker_users.iterrows():
    idx = random.randint(0, len(professions_ar) - 1)
    exp = random.randint(1, 25)
    avg_rating = round(random.uniform(1.0, 5.0), 1)
    completed = random.randint(10, 300)
    accept = round(random.uniform(30, 100), 1)
    hr = round(random.uniform(20, 200), 1) if random.random() > 0.3 else 0.0
    mc = round(random.uniform(50, 500), 1) if random.random() > 0.3 else 0.0
    dj = pd.to_datetime(u["date_joined"])
    workers.append({
        "user_id": u["id"],
        "username": u["username"],
        "name": u["name"],
        "phone": u["phone"],
        "email": u["email"],
        "governorate": u["governorate"],
        "city": u["city"],
        "is_active": True,
        "profession": professions_ar[idx],
        "profession_ar": professions_ar[idx],
        "experience_years": exp,
        "average_rating": avg_rating,
        "completed_jobs": completed,
        "accept_rate": accept,
        "is_available": random.random() > 0.2,
        "is_verified": random.random() > 0.3,
        "is_featured": random.random() > 0.7,
        "hourly_rate": hr,
        "minimum_charge": mc,
        "currency": "EGP",
        "date_joined": dj.strftime("%Y-%m-%d %H:%M:%S"),
        "profile_created_at": (dj + timedelta(days=random.randint(0, 30))).strftime("%Y-%m-%d %H:%M:%S"),
    })
df_workers = pd.DataFrame(workers)
df_workers.to_csv("data/workers.csv", index=False)
print(f"  {len(df_workers)} workers saved")

# ── Generate Orders ──
print("Generating orders...")
worker_usernames = df_workers["username"].tolist()
client_users = df_users[df_users["role"] == "client"]
orders = []
for i in range(1, N_ORDERS + 1):
    client = client_users.sample(1).iloc[0]
    worker_un = random.choice(worker_usernames)
    worker_row = df_workers[df_workers["username"] == worker_un].iloc[0]
    cat_idx = random.randint(0, len(CATEGORIES) - 1)
    cat_ar = CATEGORIES[cat_idx][1]
    status = random.choices(STATUSES, weights=STATUS_W, k=1)[0]
    urgency = random.choice(["NORMAL", "HIGH", "URGENT"])
    commission = round(random.uniform(20, 300), 2)
    ca = rand_date("2024-06", "2026-06")
    accepted = ca + timedelta(hours=random.randint(0, 8)) if status in ("COMPLETED", "IN_PROGRESS", "CANCELLED") else None
    completed = accepted + timedelta(hours=random.randint(1, 24)) if status == "COMPLETED" else None
    cancelled = accepted + timedelta(hours=random.randint(0, 4)) if status == "CANCELLED" else None
    lat = round(random.uniform(22, 31.5), 6)
    lon = round(random.uniform(25, 37), 6)
    orders.append({
        "id": i,
        "status": status,
        "urgency": urgency,
        "category": cat_ar,
        "category_ar": cat_ar,
        "client_username": client["username"],
        "client_name": client["name"],
        "client_phone": client["phone"],
        "worker_username": worker_un,
        "worker_name": worker_row["name"],
        "worker_phone": worker_row["phone"],
        "address": f"{random.randint(1, 200)} St" if random.random() > 0.3 else "",
        "latitude": lat,
        "longitude": lon,
        "commission": commission,
        "created_at": ca.strftime("%Y-%m-%d %H:%M:%S"),
        "accepted_at": accepted.strftime("%Y-%m-%d %H:%M:%S") if accepted else "",
        "completed_at": completed.strftime("%Y-%m-%d %H:%M:%S") if completed else "",
        "cancelled_at": cancelled.strftime("%Y-%m-%d %H:%M:%S") if cancelled else "",
    })
df_orders = pd.DataFrame(orders)
df_orders.to_csv("data/orders.csv", index=False)
print(f"  {len(df_orders)} orders saved")

# ── Generate Ratings ──
print("Generating ratings...")
completed = df_orders[df_orders["status"] == "COMPLETED"].copy()
ratings = []
for _, o in completed.iterrows():
    stars = random.choices([1, 2, 3, 4, 5], weights=[3, 5, 12, 35, 45], k=1)[0]
    reviews = ["", "ممتاز", "كويس", "شغل ممتاز", "كويس جدا", "احسن حاجه", "ممتاز جدا"]
    review = random.choice(reviews) if random.random() > 0.4 else ""
    ca = pd.to_datetime(o["completed_at"]) if o["completed_at"] else rand_date("2024-06", "2026-06")
    ratings.append({
        "id": o["id"],
        "stars": stars,
        "review": review,
        "order_id": o["id"],
        "order_category": o["category"],
        "client_username": o["client_username"],
        "client_name": o["client_name"],
        "worker_username": o["worker_username"],
        "worker_name": o["worker_name"],
        "worker_profession": o["category"],
        "created_at": ca.strftime("%Y-%m-%d %H:%M:%S"),
    })
df_ratings = pd.DataFrame(ratings)
df_ratings.to_csv("data/ratings.csv", index=False)
print(f"  {len(df_ratings)} ratings saved")

# ── Generate Categories ──
print("Generating categories...")
cats = []
for i, (en, ar, desc_en, desc_ar, icon) in enumerate(CATEGORIES, 1):
    cats.append({
        "id": i,
        "name": ar,
        "name_ar": ar,
        "description": desc_en,
        "description_ar": desc_ar,
        "icon": icon,
        "image_url": "",
    })
df_cats = pd.DataFrame(cats)
df_cats.to_csv("data/categories.csv", index=False)
print(f"  {len(df_cats)} categories saved")

print("Done! All CSVs generated.")
