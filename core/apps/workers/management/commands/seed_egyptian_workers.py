"""
Seed the database with realistic Egyptian workers (Cairo + Beni Suef focused).

Usage:
    python manage.py seed_egyptian_workers
    python manage.py seed_egyptian_workers --reset    # wipe existing seeded workers first
    python manage.py seed_egyptian_workers --count 50 # target ~50 workers
"""

from __future__ import annotations

import random
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction

from decimal import Decimal as D

from apps.users.models import Governorate, User
from apps.workers.models import ServiceCategory, WorkerProfile


# ─── Specialties pool per profession (en, ar) ─────────────────────────────
SPECIALTIES_POOL: dict[str, tuple[list[str], list[str]]] = {
    "Plumber":        (["leak repair","water heater","sink install","drain unclog"],
                       ["إصلاح تسريبات","تركيب سخان","تركيب أحواض","فك انسداد"]),
    "Electrician":    (["panel install","wiring","breaker fix","lighting"],
                       ["تركيب لوحات","تمديدات","إصلاح قواطع","إنارة"]),
    "Carpenter":      (["kitchen cabinets","doors","furniture repair","custom shelving"],
                       ["مطابخ","أبواب","إصلاح أثاث","أرفف خاصة"]),
    "Painter":        (["interior paint","exterior paint","decor finishes","plaster"],
                       ["دهانات داخلية","دهانات خارجية","ديكورات","محارة"]),
    "AC Technician":  (["split AC install","central AC","deep cleaning","gas refill"],
                       ["تركيب سبليت","تكييف مركزي","تنظيف عميق","شحن فريون"]),
    "Washing Machine":(["drum repair","drain fix","new install"],
                       ["إصلاح حلة","إصلاح طلمبة","تركيب جديد"]),
    "Refrigerator":   (["gas refill","compressor","thermostat"],
                       ["شحن غاز","كومبروسر","ثرموستات"]),
    "Cleaning":       (["deep cleaning","post-construction","sofa shampoo","window wash"],
                       ["تنظيف عميق","تنظيف بعد تشطيب","غسيل كنب","غسيل زجاج"]),
    "Satellite Dish": (["dish install","receiver setup","reprogramming"],
                       ["تركيب دش","ضبط ريسيفر","إعادة برمجة"]),
    "Tiling / Mason": (["ceramic","marble","plaster work","grouting"],
                       ["سيراميك","رخام","محارة","جوايط"]),
    "Blacksmith":     (["iron doors","windows","railings","gates"],
                       ["أبواب حديد","شبابيك","درابزين","بوابات"]),
    "Gardener":       (["maintenance","planting","irrigation"],
                       ["صيانة","زراعة","رى"]),
}

