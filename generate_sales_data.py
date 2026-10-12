"""
generate_sales_data.py
Generates realistic multi-year enterprise sales data for the Sales Performance BI solution.
Produces CSV files in the data/ directory:
- territories.csv
- sales_reps.csv
- products.csv
- customers.csv
- sales_targets.csv
- sales_orders.csv
"""

import os
import csv
import random
import datetime

# Seed for reproducibility
random.seed(42)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
os.makedirs(DATA_DIR, exist_ok=True)

# -------------------------------------------------------------
# 1. Territories
# -------------------------------------------------------------
territories = [
    {"TerritoryID": 1, "Region": "US West", "Country": "United States", "SalesGroup": "North America"},
    {"TerritoryID": 2, "Region": "US East", "Country": "United States", "SalesGroup": "North America"},
    {"TerritoryID": 3, "Region": "US Central", "Country": "United States", "SalesGroup": "North America"},
    {"TerritoryID": 4, "Region": "Canada", "Country": "Canada", "SalesGroup": "North America"},
    {"TerritoryID": 5, "Region": "United Kingdom", "Country": "United Kingdom", "SalesGroup": "Europe"},
    {"TerritoryID": 6, "Region": "DACH (Germany/Austria/CH)", "Country": "Germany", "SalesGroup": "Europe"},
    {"TerritoryID": 7, "Region": "France & Benelux", "Country": "France", "SalesGroup": "Europe"},
    {"TerritoryID": 8, "Region": "Australia & NZ", "Country": "Australia", "SalesGroup": "Asia Pacific"},
    {"TerritoryID": 9, "Region": "Japan & Korea", "Country": "Japan", "SalesGroup": "Asia Pacific"},
    {"TerritoryID": 10, "Region": "Latin America", "Country": "Brazil", "SalesGroup": "Latin America"},
]

