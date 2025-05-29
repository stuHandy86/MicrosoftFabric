import pandas as pd
import numpy as np
from faker import Faker
import random
from datetime import datetime, timedelta

fake = Faker()

# Define hotel distribution
regions = {
    "North America": ["New York", "Los Angeles", "Toronto", "Vancouver", "Chicago"],
    "United Kingdom": ["London", "Manchester", "Edinburgh", "Birmingham", "Bristol"],
    "Australia": ["Sydney", "Melbourne", "Brisbane", "Perth", "Adelaide"]
}

city_coords = {
    "New York": (40.7128, -74.0060),
    "Los Angeles": (34.0522, -118.2437),
    "Toronto": (43.651070, -79.347015),
    "Vancouver": (49.2827, -123.1207),
    "Chicago": (41.8781, -87.6298),
    "London": (51.5074, -0.1278),
    "Manchester": (53.4808, -2.2426),
    "Edinburgh": (55.9533, -3.1883),
    "Birmingham": (52.4862, -1.8904),
    "Bristol": (51.4545, -2.5879),
    "Sydney": (-33.8688, 151.2093),
    "Melbourne": (-37.8136, 144.9631),
    "Brisbane": (-27.4698, 153.0251),
    "Perth": (-31.9505, 115.8605),
    "Adelaide": (-34.9285, 138.6007)
}

# Generate 200 hotel names and assign cities
all_cities = sum(regions.values(), [])
hotels = [f"GlobalStay Hotel {i+1}" for i in range(200)]
hotel_city_map = {hotel: random.choice(all_cities) for hotel in hotels}

# Generate 10,000 records
records = []
for _ in range(10000):
    hotel = random.choice(hotels)
    city = hotel_city_map[hotel]
    lat, lon = city_coords[city]
    room_number = random.randint(100, 999)
    check_in = fake.date_time_between(start_date='-1y', end_date='now')
    stay_length = random.randint(1, 14)
    check_out = check_in + timedelta(days=stay_length)
    guests = random.randint(1, 4)
    rate = round(random.uniform(75, 500), 2)
    early_check_in = random.choice(["Yes", "No"])
    
    records.append([
        hotel,
        city,
        lon,
        lat,
        room_number,
        check_in,
        check_out,
        guests,
        rate,
        early_check_in
    ])

# Create DataFrame and save to CSV
columns = [
    "Hotel", "City", "Longitude", "Latitude", "Room number", 
    "Check in date time", "Check out date time", 
    "Number of guests", "Room rate per night (gbp)", "Early check in"
]
df = pd.DataFrame(records, columns=columns)
file_path = "/mnt/data/hotel_bookings.csv"
df.to_csv(file_path, index=False)
file_path