# Approximate centroids for the major locations we seed.
LOCATION_GEO: dict[tuple[str, str], tuple[float, float]] = {
    (Governorate.CAIRO,     "Nasr City"):       (30.0626, 31.3326),
    (Governorate.CAIRO,     "Heliopolis"):      (30.0905, 31.3220),
    (Governorate.CAIRO,     "Maadi"):           (29.9626, 31.2497),
    (Governorate.CAIRO,     "Zamalek"):         (30.0626, 31.2197),
    (Governorate.CAIRO,     "Downtown"):        (30.0444, 31.2357),
    (Governorate.CAIRO,     "6th of October"):  (29.9602, 30.9265),
    (Governorate.CAIRO,     "Shubra"):          (30.1083, 31.2419),
    (Governorate.CAIRO,     "New Cairo"):       (30.0301, 31.4775),
    (Governorate.CAIRO,     "Helwan"):          (29.8419, 31.3344),
    (Governorate.CAIRO,     "Ain Shams"):       (30.1290, 31.3220),
    (Governorate.CAIRO,     "El Marg"):         (30.1646, 31.3372),
    (Governorate.CAIRO,     "El Matareya"):     (30.1295, 31.3061),
    (Governorate.GIZA,      "Dokki"):           (30.0381, 31.2120),
    (Governorate.GIZA,      "Mohandessin"):     (30.0626, 31.2009),
    (Governorate.GIZA,      "Faisal"):          (29.9966, 31.1646),
    (Governorate.GIZA,      "Haram"):           (29.9870, 31.1340),
    (Governorate.GIZA,      "Imbaba"):          (30.0772, 31.2073),
    (Governorate.GIZA,      "Boulaq"):          (30.0440, 31.2050),
    (Governorate.BENI_SUEF, "Beni Suef City"):  (29.0744, 31.0978),
    (Governorate.BENI_SUEF, "Beba"):            (28.9020, 30.8650),
    (Governorate.BENI_SUEF, "Wasti"):           (29.3343, 31.2014),
    (Governorate.BENI_SUEF, "Nasser"):          (28.6422, 30.8470),
    (Governorate.BENI_SUEF, "Ihnasia"):         (29.0900, 30.9300),
    (Governorate.BENI_SUEF, "Al-Fashn"):        (28.8214, 30.8908),
    (Governorate.BENI_SUEF, "Sumusta"):         (28.6841, 30.8553),
    (Governorate.BENI_SUEF, "New Beni Suef"):   (29.0700, 31.1250),
    (Governorate.ALEXANDRIA,"Smouha"):          (31.2197, 29.9450),
    (Governorate.ALEXANDRIA,"Sidi Gaber"):      (31.2200, 29.9420),
    (Governorate.MINYA,     "Minya Center"):    (28.1099, 30.7503),
    (Governorate.FAYOUM,    "Fayoum City"):     (29.3084, 30.8418),
}


# ─── Service catalog (bilingual) ──────────────────────────────────────────
# (en, ar, icon, en-desc, ar-desc, base_rate_egp_per_hour)
SERVICES: list[tuple[str, str, str, str, str, int]] = [
    ("Plumber",        "سباك",          "plumbing",   "Pipes, leaks, sinks, water heaters",          "سباكة، تسريبات، أحواض، سخانات",          120),
    ("Electrician",    "كهربائي",        "bolt",       "Wiring, breakers, outlets, lighting",         "كهرباء منزلية، تركيب ولوحات وتوصيلات",   140),
    ("Carpenter",      "نجار",           "hammer",     "Furniture, doors, kitchen cabinets",          "نجارة، أبواب، مطابخ، إصلاح أثاث",        130),
    ("Painter",        "نقاش / دهان",    "brush",      "Walls, paint, plaster, decorative finishes",  "محارة ودهانات وديكورات",                100),
    ("AC Technician",  "فني تكييف",      "ac_unit",    "Install, repair and clean AC units",          "تركيب وصيانة وتنظيف التكييفات",         180),
    ("Washing Machine","فني غسالات",     "local_laundry_service", "Washing machine repair and install", "إصلاح وتركيب الغسالات الأوتوماتيك",   150),
    ("Refrigerator",   "فني ثلاجات",     "kitchen",    "Fridge and freezer repair",                   "إصلاح وصيانة الثلاجات والديب فريزر",     160),
    ("Cleaning",       "تنظيف منازل",   "cleaning_services", "Home and apartment deep cleaning",    "تنظيف شقق وفلل وتلميع",                  80),
    ("Satellite Dish", "فني دش",         "satellite_alt", "Satellite dish install and reprogramming","تركيب وضبط الدش والريسيفر",             90),
    ("Tiling / Mason", "محارة وبلاط",    "grid_view",  "Tiling, masonry, marble installation",        "محارة وتركيب سيراميك ورخام",            150),
    ("Blacksmith",     "حداد",           "construction","Iron doors, railings, windows",              "حدادة، أبواب وشبابيك حديد",             170),
    ("Gardener",       "جنايني",         "yard",       "Garden maintenance, planting",                "تنسيق الحدائق وزراعة النباتات",         70),
]


