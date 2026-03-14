# StudySync

> POV: You were absent from school, ask friends for notes on WhatsApp, and suddenly 1,000+ images flood your chat. You have to open each image just to find the topic. Later in the year, exams hit, and you have to scroll through 10,000 messages to find them again. Pure pain.
>
> **StudySync fixes this.**

Chat with your study group, request notes by subject and topic, and your whole group gets notified instantly. Whoever has them sends tagged, organized notes directly in chat. Every note is saved in the Notes Manager, sorted by subject or topic, searchable anytime. Add friends, create study groups, never lose a note again. Study smart and stay in sync.


---


## What is StudySync

Studysync is a commmunication app built specifically for students.It works like a messaging app but with one key difference. Every note that gets shared is automatically tagged and organized in notes manager. You never have to hunt for anything again.you can also request for notes and the whole group gets notified. if someone has the notes they can send it tagged by subject and topic name.
The notes manager tab is where you can see all the notes sent (by anyone) in past and filter or sort it by subject or topic

---



## Features

**Notes Request System**
When you need notes for a specific topic, you tap one button, enter the subject and topic name, and every member of your group gets a notification card.

**Tagged Note Sending**
When sending notes, you pick images from your gallery or camera, tag them with a subject and topic, arrange the page order , and send. The notes appear in chat as a structured card, not a pile of loose images.

**Notes Manager**
A dedicated tab that collects every note ever shared in all groups. Notes are grouped by subject. You can filter/sort by subject or topic using at the top or search by topic/subject name. Tap any note to open the full viewer.

**Note Viewer**
Swipe through pages of a note one by one. Pinch to zoom in on any page. nothing new

**Friends and Groups**
Search for other users by username, send a friend request, and once accepted you can add them to study groups.

**Regular Chat**
Beyond notes, you can chat...like whatsapp.

---

## Inspiration
I am currently in 10th grade, last year of school was like a trailer of 10th. even if i was absent for 1 day the teachers would give so many notes (only when im absent 😭, /joke). so i had to ask my friends on whatsapp for notes. my phone's storage was filled with 10gb of images of notes. it was impossible to find any notes when my finals arrived. it was a headache to find notes. so after my exams were over i made a app addressing this specific issue in android studio, but that attempt was terrible. the app kept crashing easily. text was glitching and the ui was like 2008. so i dropped the project midway. then i came to know about flutter flow. i learnt flutter flow and now its my second attempt at making this app. i hope this turns out great. this app would solve my current biggest problem. 

---

# NOTE
i havent added email confirmation yet. i think i will turn back to only username nd passowrd, and if i dont, i will add guest login

---

## How to Try It


### Option 1 — Try in Browser
No install needed. Opens on any device  phone, tablet, or PC.

[![Try in Browser](https://img.shields.io/badge/Try%20in%20Browser-%235C6BC0?style=for-the-badge&logo=googlechrome&logoColor=white)](https://studysync-web.netlify.app/)



---

### Option 2 — Android APK

[![Download APK](https://img.shields.io/badge/Download%20APK-%233DDC84?style=for-the-badge&logo=android&logoColor=white)](https://studysync-apk.short.gy/tivrqH)

1. Download the APK file
2. Open it, Android will ask to allow installation from unknown sources, tap Allow
3. Install, open.

---

### Option 3 — Windows

[![Download for Windows](https://img.shields.io/badge/Download%20for%20Windows-%230078D4?style=for-the-badge&logo=windows&logoColor=white)](https://studysync-apk.short.gy/UhNXnd)

1. Download and run the installer
2. install it (dw it takes 30mb and like 10 sec to install, just spam next)
3. search for study sync in search bar or open desktop shorcut


---

## Platform Availability

| Platform | Status |
|---|---|
| Android | Available |
| Web (Browser) | Available |
| Windows | Available |
| macOS | coming soon |
| Linux | coming soon |
| iOS | coming soon |

---

## Technologies Used

| Feature | Technology |
|---|---|
| App Framework | Flutter (Dart) |
| Backend and Auth | Supabase |
| Image Storage | Cloudinary |
| State Management | Provider |
| Real-time Messaging | Supabase Realtime |

---

## Project Status


| Version | Feature | Status |
|:---:|:---|:---:|
| v0.1 | Login and Register | Done |
| v0.2 | Home Screen | Done |
| v0.3 | Groups + Create Group | Done |
| v0.4 | Friends Screen | Done |
| v0.5 | Chat Screen | In Progress |
| v0.6 | Request Notes | Upcoming |
| v0.7 | Send Notes | Upcoming |
| v0.8 | Notes Manager | Upcoming |
| v0.9 | Note Viewer | Upcoming |

---

## Run Locally

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/studysync.git
cd studysync

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on Android
flutter run

# Run on Windows
flutter run -d windows

```

You will need to add your own credentials in:
- `lib/supabase_config.dart` — your Supabase URL and anon key
- `lib/services/cloudinary_service.dart` — your Cloudinary cloud name and upload preset

---

## Build Commands

| Platform | Command | Output Location |
|---|---|---|
| Android APK | `flutter build apk ` | `build/app/outputs/flutter-apk/app-release.apk` |
| Web | `flutter build web` | `build/web/` |
| Windows | `flutter build windows` | `build/windows/x64/runner/Release/` |


---

*Built by a student, for students.*
