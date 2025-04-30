-- Add missing INSERT policy for profiles table
-- This is critical for allowing users to create their profiles during registration

-- First, check if policy already exists to avoid errors
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND operation = 'INSERT'
        AND policyname = 'Users can insert their own profile'
    ) THEN
        -- Create the insert policy
        CREATE POLICY "Users can insert their own profile" 
          ON profiles FOR INSERT 
          WITH CHECK (auth.uid() = id);
          
        RAISE NOTICE 'Created INSERT policy for profiles table';
    ELSE
        RAISE NOTICE 'INSERT policy for profiles already exists';
    END IF;
END
$$;

-- Also create a temporary service role policy to fix existing profiles
-- This can be removed after fixing the profiles
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND operation = 'INSERT'
        AND policyname = 'Service role can create profiles'
    ) THEN
        -- Create temporary service role policy
        CREATE POLICY "Service role can create profiles" 
          ON profiles FOR INSERT 
          WITH CHECK (true);
          
        RAISE NOTICE 'Created temporary service role policy for profiles';
    ELSE
        RAISE NOTICE 'Service role policy already exists';
    END IF;
END
$$;

-- Create a function to check if a table has any rows
CREATE OR REPLACE FUNCTION table_has_rows(table_name text) RETURNS boolean AS $$
DECLARE
    row_count integer;
BEGIN
    EXECUTE format('SELECT COUNT(*) FROM %I', table_name) INTO row_count;
    RETURN row_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Write an info message about current state
DO $$
BEGIN
    IF table_has_rows('profiles') THEN
        RAISE NOTICE 'There are existing profile records in the database';
    ELSE
        RAISE NOTICE 'No profile records found in the database';
    END IF;
END
$$; 