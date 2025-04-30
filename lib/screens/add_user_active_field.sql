-- Add is_active column to profiles table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE profiles ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
END
$$;

-- Set all existing users to active
UPDATE profiles SET is_active = TRUE WHERE is_active IS NULL;

-- Make sure updated_at field exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END
$$;

-- Update RLS policies to allow admin to manage users
-- First, let's create a function to check if a user is an admin
CREATE OR REPLACE FUNCTION is_admin() 
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if profile with admin role exists for current user
    RETURN EXISTS (
        SELECT 1
        FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add role column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'role'
    ) THEN
        ALTER TABLE profiles ADD COLUMN role TEXT DEFAULT 'user';
    END IF;
END
$$;

-- Update admin policy for viewing all profiles
DROP POLICY IF EXISTS "Admin can view all profiles" ON profiles;
CREATE POLICY "Admin can view all profiles" 
  ON profiles FOR SELECT 
  USING (is_admin() OR auth.uid() = id);

-- Update admin policy for updating any profile
DROP POLICY IF EXISTS "Admin can update any profile" ON profiles;
CREATE POLICY "Admin can update any profile" 
  ON profiles FOR UPDATE 
  USING (is_admin() OR auth.uid() = id);

-- Update admin policy for deleting any profile
DROP POLICY IF EXISTS "Admin can delete any profile" ON profiles;
CREATE POLICY "Admin can delete any profile" 
  ON profiles FOR DELETE 
  USING (is_admin()); 