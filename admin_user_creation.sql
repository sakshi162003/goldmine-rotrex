-- SQL Query to insert admin user into profiles table

-- First, ensure the user exists in auth.users table
-- Note: This part is normally handled by Supabase Auth API and not direct SQL
-- If you need to check existing users:
-- SELECT * FROM auth.users WHERE email = 'sahilbagal877@gmail.com';

-- Insert the admin user record into profiles table
-- If the admin user ID is known, use that ID in the query
INSERT INTO profiles (
  id,                 -- UUID matching auth.users ID
  full_name,          -- Admin user's name
  email,              -- Admin email
  phone_number,       -- Admin phone number
  avatar_url,         -- Optional avatar URL
  role,               -- Set as 'admin'
  is_active,          -- Set as active
  created_at,         -- Current timestamp
  updated_at          -- Current timestamp
)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'sahilbagal877@gmail.com'), -- Get ID from auth.users table
  'Admin User',       -- Admin name
  'sahilbagal877@gmail.com', -- Admin email
  '+91 9876543210',   -- Sample phone number
  NULL,               -- No avatar yet
  'admin',            -- Role set to admin
  TRUE,               -- Active account
  CURRENT_TIMESTAMP,  -- Created now
  CURRENT_TIMESTAMP   -- Updated now
)
ON CONFLICT (id) DO UPDATE 
SET 
  role = 'admin',
  updated_at = CURRENT_TIMESTAMP;

-- Alternative version if you don't have access to auth.users table
-- (Replace 'user-id-here' with the actual ID you get from logging in)
/*
INSERT INTO profiles (
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
  'user-id-here',
  'Admin User',
  'sahilbagal877@gmail.com',
  '+91 9876543210',
  'admin',
  TRUE,
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO UPDATE 
SET 
  role = 'admin',
  updated_at = CURRENT_TIMESTAMP;
*/

-- You can also try updating an existing profile if the user already exists
UPDATE profiles
SET 
  role = 'admin',
  updated_at = CURRENT_TIMESTAMP
WHERE email = 'sahilbagal877@gmail.com'; 