"""Egyptian governorates — the single source of truth for the
27 governorates that Egypt was reorganized into in 2008 (when Luxor
was split off from Qena).

Each entry has:
  * `code`     — stable machine token stored in DB (User.governorate).
  * `name_en`  — English label.
  * `name_ar`  — Arabic label (الاسم بالعربية), what mobile UI shows
                 by default since the platform is Arabic-first.

The `Governorate` TextChoices in models.py uses the same codes; this
module exists so the JSON shape `{code, name_en, name_ar}` lives in one
place and can be exposed via the public `/api/governorates/`
endpoint without re-iterating the list anywhere else.
"""
from typing import List, Dict

# Order roughly groups capital + delta first, then mid-Egypt, then
# Upper Egypt, then canal cities, then frontier governorates. That's
# the same order shoppers/buyers see in most Egyptian sign-up forms.
GOVERNORATES: List[Dict[str, str]] = [
    {"code": "cairo",        "name_en": "Cairo",          "name_ar": "القاهرة"},
    {"code": "giza",         "name_en": "Giza",           "name_ar": "الجيزة"},
    {"code": "alexandria",   "name_en": "Alexandria",     "name_ar": "الإسكندرية"},
    {"code": "qalyubia",     "name_en": "Qalyubia",       "name_ar": "القليوبية"},
    {"code": "sharqia",      "name_en": "Sharqia",        "name_ar": "الشرقية"},
    {"code": "dakahlia",     "name_en": "Dakahlia",       "name_ar": "الدقهلية"},
    {"code": "menofia",      "name_en": "Menofia",        "name_ar": "المنوفية"},
    {"code": "gharbia",      "name_en": "Gharbia",        "name_ar": "الغربية"},
    {"code": "kafr_sheikh",  "name_en": "Kafr El-Sheikh", "name_ar": "كفر الشيخ"},
    {"code": "beheira",      "name_en": "Beheira",        "name_ar": "البحيرة"},
    {"code": "damietta",     "name_en": "Damietta",       "name_ar": "دمياط"},
    {"code": "port_said",    "name_en": "Port Said",      "name_ar": "بورسعيد"},
    {"code": "ismailia",     "name_en": "Ismailia",       "name_ar": "الإسماعيلية"},
    {"code": "suez",         "name_en": "Suez",           "name_ar": "السويس"},
    {"code": "fayoum",       "name_en": "Fayoum",         "name_ar": "الفيوم"},
    {"code": "beni_suef",    "name_en": "Beni Suef",      "name_ar": "بني سويف"},
    {"code": "minya",        "name_en": "Minya",          "name_ar": "المنيا"},
    {"code": "asyut",        "name_en": "Asyut",          "name_ar": "أسيوط"},
    {"code": "sohag",        "name_en": "Sohag",          "name_ar": "سوهاج"},
    {"code": "qena",         "name_en": "Qena",           "name_ar": "قنا"},
    {"code": "luxor",        "name_en": "Luxor",          "name_ar": "الأقصر"},
    {"code": "aswan",        "name_en": "Aswan",          "name_ar": "أسوان"},
    {"code": "red_sea",      "name_en": "Red Sea",        "name_ar": "البحر الأحمر"},
    {"code": "new_valley",   "name_en": "New Valley",     "name_ar": "الوادي الجديد"},
    {"code": "matrouh",      "name_en": "Matrouh",        "name_ar": "مطروح"},
    {"code": "north_sinai",  "name_en": "North Sinai",    "name_ar": "شمال سيناء"},
    {"code": "south_sinai",  "name_en": "South Sinai",    "name_ar": "جنوب سيناء"},
]

GOVERNORATE_CODES = {g["code"] for g in GOVERNORATES}
GOVERNORATE_NAME_AR = {g["code"]: g["name_ar"] for g in GOVERNORATES}
