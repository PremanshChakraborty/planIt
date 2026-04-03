<p align="center">
  <img src="frontend/assets/images/planit-high-resolution-logo-transparent.png" alt="PlanIt Logo" width="320"/>
</p>

[![Flutter](https://img.shields.io/badge/Flutter-3.0-blue?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18.x-green?logo=node.js)](https://nodejs.org)
[![Express](https://img.shields.io/badge/Express.js-4.x-black?logo=express)](https://expressjs.com)
[![MongoDB](https://img.shields.io/badge/MongoDB-6.x-brightgreen?logo=mongodb)](https://mongodb.com)
[![AWS](https://img.shields.io/badge/AWS-EC2%20|%20SNS%20|%20Lambda-FF9900?logo=amazonwebservices)](https://aws.amazon.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://www.docker.com/)
[![Android](https://img.shields.io/badge/Platform-Android-green?logo=android)](https://android.com)
[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📑 Contents

- [Overview](#️-overview)
- [Download](#-download)
- [Tech Stack](#️-tech-stack)
- [Features](#-features)
- [APIs & Services](#-apis--services)
- [Screenshots](#️-screenshots)
- [Architecture](#️-architecture)
- [Contact](#-contact)

---

## 🗺️ Overview

**PlanIt** is a playground for trip planning that replaces exhausting discussions with friends and family with a multistage structured and interactive process.

I developed this app in 2 sprints. the first sprint had the vision of combining all travel related services into a single app which was only partially successful. the second spromt was focused more on unique features useful for trip planning that are not offered anywhere else. The two sprints were 6 months apart, so naturally threres the big jump in terms of quality of code and complexity of features.

the first sprint included:

- user authentication
- trip locations management (CRUD and reordering)
- attraction/hotel discovery and saving.
- A general map page to view and search for places.

the second sprint included 3 major features:

- Collaboration features governed by RBAC rules. managing locations, attractions and dayplans.
- Multiscale map visualisation of whole trip for high level planning refinement.
- DAYPLANNER: A feature to plan daywise itinerary for each location using saved attractions and hotels through drag and drop sequencing with live route calculation and visualisation with aggregate and leg wise metrics. Also a automatic suggestion of the most optimal sequence using the current set powered by Google Directions API.

I ended the 2nd Sprint with a cloud backend development on aws with the following features:

- Serverless event based push notifications and audit trail using Amazon SNS Lambda and Firebase FCM tokens.
- Custom Nginx reverse proxy with manual HTTPS setup using Let's Encrypt SSL certificates and API response caching.
- Other AWS Native security and analytics features like Cloudwatch, Security groups, etc.

Download the app and create your first trip!

---

## 📥 Download

<p align="center">
  <a href="https://github.com/PremanshChakraborty/planIt/releases/tag/v1.0.0" target="_blank">
    <img src="https://img.shields.io/badge/Download%20APK-PlanIt-blueviolet?logo=android&logoColor=white&style=for-the-badge" alt="Download PlanIt APK"/>
  </a>
</p>

---

## 🛠️ Tech Stack

[![Flutter](https://img.shields.io/badge/Flutter-3.0-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0-blue?logo=dart)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18.x-green?logo=node.js)](https://nodejs.org)
[![Express](https://img.shields.io/badge/Express.js-4.x-black?logo=express)](https://expressjs.com)
[![MongoDB](https://img.shields.io/badge/MongoDB-6.x-brightgreen?logo=mongodb)](https://mongodb.com)
[![AWS](https://img.shields.io/badge/AWS-EC2%20|%20SNS%20|%20Lambda-FF9900?logo=amazonwebservices)](https://aws.amazon.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://www.docker.com/)
[![Android](https://img.shields.io/badge/Platform-Android-green?logo=android)](https://android.com)

| Layer                  | Technologies                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Frontend**           | Flutter (Dart), Provider state management, Google Maps SDK, Material 3                      |
| **Backend**            | Node.js (Express), MongoDB (Mongoose), JWT Auth, Joi Validation, Winston logging            |
| **Cloud Services**     | Google Places API, Google Routes API, Tripadvisor API (RapidAPI), Cloudinary (image upload) |
| **AWS Infrastructure** | EC2, SNS, Lambda, CloudWatch, Security Groups                                               |
| **DevOps**             | Docker Compose, GitHub Actions CI/CD, Nginx reverse proxy, Let's Encrypt SSL                |
| **Notifications**      | Amazon SNS → Lambda → MongoDB (event-driven audit trail), Firebase FCM (push)               |

---

## ✨ Features

### Sprint 1 — Core Trip Planning

- 🔐 **User Authentication:** Secure signup/login with JWT auth, OTP-based email verification via Nodemailer, and password reset flow.
- 🗂️ **Trip Management:** Create multi-location trips with start dates, guest counts, and budgets. Full CRUD operations with drag-and-drop location reordering.
- 🏨 **Hotel Discovery:** Search and save hotels per location via Tripadvisor API with pricing, ratings, and images.
- 🎯 **Attraction Discovery:** Explore nearby attractions per location via Google Places API, save favourites with type, rating, and geo-coordinates.
- 🗺️ **General Map Page:** A standalone map page to search and explore any place on Google Maps with autocomplete.
- 📅 **My Trips Dashboard:** View, manage, and revisit all your trips in one place.
- 👤 **User Profile:** Update personal info and upload profile photos via Cloudinary with signed uploads.
- 🆘 **Safety & Emergency Tools:**
  - 🚨 **SOS Button:** Instantly send your location to emergency contacts and call local authorities via device telephony.
  - 📇 **Emergency Contacts:** Add, manage, and quickly reach your trusted contacts.
  - 🛡️ **Safety Settings:** Centralized hub accessible from each trip.

---

### Sprint 2 — Collaboration, DayPlanner & Cloud Infrastructure

#### 🤝 Real-Time Collaboration with RBAC

Trip planning is a group activity. PlanIt supports inviting collaborators to any trip, governed by **Role-Based Access Control (RBAC)** enforced through custom Express middleware:

- **Trip Owner** — Full control: manage locations, attractions, hotels, day plans. Can add/remove collaborators, star/unstar day plans, and delete any day plan.
- **Collaborator** — Can add locations, attractions, hotels, and create their own day plans. Cannot modify other collaborators' plans or manage the collaborator list.

User search allows finding registered users by name to invite. All collaborator mutations publish events to Amazon SNS for downstream notification processing.

#### 📆 DayPlanner — Itinerary Builder with Route Optimization

The standout feature of Sprint 2. For each trip location, users can create **day-wise itinerary plans** combining saved attractions and hotels:

- **Drag & Drop Sequencing** — Arrange plan blocks (attractions/hotels) in any order for the day.
- **Live Route Calculation** — Routes are computed via the **Google Routes API** (Directions v2) with encoded polyline rendering on the map.
- **Leg-wise Metrics** — Each leg between stops displays distance and duration. Aggregate trip summary shows total distance, total time, and travel mode.
- **Multi-mode Travel** — Switch between driving, walking, and two-wheeler modes with instant route recalculation.
- **Optimal Sequence Suggestion** — One-tap optimization that uses Google's waypoint optimization (`optimizeWaypointOrder`) to suggest the most efficient visiting order for the current set of stops.
- **Save or Fork** — Save the optimized sequence in-place or as a new copy. Only the plan creator can edit; the trip owner can star the best plan.
- **Interactive Map View** — Tapping a plan block marker opens a detailed place info dialog powered by Google Places details API.

#### 🗺️ Multiscale Map Visualization

The Trip Details page features a **full-screen Google Map** with a draggable bottom sheet, providing multiscale spatial context:

- **Trip-level overview** — All locations plotted with numbered custom markers. The camera auto-fits bounds to show the entire trip geography.
- **Location-level drill-down** — Tapping a location marker or card zooms into that location, revealing its saved hotels (🏨) and attractions (📍) as additional markers.
- **Map ↔ List sync** — Tapping a marker scrolls the bottom sheet to the corresponding location card and vice versa. Selection state is synchronized across map and list.
- **Custom map styles** — Separate light and dark JSON style configs for Google Maps that match the app theme.

#### 🔔 Serverless Event-Driven Notifications

Collaboration events trigger a fully serverless notification pipeline:

1. **Backend publishes** a structured event (e.g. `COLLABORATOR_ADDED`) to an **Amazon SNS** topic via the AWS SDK.
2. **AWS Lambda** (subscribed to the SNS topic) processes the event, fans out notifications to all trip participants, and inserts notification documents into **MongoDB**.
3. **Frontend** fetches paginated notifications from a dedicated `/api/notifications` endpoint with read/unread state.

This architecture decouples the notification logic from the main API server, ensuring non-blocking request handling and providing an audit trail of all collaboration events.

#### ☁️ AWS Cloud Backend & DevOps

The second sprint concluded with a production cloud deployment:

- **CI/CD Pipeline** — GitHub Actions workflow triggers on push to `main` (backend path). Builds a Docker image, pushes to DockerHub, then SSH-deploys to EC2 via `docker compose pull && up`.
- **Nginx Reverse Proxy** — Custom Nginx configuration on EC2 with manual HTTPS setup using **Let's Encrypt** SSL certificates and API response caching.
- **AWS Security** — EC2 Security Groups restricting inbound traffic, CloudWatch monitoring for logs and metrics.
- **Containerized Deployment** — Docker Compose orchestrating the Node.js backend on EC2 with environment-based configuration.

---

## 🌐 APIs & Services

| Service                                                                                           | Usage                                                                             |
| ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| [Google Places API](https://developers.google.com/maps/documentation/places/web-service/overview) | Place search, autocomplete, place details, and photos                             |
| [Google Routes API](https://developers.google.com/maps/documentation/routes)                      | Route computation with waypoint optimization, polyline encoding, leg-wise metrics |
| [Google Maps SDK (Flutter)](https://pub.dev/packages/google_maps_flutter)                         | Interactive map rendering, custom markers, polyline overlays, camera animations   |
| [Tripadvisor API (RapidAPI)](https://rapidapi.com/apidojo/api/tripadvisor-com)                    | Hotel search and pricing data                                                     |
| [Cloudinary](https://cloudinary.com/)                                                             | Signed image uploads for user profile photos                                      |
| [Amazon SNS](https://aws.amazon.com/sns/)                                                         | Event publishing for collaboration actions                                        |
| [AWS Lambda](https://aws.amazon.com/lambda/)                                                      | Serverless notification fan-out and MongoDB persistence                           |
| Gmail SMTP (Nodemailer)                                                                           | OTP email verification and password reset                                         |
| Device Telephony/SMS                                                                              | Native emergency calling and SMS via device APIs                                  |

---

## 🖼️ Screenshots

### 🧭 Day Planner

<table><tr>
<td><img src="screenshots/dayplan.jpg" width="220"/></td>
<td><img src="screenshots/create_dayplan.jpg" width="220"/></td>
<td><img src="screenshots/dayplan_map.jpg" width="220"/></td>
</tr></table>

### 🏨 Trip Planning Flow

<table><tr>
<td><img src="screenshots/home.jpg" width="220"/></td>
<td><img src="screenshots/my trips.jpg" width="220"/></td>
<td><img src="screenshots/trip_details.jpg" width="220"/></td>
<td><img src="screenshots/trip_details_map.jpg" width="220"/></td>
</tr></table>

### 🗺️ Collaboration

<table><tr>
<td><img src="screenshots/collaborators.jpg" width="220"/></td>
<td><img src="screenshots/collaborators_add.jpg" width="220"/></td>
</tr></table>

### 🤝 Attractions, Maps & Profile

<table><tr>
<td><img src="screenshots/attractions.jpg" width="220"/></td>
<td><img src="screenshots/map.jpg" width="220"/></td>
<td><img src="screenshots/profile.jpg" width="220"/></td>
</tr></table>

---

## 🏗️ Architecture

```
┌─────────────┐       ┌──────────────────┐       ┌─────────────┐
│  Flutter App │◄─────►│  Express API     │◄─────►│  MongoDB    │
│  (Android)   │ REST  │  (Node.js)       │       │  Atlas      │
└─────────────┘       └────────┬─────────┘       └─────────────┘
                               │
                        publish │ SNS
                               ▼
                      ┌─────────────────┐
                      │  Amazon SNS     │
                      │  Topic          │
                      └────────┬────────┘
                               │ subscribe
                               ▼
                      ┌─────────────────┐       ┌─────────────┐
                      │  AWS Lambda     │──────►│  MongoDB    │
                      │  (Notification) │ write  │  (notifs)   │
                      └─────────────────┘       └─────────────┘

─── Deployment ───
GitHub Actions → DockerHub → EC2 (Docker Compose)
Nginx reverse proxy + Let's Encrypt HTTPS
Cloudinary (profile image CDN)
```

---

## 📞 Contact

- 📱 **Phone:** +91 8260094077
- 📧 **Email:** premansh_ug_23@cse.nits.ac.in
- 💻 **GitHub:** [premansh29](https://github.com/PremanshChakraborty)

Feel free to reach out for feedback, suggestions, or support!
