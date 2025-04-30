# Supabase Setup Guide for Real Estate App

This guide explains how to set up the necessary Supabase tables and configurations to make the app work correctly, especially the authentication features.

## Prerequisites

1. A Supabase account
2. Access to your Supabase project dashboard

## 1. Setting Up the Profiles Table

The profiles table is essential for storing additional user information beyond what Supabase Auth provides.

### Step 1: Open SQL Editor
Navigate to the SQL Editor in your Supabase dashboard.

### Step 2: Create Profiles Table
Execute the following SQL:

```sql
-- Create profiles table
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone_number TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Set up Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policy for viewing profiles
CREATE POLICY "Users can view their own profile" 
  ON profiles FOR SELECT 
  USING (auth.uid() = id);

-- Create policy for updating profiles
CREATE POLICY "Users can update their own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = id);

-- Create policy for inserting profiles (needed for signup)
CREATE POLICY "Users can insert their own profile" 
  ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);
```

## 2. Configure Auth Settings in Supabase

To make sure authentication works properly, you need to configure some settings in Supabase.

### Step 1: Configure Email Auth
1. Go to Authentication > Providers in your Supabase dashboard
2. Make sure "Email" is enabled
3. Decide whether to enable "Confirm email" based on your needs:
   - If enabled: Users will need to confirm their email after signup
   - If disabled: Users can use their account immediately after signup

### Step 2: Configure Password Reset
1. Go to Authentication > Email Templates
2. Customize the "Password Reset" email template as needed

### Step 3: Configure Redirect URLs
1. Go to Authentication > URL Configuration
2. Add appropriate redirect URLs for your app's environment:
   - For development: `http://localhost:3000/*`
   - For production: Add your production URL

## 3. Testing Signup Flow

Once your Supabase project is configured correctly, you can test the signup flow:

1. Launch your app
2. Navigate to the Signup screen
3. Fill in all required fields
4. Submit the form

### Verification Steps:
1. Check the Supabase Authentication > Users page to see if the user was created
2. Execute this SQL query to check if the profile was created:
   ```sql
   SELECT * FROM profiles ORDER BY created_at DESC LIMIT 5;
   ```
3. Try logging in with the credentials you created

## 4. Troubleshooting

### User created but profile missing:
- Check repository implementation in `auth_repository_impl.dart`
- Verify that both auth signup and profile creation are in the same try/catch block
- Ensure profile insertion uses the correct user ID

### Error during signup:
- Check browser console for detailed error messages
- Verify that `profiles` table has the correct structure
- Ensure Row Level Security policies allow the insertion

## 5. Common Issues and Solutions

### Issue: "Foreign key violation" error
- **Problem**: The profile insert is attempting to use an ID that doesn't exist in auth.users
- **Solution**: Ensure you're using the ID from the auth response

### Issue: "Permission denied" error
- **Problem**: RLS policies are blocking the insert operation
- **Solution**: Check your RLS policies and make sure there's one that allows users to insert their own profile

### Issue: Profile created but can't query it later
- **Problem**: SELECT RLS policy might be too restrictive
- **Solution**: Verify the SELECT policy allows users to retrieve their own profile 