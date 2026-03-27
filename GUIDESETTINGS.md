# FateLink - Development Setup Guide

This guide provides instructions for setting up the FateLink project for local development.

## Prerequisites

*   [Node.js](https://nodejs.org/) (v16 or higher)
*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   [MongoDB](https://www.mongodb.com/docs/manual/installation/)
*   [Firebase Project](https://console.firebase.google.com/)

## Backend Setup (fatelink-be)

1.  Navigate to the `fatelink-be` directory: `cd fatelink-be`
2.  Install dependencies: `npm install`
3.  Configure environment variables:
    *   Create a `.env` file in the root of the `fatelink-be` directory.
    *   Add the following variables:
        ```
        MONGODB_URI=your_mongodb_connection_string
        FIREBASE_PROJECT_ID=your_firebase_project_id
        ```
4.  Run the backend: `npm run start:dev`

## Frontend Setup (fatelink-fe)

1.  Navigate to the `fatelink-fe` directory: `cd fatelink-fe`
2.  Run `flutter pub get`