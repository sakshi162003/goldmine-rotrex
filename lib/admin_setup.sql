-- Admin Setup SQL Script

-- First, create an admin user in the auth.users table if it doesn't exist
-- Note: In Supabase, we can't directly insert into auth.users table from SQL,
-- so this is provided as a reference for what needs to be done in the Supabase dashboard

-- 1. Go to Authentication > Users in Supabase dashboard
-- 2. Click "Add User" and create a user with:
--    Email: sahilbagal877@gmail.com
--    Password: Sahil@123

-- Instead, we'll set up the profiles table entry which will work if the user is created via the UI

-- Create admin entry in profiles table
INSERT INTO public.profiles (
  id,
  full_name,
  email,
  phone_number,
  role,
  is_active,
  created_at,
  updated_at
)
VALUES (
  -- Replace this with the actual UUID of the admin user after creating it in Authentication
  -- You can get this from the Supabase dashboard after creating the user
  '00000000-0000-0000-0000-000000000000',  -- Replace with actual UUID
  'Admin User',
  'sahilbagal877@gmail.com',
  '+91 9876543210',
  'admin',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) 
DO UPDATE SET
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  phone_number = EXCLUDED.phone_number,
  role = 'admin',
  is_active = true,
  updated_at = NOW();

-- Query to verify the admin user exists
-- SELECT * FROM profiles WHERE email = 'sahilbagal877@gmail.com'; 