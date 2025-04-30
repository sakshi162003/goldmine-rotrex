-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Profiles Table
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone_number TEXT,
    avatar_url TEXT,
    role TEXT DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Properties Table
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL NOT NULL,
    property_type TEXT NOT NULL,
    listing_type TEXT NOT NULL,
    bedrooms INTEGER,
    bathrooms INTEGER,
    area DECIMAL,
    city TEXT,
    state TEXT,
    address TEXT,
    latitude DECIMAL,
    longitude DECIMAL,
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Property Images Table
CREATE TABLE property_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Favorites Table
CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, property_id)
);

-- 5. Property Inquiries Table
CREATE TABLE property_inquiries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    property_id UUID REFERENCES properties(id),
    inquiry_type TEXT NOT NULL,
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_inquiries ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- Properties Policies
CREATE POLICY "Anyone can view active properties"
ON properties FOR SELECT
USING (is_active = true);

CREATE POLICY "Only admins can manage properties"
ON properties FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'admin'
    )
);

-- Property Images Policies
CREATE POLICY "Anyone can view property images"
ON property_images FOR SELECT
USING (true);

CREATE POLICY "Only admins can manage property images"
ON property_images FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'admin'
    )
);

-- Favorites Policies
CREATE POLICY "Users can manage own favorites"
ON favorites FOR ALL
USING (auth.uid() = user_id);

-- Property Inquiries Policies
CREATE POLICY "Users can view own inquiries"
ON property_inquiries FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create inquiries"
ON property_inquiries FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Common Queries for Data Operations

-- Get user profile
-- SELECT * FROM profiles WHERE id = :user_id;

-- Update user profile
-- UPDATE profiles 
-- SET full_name = :full_name,
--     phone_number = :phone_number,
--     updated_at = CURRENT_TIMESTAMP
-- WHERE id = :user_id;

-- Get all active properties with first image
-- SELECT p.*, pi.image_url 
-- FROM properties p
-- LEFT JOIN property_images pi ON p.id = pi.property_id
-- WHERE p.is_active = true
-- ORDER BY p.created_at DESC;

-- Get property with all images
-- SELECT p.*, 
--        json_agg(json_build_object('id', pi.id, 'url', pi.image_url)) as images
-- FROM properties p
-- LEFT JOIN property_images pi ON p.id = pi.property_id
-- WHERE p.id = :property_id
-- GROUP BY p.id;

-- Search properties
-- SELECT p.*, pi.image_url
-- FROM properties p
-- LEFT JOIN property_images pi ON p.id = pi.property_id
-- WHERE 
--     p.city ILIKE :search_term OR
--     p.state ILIKE :search_term OR
--     p.title ILIKE :search_term
--     AND p.is_active = true;

-- Get user's favorites
-- SELECT p.*, pi.image_url, f.created_at as favorited_at
-- FROM favorites f
-- JOIN properties p ON f.property_id = p.id
-- LEFT JOIN property_images pi ON p.id = pi.property_id
-- WHERE f.user_id = :user_id
-- ORDER BY f.created_at DESC;

-- Add to favorites
-- INSERT INTO favorites (user_id, property_id)
-- VALUES (:user_id, :property_id);

-- Remove from favorites
-- DELETE FROM favorites 
-- WHERE user_id = :user_id AND property_id = :property_id;

-- Create indexes for better performance
CREATE INDEX idx_properties_is_active ON properties(is_active);
CREATE INDEX idx_properties_city ON properties(city);
CREATE INDEX idx_properties_state ON properties(state);
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_property_id ON favorites(property_id);
CREATE INDEX idx_property_inquiries_user_id ON property_inquiries(user_id);
CREATE INDEX idx_property_inquiries_property_id ON property_inquiries(property_id); 