# ─── Cairo districts ──────────────────────────────────────────────────────
CAIRO_DISTRICTS = [
    ("Nasr City",       "مدينة نصر"),
    ("Heliopolis",      "مصر الجديدة"),
    ("Maadi",           "المعادي"),
    ("Zamalek",         "الزمالك"),
    ("Downtown",        "وسط البلد"),
    ("6th of October",  "السادس من أكتوبر"),
    ("Shubra",          "شبرا"),
    ("New Cairo",       "القاهرة الجديدة"),
    ("Helwan",          "حلوان"),
    ("Ain Shams",       "عين شمس"),
    ("El Marg",         "المرج"),
    ("El Matareya",     "المطرية"),
]

# Some workers tagged to Giza for realism (Cairo metro)
GIZA_DISTRICTS = [
    ("Dokki",       "الدقي"),
    ("Mohandessin", "المهندسين"),
    ("Faisal",      "فيصل"),
    ("Haram",       "الهرم"),
    ("Imbaba",      "إمبابة"),
    ("Boulaq",      "بولاق الدكرور"),
]

# ─── Beni Suef cities / districts ─────────────────────────────────────────
BENI_SUEF_DISTRICTS = [
    ("Beni Suef City",  "مدينة بني سويف"),
    ("Beba",            "ببا"),
    ("Wasti",           "الواسطى"),
    ("Nasser",          "ناصر"),
    ("Ihnasia",         "إهناسيا"),
    ("Al-Fashn",        "الفشن"),
    ("Sumusta",         "سمسطا"),
    ("New Beni Suef",   "بني سويف الجديدة"),
]

OTHER_GOV_DISTRICTS = [
    (Governorate.ALEXANDRIA, "Smouha",       "سموحة"),
    (Governorate.ALEXANDRIA, "Sidi Gaber",   "سيدي جابر"),
    (Governorate.MINYA,      "Minya Center", "مركز المنيا"),
    (Governorate.FAYOUM,     "Fayoum City",  "مدينة الفيوم"),
]


# ─── Common Egyptian first / family names ────────────────────────────────
FIRST_NAMES_AR = [
    "محمد", "أحمد", "محمود", "حسن", "حسين", "علي", "مصطفى",
    "إبراهيم", "خالد", "طارق", "سيد", "رضا", "صابر", "مجدي",
    "كريم", "وائل", "ياسر", "هاني", "شريف", "عماد", "سامح",
    "أيمن", "عمرو", "فؤاد", "نبيل", "عاطف",
]

FAMILY_NAMES_AR = [
    "عبد الرحمن", "عبد الله", "السيد", "الشريف", "حسني", "العشري",
    "البنا", "الجمل", "الفقي", "النجار", "المنشاوي", "غنيم",
    "البدوي", "الديب", "الباز", "زكي", "فوزي", "متولي", "عثمان",
]

FIRST_NAMES_EN = [
    "Mohamed", "Ahmed", "Mahmoud", "Hassan", "Hussein", "Ali", "Mostafa",
    "Ibrahim", "Khaled", "Tarek", "Sayed", "Reda", "Saber", "Magdy",
    "Karim", "Wael", "Yasser", "Hany", "Sherif", "Emad", "Sameh",
    "Ayman", "Amr", "Fouad", "Nabil", "Atef",
]

FAMILY_NAMES_EN = [
    "Abdelrahman", "Abdullah", "Elsayed", "Elsharif", "Hosny", "Elashry",
    "Elbanna", "Elgamal", "Elfeki", "Elnaggar", "Elmenshawy", "Ghoneim",
    "Elbadawy", "Eldeeb", "Elbaz", "Zaky", "Fawzy", "Metwally", "Othman",
]

assert len(FIRST_NAMES_AR) == len(FIRST_NAMES_EN)
assert len(FAMILY_NAMES_AR) == len(FAMILY_NAMES_EN)


