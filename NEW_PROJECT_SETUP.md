# New Project Setup Guide

This guide will help you set up a new project using the provided templates.

## Step 1: Create a New Supabase Project

1. Go to [Supabase](https://supabase.com/) and sign in or create an account
2. Click "New Project" and fill in the details
3. Once created, go to Project Settings > API to get your:
   - Project URL
   - anon/public key

## Step 2: Set Up Database

1. In your Supabase project, go to the SQL Editor
2. Copy the contents of `new_project_setup.sql`
3. Paste and run the SQL to create all tables and policies

## Step 3: Create Storage Buckets

1. Go to Storage in your Supabase dashboard
2. Create the following buckets:
   - `avatars` - For user profile pictures
   - `properties` - For property images

## Step 4: Set Up Flutter Project

1. Create a new Flutter project:
   ```
   flutter create your_project_name
   cd your_project_name
   ```

2. Add required dependencies to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     supabase_flutter: ^1.10.25
     get: ^4.6.6
     lottie: ^2.7.0
     http: ^1.1.0
     path_provider: ^2.1.1
     image_picker: ^1.0.4
     google_fonts: ^6.1.0
   ```

3. Run:
   ```
   flutter pub get
   ```

## Step 5: Configure Project Files

1. Copy `new_project_main.dart` to your project's `lib/main.dart`
2. Replace the following placeholders:
   - `YOUR_SUPABASE_URL_HERE` with your Supabase project URL
   - `YOUR_SUPABASE_ANON_KEY_HERE` with your Supabase anon key
   - `YOUR_BUCKET_NAME` with your bucket names (e.g., 'avatars', 'properties')

3. Create the necessary screen files in `lib/screens/`:
   - `login_screen.dart`
   - `home_screen.dart`
   - `profile_screen.dart`
   - etc.

4. Update the imports in `main.dart` to point to your screen files

## Step 6: Test the Setup

1. Run the app:
   ```
   flutter run
   ```

2. Verify that:
   - The app connects to Supabase
   - You can sign up/login
   - You can view and create properties
   - Images can be uploaded and displayed

## Troubleshooting

### Database Connection Issues
- Verify your Supabase URL and anon key are correct
- Check that all tables were created successfully
- Ensure RLS policies are properly set up

### Storage Issues
- Verify bucket names match what's in your code
- Check bucket permissions in Supabase dashboard
- Ensure proper CORS settings for your domain

### Authentication Issues
- Verify email provider is enabled in Supabase
- Check that user profiles are being created
- Ensure proper redirect URLs are set

## Next Steps

1. Customize the UI to match your brand
2. Add additional features specific to your project
3. Implement proper error handling
4. Add analytics and monitoring
5. Set up CI/CD for your project 