with open(os.path.join(DATA_DIR, "territories.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["TerritoryID", "Region", "Country", "SalesGroup"])
    writer.writeheader()
    writer.writerows(territories)

# -------------------------------------------------------------
# 2. Sales Reps
# -------------------------------------------------------------
sales_reps_data = [
    (101, "Marcus", "Vance", "marcus.vance@company.com", "Senior Enterprise Account Exec", 1, "2021-03-15", 5200000),
    (102, "Sarah", "Chen", "sarah.chen@company.com", "Enterprise Account Exec", 1, "2022-06-01", 4500000),
    (103, "David", "Miller", "david.miller@company.com", "Regional Sales Director", 2, "2020-01-10", 6200000),
    (104, "Elena", "Rostova", "elena.rostova@company.com", "Senior Enterprise Account Exec", 2, "2021-08-20", 5400000),
    (105, "James", "Wilson", "james.wilson@company.com", "Mid-Market Account Exec", 3, "2022-11-05", 3800000),
    (106, "Chloe", "Tremblay", "chloe.tremblay@company.com", "Country Manager Canada", 4, "2021-05-12", 4800000),
    (107, "Oliver", "Smith", "oliver.smith@company.com", "UK Sales Director", 5, "2020-04-18", 5600000),
    (108, "Emma", "Watson", "emma.watson@company.com", "Enterprise Account Exec", 5, "2022-02-14", 4200000),
    (109, "Lucas", "Mueller", "lucas.mueller@company.com", "DACH Regional Lead", 6, "2021-09-01", 5500000),
    (110, "Hannah", "Weber", "hannah.weber@company.com", "Mid-Market Account Exec", 6, "2023-01-15", 3600000),
    (111, "Julien", "Dupont", "julien.dupont@company.com", "France Sales Lead", 7, "2021-10-10", 4600000),
    (112, "Liam", "O'Connor", "liam.oconnor@company.com", "APAC Regional Director", 8, "2020-07-01", 6000000),
    (113, "Mia", "Tanaka", "mia.tanaka@company.com", "Senior Enterprise Account Exec", 9, "2021-12-01", 5100000),
    (114, "Gabriel", "Silva", "gabriel.silva@company.com", "LatAm Commercial Lead", 10, "2022-04-15", 4000000),
    (115, "Aria", "Patel", "aria.patel@company.com", "Strategic Accounts Executive", 3, "2022-08-11", 5000000)
]

sales_reps = []
for item in sales_reps_data:
    sales_reps.append({
        "SalesRepID": item[0],
        "FirstName": item[1],
        "LastName": item[2],
        "Email": item[3],
        "Title": item[4],
        "TerritoryID": item[5],
        "HireDate": item[6],
        "QuotaTargetBase": item[7]
    })

with open(os.path.join(DATA_DIR, "sales_reps.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["SalesRepID", "FirstName", "LastName", "Email", "Title", "TerritoryID", "HireDate", "QuotaTargetBase"])
    writer.writeheader()
    writer.writerows(sales_reps)

# -------------------------------------------------------------
# 3. Products
# -------------------------------------------------------------
products_raw = [
    # Hardware
    ("HW-101", "Enterprise Rack Server Apex R7", "Hardware", "Servers", 4200.0, 6800.0),
    ("HW-102", "Compact Edge Gateway G3", "Hardware", "Networking", 650.0, 1150.0),
    ("HW-103", "Core Layer-3 48-Port Switch", "Hardware", "Networking", 1850.0, 3100.0),
    ("HW-104", "Enterprise All-Flash SAN Storage 12TB", "Hardware", "Storage", 8500.0, 14200.0),
    ("HW-105", "High-Density Blade Enclosure", "Hardware", "Servers", 5200.0, 8900.0),
    # Software & SaaS
    ("SW-201", "Nexus Cloud Security Suite (Annual)", "Software", "Cybersecurity", 1800.0, 4200.0),
    ("SW-202", "OmniData Analytics Platform (User/Yr)", "Software", "Analytics", 850.0, 2400.0),
    ("SW-203", "Synapse ERP Enterprise License", "Software", "Enterprise Apps", 12000.0, 28000.0),
    ("SW-204", "WorkFlow Orchestrator Pro", "Software", "Productivity", 400.0, 1100.0),
    ("SW-205", "Zero-Trust Identity Access Guard", "Software", "Cybersecurity", 950.0, 2600.0),
    # Cloud Services
    ("CS-301", "Managed Hybrid Cloud Hosting (Tier 1)", "Cloud Services", "Infrastructure", 2100.0, 4500.0),
    ("CS-302", "Disaster Recovery As-A-Service (DRaaS)", "Cloud Services", "Backup & Recovery", 1400.0, 3200.0),
    ("CS-303", "Kubernetes Multi-Cluster Management", "Cloud Services", "DevOps", 900.0, 2150.0),
    ("CS-304", "AI Inference API Gateway Tier", "Cloud Services", "AI & ML", 1600.0, 3800.0),
    # Professional Services
    ("PS-401", "Enterprise Architecture Audit (40 Hrs)", "Professional Services", "Consulting", 4000.0, 8500.0),
    ("PS-402", "Cloud Migration Implementation Package", "Professional Services", "Implementation", 7500.0, 16000.0),
    ("PS-403", "Cybersecurity Penetration Test & Remediation", "Professional Services", "Consulting", 5000.0, 11000.0),
    ("PS-404", "Custom BI Dashboard & Data Pipeline Dev", "Professional Services", "Development", 3800.0, 9200.0),
    # Peripherals & Add-ons
    ("PE-501", "Redundant 1200W Titanium Power Supply", "Peripherals", "Components", 180.0, 380.0),
    ("PE-502", "High-Speed SFP+ 10Gb Optical Transceiver 4-Pack", "Peripherals", "Networking Accessories", 120.0, 290.0),
    ("PE-503", "Hot-Swap NVMe 3.84TB Enterprise SSD", "Peripherals", "Storage Accessories", 450.0, 950.0)
]

products = []
for idx, (sku, name, cat, subcat, cost, price) in enumerate(products_raw, start=1):
    products.append({
        "ProductID": idx,
        "SKU": sku,
        "ProductName": name,
        "Category": cat,
        "SubCategory": subcat,
        "StandardCost": cost,
        "ListPrice": price,
        "Status": "Active"
    })

with open(os.path.join(DATA_DIR, "products.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["ProductID", "SKU", "ProductName", "Category", "SubCategory", "StandardCost", "ListPrice", "Status"])
    writer.writeheader()
    writer.writerows(products)

# -------------------------------------------------------------
# 4. Customers
# -------------------------------------------------------------
company_prefixes = ["Apex", "Vertex", "Quantum", "Horizon", "Pinnacle", "Starlight", "Atlas", "Beacon", "Nexus", "Solstice", "Vanguard", "Crestview", "BlueWave", "Terra", "Aero", "Pulse", "Cyber", "Ironclad", "Summit", "Dynamic"]
company_suffixes = ["Technologies", "Financial", "Logistics", "Healthcare", "Retail Group", "Energy", "Solutions", "Media", "BioTech", "Consulting", "Aerospace", "Global", "Systems", "Holdings", "Robotics"]
industries = ["FinTech & Banking", "Healthcare & Pharma", "Manufacturing", "Retail & E-Commerce", "Government & Education", "Telecommunications", "Energy & Utilities", "Professional Services"]
customer_types = ["Enterprise", "Mid-Market", "SMB", "Strategic Key Account"]

cities_by_territory = {
    1: [("San Francisco", "California", "USA"), ("Seattle", "Washington", "USA"), ("Los Angeles", "California", "USA")],
    2: [("New York", "New York", "USA"), ("Boston", "Massachusetts", "USA"), ("Atlanta", "Georgia", "USA")],
    3: [("Chicago", "Illinois", "USA"), ("Dallas", "Texas", "USA"), ("Minneapolis", "Minnesota", "USA")],
    4: [("Toronto", "Ontario", "Canada"), ("Vancouver", "British Columbia", "Canada"), ("Montreal", "Quebec", "Canada")],
    5: [("London", "Greater London", "UK"), ("Manchester", "Greater Manchester", "UK"), ("Edinburgh", "Midlothian", "UK")],
    6: [("Frankfurt", "Hesse", "Germany"), ("Munich", "Bavaria", "Germany"), ("Zurich", "Zurich", "Switzerland")],
    7: [("Paris", "Ile-de-France", "France"), ("Brussels", "Brussels", "Belgium"), ("Lyon", "Rhone", "France")],
    8: [("Sydney", "New South Wales", "Australia"), ("Melbourne", "Victoria", "Australia"), ("Brisbane", "Queensland", "Australia")],
    9: [("Tokyo", "Kanto", "Japan"), ("Osaka", "Kansai", "Japan"), ("Seoul", "Gyeonggi", "South Korea")],
    10: [("Sao Paulo", "Sao Paulo", "Brazil"), ("Rio de Janeiro", "Rio de Janeiro", "Brazil"), ("Bogota", "Cundinamarca", "Colombia")]
}

customers = []
cust_id = 1
for i in range(250):
    p = random.choice(company_prefixes)
    s = random.choice(company_suffixes)
    c_name = f"{p} {s}"
    terr_id = random.randint(1, 10)
    city_info = random.choice(cities_by_territory[terr_id])
    c_type = random.choices(customer_types, weights=[0.25, 0.45, 0.20, 0.10])[0]
    ind = random.choice(industries)
    customers.append({
        "CustomerID": cust_id,
        "CustomerName": c_name,
        "CustomerType": c_type,
        "Industry": ind,
        "City": city_info[0],
        "StateProvince": city_info[1],
        "Country": city_info[2],
        "TerritoryID": terr_id
    })
    cust_id += 1

with open(os.path.join(DATA_DIR, "customers.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["CustomerID", "CustomerName", "CustomerType", "Industry", "City", "StateProvince", "Country", "TerritoryID"])
    writer.writeheader()
    writer.writerows(customers)

# -------------------------------------------------------------
# 5. Sales Targets (Monthly Targets per Rep & Territory: 2024 - 2026)
# -------------------------------------------------------------
sales_targets = []
target_id = 1

month_seasonality = {
    1: 0.85, 2: 0.90, 3: 1.05,   # Q1
    4: 0.95, 5: 1.00, 6: 1.10,   # Q2
    7: 0.88, 8: 0.92, 9: 1.08,   # Q3
    10: 1.15, 11: 1.25, 12: 1.35 # Q4 (budget flush)
}

years = [2024, 2025, 2026]

for yr in years:
    yr_mult = 1.0 + (yr - 2024) * 0.12
    for mo in range(1, 13):
        date_key = yr * 10000 + mo * 100 + 1
        season_factor = month_seasonality[mo]
        for rep in sales_reps:
            base_monthly = (rep["QuotaTargetBase"] / 12.0) * yr_mult * season_factor
            target_amt = round(base_monthly * random.uniform(0.96, 1.04), 2)
            target_units = int(round(target_amt / 3500.0))
            sales_targets.append({
                "TargetID": target_id,
                "Year": yr,
                "Month": mo,
                "DateKey": date_key,
                "SalesRepID": rep["SalesRepID"],
                "TerritoryID": rep["TerritoryID"],
                "TargetAmount": target_amt,
                "TargetUnits": target_units
            })
            target_id += 1

with open(os.path.join(DATA_DIR, "sales_targets.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["TargetID", "Year", "Month", "DateKey", "SalesRepID", "TerritoryID", "TargetAmount", "TargetUnits"])
    writer.writeheader()
    writer.writerows(sales_targets)

# -------------------------------------------------------------
# 6. Sales Orders & Line Items (2024 to early 2026)
# -------------------------------------------------------------
rep_perf_factor = {
    101: 1.14, # Top performer
    102: 0.98,
    103: 1.08,
    104: 1.12, # Strong
    105: 0.88, # Struggling
    106: 1.02,
    107: 1.05,
    108: 0.92,
    109: 1.10,
    110: 0.82, # Junior rep ramp-up
    111: 0.96,
    112: 1.15, # Top APAC lead
    113: 1.04,
    114: 0.89,
    115: 1.07
}

channels = ["Direct Sales", "Partner / Reseller", "Online Portal", "Enterprise Contract"]
channel_weights = [0.45, 0.30, 0.15, 0.10]

start_date = datetime.date(2024, 1, 1)
end_date = datetime.date(2026, 10, 1)
total_days = (end_date - start_date).days

sales_orders = []
order_id = 10001

custs_by_terr = {}
for c in customers:
    custs_by_terr.setdefault(c["TerritoryID"], []).append(c["CustomerID"])

for rep in sales_reps:
    r_id = rep["SalesRepID"]
    t_id = rep["TerritoryID"]
    p_factor = rep_perf_factor.get(r_id, 1.0)
    rep_custs = custs_by_terr.get(t_id, [c["CustomerID"] for c in customers])
    
    current_dt = start_date
    while current_dt <= end_date:
        yr = current_dt.year
        mo = current_dt.month
        season = month_seasonality[mo]
        orders_this_month = int(round(random.randint(14, 25) * season * p_factor))
        
        days_in_month = 28 if mo == 2 else (30 if mo in [4, 6, 9, 11] else 31)
        for _ in range(orders_this_month):
            day = min(random.randint(1, days_in_month), (end_date.day if (yr == end_date.year and mo == end_date.month) else days_in_month))
            try:
                order_dt = datetime.date(yr, mo, day)
            except ValueError:
                order_dt = datetime.date(yr, mo, 28)
            
            if order_dt > end_date:
                continue
                
            ship_days = random.randint(1, 7)
            ship_dt = order_dt + datetime.timedelta(days=ship_days)
            
            cust_chosen = random.choice(rep_custs)
            chan_chosen = random.choices(channels, weights=channel_weights)[0]
            
            if (end_date - order_dt).days < 3:
                status = random.choice(["Processing", "Shipped"])
            else:
                status = random.choices(["Completed", "Shipped", "Returned", "Cancelled"], weights=[0.88, 0.08, 0.02, 0.02])[0]
            
            num_lines = random.choices([1, 2, 3, 4], weights=[0.55, 0.25, 0.15, 0.05])[0]
            chosen_prods = random.sample(products, k=num_lines)
            
            for line_idx, prod in enumerate(chosen_prods, start=1):
                qty = random.choices([1, 2, 3, 5, 10], weights=[0.50, 0.25, 0.15, 0.07, 0.03])[0]
                unit_price = prod["ListPrice"]
                cost = prod["StandardCost"]
                
                disc_pct = 0.0
                if chan_chosen == "Enterprise Contract":
                    disc_pct = random.choice([0.10, 0.12, 0.15, 0.18])
                elif chan_chosen == "Partner / Reseller":
                    disc_pct = random.choice([0.05, 0.08, 0.10])
                elif random.random() < 0.25:
                    disc_pct = random.choice([0.05, 0.08])
                
                line_gross = round(unit_price * qty, 2)
                discount_amt = round(line_gross * disc_pct, 2)
                tax_amt = round((line_gross - discount_amt) * 0.075, 2)
                shipping_amt = round(15.0 + (qty * 4.5), 2)
                
                sales_orders.append({
                    "OrderID": order_id,
                    "OrderLineNumber": line_idx,
                    "OrderDate": order_dt.strftime("%Y-%m-%d"),
                    "ShipDate": ship_dt.strftime("%Y-%m-%d"),
                    "CustomerID": cust_chosen,
                    "ProductID": prod["ProductID"],
                    "SalesRepID": r_id,
                    "TerritoryID": t_id,
                    "Channel": chan_chosen,
                    "OrderQuantity": qty,
                    "UnitPrice": unit_price,
                    "UnitCost": cost,
                    "DiscountAmount": discount_amt,
                    "TaxAmount": tax_amt,
                    "ShippingAmount": shipping_amt,
                    "OrderStatus": status
                })
            
            order_id += 1
        
        if mo == 12:
            current_dt = datetime.date(yr + 1, 1, 1)
        else:
            current_dt = datetime.date(yr, mo + 1, 1)

with open(os.path.join(DATA_DIR, "sales_orders.csv"), "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=[
        "OrderID", "OrderLineNumber", "OrderDate", "ShipDate", "CustomerID", "ProductID",
        "SalesRepID", "TerritoryID", "Channel", "OrderQuantity", "UnitPrice", "UnitCost",
        "DiscountAmount", "TaxAmount", "ShippingAmount", "OrderStatus"
    ])
    writer.writeheader()
    writer.writerows(sales_orders)

print(f"[SUCCESS] Generated files in: {DATA_DIR}")
print(f"  - Territories: {len(territories)}")
print(f"  - Sales Reps: {len(sales_reps)}")
print(f"  - Products: {len(products)}")
print(f"  - Customers: {len(customers)}")
print(f"  - Monthly Targets: {len(sales_targets)}")
print(f"  - Sales Orders (Line items): {len(sales_orders)}")
