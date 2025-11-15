Flutter FLUTTER_APP with Back4App

This guide will walk you through setting up and running the provided Flutter code for a complete CRUD (Create, Read, Update, Delete) Task Manager application using Back4App as your Backend-as-a-Service (BaaS).

Features

User Authentication (Registration, Login, Logout)

Full CRUD operations on Tasks

Real-Time Database Syncing using Back4App Live Queries

Secure, persistent user sessions

Technology Stack

Frontend: Flutter (Dart)

Backend: Back4App (Parse Server)

Step 1: Set Up Your Back4App Backend (Critical!)

Before you can run the Flutter code, your backend database must exist.

Create Your Back4App Account: Go to Back4App and sign up for a free account.

Create a New App:

On your dashboard, click "Build a new app".

Select "Backend as a Service (BaaS)".

Give your app a name (e.g., "StudentApp") and create it.

Find Your App Keys:

Once your app is created, go to "App Settings" > "Security & Keys".

You will need three values:

Application ID

Client Key

Server URL (This is under "Server Settings" > "Core Settings" > "Server URL")

Keep these keys safe. You will add them to your main.dart file.

Create the Task Database Class:

Go to your Back4App Dashboard and click "Database" > "Create a new class".

Name the class Task and create it.

Your Task class needs the following columns (fields):

title (Type: String)

description (Type: String)

isDone (Type: Boolean)

user (Type: Pointer, Target Class: _User) - This is for security! It links the task to the user who created it.

Set Class-Level Permissions (CLPs):

While viewing your Task class, click the "Security" button (CLPs).

This is vital for ensuring users can only see and edit their own tasks.

Set the permissions as follows:

Authenticated: Create, Read

pointer-field (user): Read, Update, Delete

This means any logged-in user can create a task, but only the user in the user pointer field can read, update, or delete it.

Enable Live Queries:

In your Back4App dashboard, find "Live Query" in the sidebar.

Make sure Live Query is activated for your app.

In the "Task" class, ensure Live Query is enabled.

Step 2: Set Up Your Flutter Project

Create a New Flutter App:

flutter create task_manager
cd flutter_app


Add Dependencies:

Open the pubspec.yaml file.

Copy the content from the pubspec.yaml file I provided and paste it into yours.

Get Dependencies:

Run flutter pub get in your terminal.

Step 3: Add the App Code

Create the Files:

Inside your lib folder, create the following files:

auth_screen.dart

task_list_screen.dart

task_edit_screen.dart

Copy-Paste:

Copy the code from each of the .dart files (main.dart, auth_screen.dart, etc.) and paste it into the corresponding file in your project.

Add Your Back4App Keys:

Open lib/main.dart.

Find the Parse().initialize block.

Replace the placeholder strings ('YOUR_APP_ID', 'YOUR_SERVER_URL', 'YOUR_CLIENT_KEY') with the actual keys you got in Step 1.

Step 4: Run Your App

You are all set! Connect a device or start an emulator and run your app:

flutter run


You should now be able. to:

Register for a new account.

Log in and be taken to the task list.

Log out and be returned to the login screen.

Create, edit, and delete tasks.

Open the app on two devices (or the emulator + your Back4App database) and see tasks update in real-time.