BIO_TEMPLATES_AR = [
    "خبرة {y} سنة في {p}. شغل نضيف ومضمون والأسعار مناسبة.",
    "{p} محترف بخبرة {y} سنة، أمانة وسرعة في التنفيذ.",
    "بتعامل بضمير، {y} سنة خبرة في {p}، متاح في أي وقت.",
    "متخصص في {p} منذ {y} سنوات، الكشف بالمجان والشغل بضمان.",
]

BIO_TEMPLATES_EN = [
    "{y} years of experience as a {p}. Clean work and fair prices.",
    "Professional {p} with {y} years of experience — reliable and fast.",
    "Trusted {p} with {y} years on the job. Available any day.",
    "Specialised {p} for {y} years. Free inspection, guaranteed work.",
]


def egyptian_phone() -> str:
    prefix = random.choice(["010", "011", "012", "015"])
    rest = "".join(random.choices("0123456789", k=8))
    return f"+20{prefix[1:]}{rest}"   # +20 10XXXXXXXX form


def unique_username(base: str, used: set[str]) -> str:
    candidate = base
    n = 1
    while candidate in used or User.objects.filter(username=candidate).exists():
        n += 1
        candidate = f"{base}{n}"
    used.add(candidate)
    return candidate


class Command(BaseCommand):
    help = "Seed realistic Egyptian workers (Cairo + Beni Suef focused)."

    def add_arguments(self, parser):
        parser.add_argument("--count", type=int, default=36)
        parser.add_argument("--reset", action="store_true",
                            help="Delete previously seeded workers (username starts with 'eg_').")

    @transaction.atomic
    def handle(self, *args, count, reset, **opts):
        if reset:
            removed, _ = User.objects.filter(username__startswith="eg_").delete()
            self.stdout.write(self.style.WARNING(f"Removed {removed} previously seeded users."))

        # 1. Service categories ------------------------------------------------
        cats_by_en = {}
        for en, ar, icon, desc_en, desc_ar, _base in SERVICES:
            cat, _ = ServiceCategory.objects.update_or_create(
                name=en,
                defaults={"name_ar": ar, "icon": icon,
                          "description": desc_en, "description_ar": desc_ar},
            )
            cats_by_en[en] = cat
        self.stdout.write(self.style.SUCCESS(f"Service categories: {ServiceCategory.objects.count()}"))

        # 2. Build the location pool ------------------------------------------
        # Split: ~50% Cairo, ~30% Beni Suef, ~10% Giza, ~10% other
        pool: list[tuple[str, str, str]] = []  # (gov, city_en, city_ar)
        for _ in range(max(1, int(count * 0.50))):
            d = random.choice(CAIRO_DISTRICTS)
            pool.append((Governorate.CAIRO, d[0], d[1]))
        for _ in range(max(1, int(count * 0.30))):
            d = random.choice(BENI_SUEF_DISTRICTS)
            pool.append((Governorate.BENI_SUEF, d[0], d[1]))
        for _ in range(max(1, int(count * 0.10))):
            d = random.choice(GIZA_DISTRICTS)
            pool.append((Governorate.GIZA, d[0], d[1]))
        for _ in range(max(1, int(count * 0.10))):
            gov, en, ar = random.choice(OTHER_GOV_DISTRICTS)
            pool.append((gov, en, ar))

        random.shuffle(pool)
        pool = pool[:count]

        # 3. Create workers ---------------------------------------------------
        used_usernames: set[str] = set()
        created = 0

        for idx, (gov, city_en, city_ar) in enumerate(pool):
            i = random.randrange(len(FIRST_NAMES_EN))
            j = random.randrange(len(FAMILY_NAMES_EN))
            first_en, first_ar = FIRST_NAMES_EN[i], FIRST_NAMES_AR[i]
            fam_en, fam_ar = FAMILY_NAMES_EN[j], FAMILY_NAMES_AR[j]

            base = f"eg_{first_en.lower()}_{fam_en.lower().replace(' ', '')}"
            username = unique_username(base, used_usernames)

            # Pick service
            en, ar, icon, _desc_en, _desc_ar, base_rate = random.choice(SERVICES)

            experience = random.randint(1, 22)
            rating = round(random.uniform(3.6, 4.95), 2)
            jobs = random.randint(3, 220)
            rate_var = random.uniform(0.85, 1.4)
            hourly = Decimal(str(round(base_rate * rate_var / 5) * 5))  # snap to 5 EGP
            is_verified = rating >= 4.5 and jobs >= 30

            user = User.objects.create_user(
                username=username,
                name_ar=f"{first_ar} {fam_ar}",
                email=f"{username}@example.com",
                phone=egyptian_phone(),
                password="password123",
                role=User.Role.WORKER,
                first_name=first_en,
                last_name=fam_en,
                address=f"{city_en}",
                governorate=gov,
                city=city_en,
            )

            bio_en = random.choice(BIO_TEMPLATES_EN).format(y=experience, p=en.lower())
            bio_ar = random.choice(BIO_TEMPLATES_AR).format(y=experience, p=ar)

            # Specialties — pick 2-4 from the pool
            sp_en, sp_ar = SPECIALTIES_POOL.get(en, ([], []))
            picks = random.sample(range(len(sp_en)), k=min(len(sp_en), random.randint(2, 4))) if sp_en else []
            specialties = ",".join(sp_en[i] for i in picks)
            specialties_ar_str = ",".join(sp_ar[i] for i in picks) if sp_ar else ""

            # Languages
            languages = "ar"
            if random.random() < 0.4:
                languages = "ar,en"

            response_minutes = random.choice([10, 15, 20, 30, 45, 60, 90])
            completion_rate = round(min(99.0, 70 + rating * 5 + random.uniform(-2, 4)), 1)
            accept_rate = round(min(99.0, 60 + rating * 6 + random.uniform(-3, 5)), 1)
            wh_start = random.choice([7, 8, 9, 10])
            wh_end = random.choice([18, 20, 21, 22, 23])

            lat_lng = LOCATION_GEO.get((gov, city_en))
            if lat_lng:
                lat = D(str(round(lat_lng[0] + random.uniform(-0.012, 0.012), 6)))
                lng = D(str(round(lat_lng[1] + random.uniform(-0.012, 0.012), 6)))
            else:
                lat, lng = None, None

            WorkerProfile.objects.create(
                user=user,
                profession=en,
                profession_ar=ar,
                bio=bio_en,
                bio_ar=bio_ar,
                experience_years=experience,
                hourly_rate=hourly,
                minimum_charge=Decimal(str(int(float(hourly) * 0.7))),
                currency="EGP",
                specialties=specialties,
                specialties_ar=specialties_ar_str,
                languages=languages,
                response_time_minutes=response_minutes,
                completion_rate=completion_rate,
                accept_rate=accept_rate,
                working_hours_start=wh_start,
                working_hours_end=wh_end,
                works_friday=random.random() < 0.6,
                latitude=lat,
                longitude=lng,
                service_radius_km=random.choice([5, 10, 15, 20, 30]),
                average_rating=rating,
                completed_jobs=jobs,
                is_verified=is_verified,
                is_featured=(rating >= 4.8 and jobs >= 100),
                is_available=random.random() < 0.85,
            )
            created += 1

        self.stdout.write(self.style.SUCCESS(
            f"Created {created} Egyptian worker profiles "
            f"({Governorate.CAIRO} + {Governorate.BENI_SUEF} focused)."
        ))

        # Summary breakdown by governorate
        from collections import Counter
        breakdown = Counter(
            WorkerProfile.objects.filter(user__username__startswith="eg_")
            .values_list("user__governorate", flat=True)
        )
        for gov, n in breakdown.most_common():
            self.stdout.write(f"  {gov:>12}: {n}")
