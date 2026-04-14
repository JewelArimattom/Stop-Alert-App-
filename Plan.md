# 🚆 Travel Alarm App – Full Development Plan

## 📌 Overview
A mobile application that alerts users when they are near their destination while traveling (bus/train), even if they fall asleep.

---

# 🎯 Goals
- Work **100% offline**
- Be **battery efficient**
- Reduce **device heating**
- Support **background tracking**
- Provide **accurate alerts**

---

# 🧰 Tech Stack (100% Free)

## 📱 App
- Flutter

## 🗺️ Maps
- OpenStreetMap (flutter_map)

## 📍 Location
- geolocator (uses device GPS)

## 💾 Storage
- Hive / SQLite

## 🔔 Notifications
- flutter_local_notifications

## 🔄 Background Tasks
- workmanager
- flutter_background_service

---

# 🏗️ Architecture

User → Flutter App → GPS (Device)
                     ↓
              Local Processing
                     ↓
            Distance Calculation
                     ↓
           Alert + Notification

👉 No backend required

---

# ⚙️ Core Modules

## 1. Location Engine
- Fetch GPS location
- Adaptive update intervals
- Battery optimized

---

## 2. Distance Engine
- Use Haversine formula
- Fully offline calculation

---

## 3. Geofence Engine
- Trigger alert when within radius

---

## 4. Travel Detection Engine
- Detect:
  - Walking
  - Bus
  - Train

Based on:
- Speed
- Stop patterns

---

## 5. Notification Engine
- Multi-level alerts:
  - 1000m → Notification
  - 500m → Sound alert
  - 200m → Continuous alarm

---

## 6. Background Engine
- Runs even when app is closed
- Uses foreground service (Android)

---

# 🧠 Core Logic

## Distance Calculation

distance = haversine(current_lat, current_lng, dest_lat, dest_lng)


---

## ETA Calculation

time_to_destination = distance / speed


---

# 🚀 Optimized Tracking Strategy (IMPORTANT)

## ✅ Correct Version of Adaptive Tracking

Instead of fixed distance pings (like 10km → 15km → 18km),
use **dynamic tracking based on distance**:

---

### 🔹 FAR (>10 km)

check every 30–60 seconds
low accuracy mode


---

### 🔹 MID (10 km → 2 km)

check every 10–15 seconds
medium accuracy


---

### 🔹 NEAR (2 km → 500 m)

check every 5 seconds
high accuracy


---

### 🔹 VERY CLOSE (<500 m)

check every 1–2 seconds
very high accuracy


---

## 📌 Progressive Refinement Model


if distance > 10 km:
very low tracking

elif distance > 5 km:
low tracking

elif distance > 2 km:
medium tracking

elif distance > 1 km:
high tracking

elif distance < 500 m:
very high tracking


👉 This ensures:
- Low battery usage far away
- High accuracy near destination
- No missed stops

---

# 🚆 Speed-Based Adjustment


if speed > 60 km/h:
trigger_radius = 1000m # Train

elif speed > 30 km/h:
trigger_radius = 500m # Bus

else:
trigger_radius = 200m # Walking


---

# 🔋 Battery Optimization

## Rules:
- Avoid continuous GPS
- Use adaptive intervals
- Stop tracking when idle


if no movement for 5 minutes:
pause GPS


---

## Techniques:
- Use low accuracy when far
- Reduce update frequency
- Avoid constant loops

---

# 🔥 Heat Reduction Strategy

- Minimize CPU usage
- Avoid frequent updates
- Disable map rendering in background
- Run only essential logic


run_check_every(10 seconds)


---

# 📡 Offline Strategy

- Store destination locally
- Use GPS only
- No API calls needed

---

# 🔔 Alert Logic


if distance < 1000:
notify_user()

if distance < 500:
play_sound()

if distance < 200:
continuous_alarm()


---

# 🛑 Stop Conditions


if destination_reached:
stop_tracking()

if user_not_moving:
reduce_tracking()


---

# 🧪 Testing Plan

## Test Cases:
- Bus with frequent stops
- Train with high speed
- Poor GPS signal
- Background mode
- App killed scenario

---

# 📅 Development Timeline

## Week 1
- Location + map + distance

## Week 2
- Geofence + alerts

## Week 3
- Background tracking

## Week 4
- Travel detection

## Week 5
- Optimization + UI

---

# ⚠️ Challenges

- GPS inaccuracy
- Background restrictions
- Battery drain
- Missed alerts

---

# 💡 Future Enhancements

- AI prediction of stops
- Voice alerts
- Trip sharing
- Smart wake timing

---

# 🏁 Final Principle

👉 Smart Tracking = Distance + Speed + Time

👉 Run less, but intelligently
