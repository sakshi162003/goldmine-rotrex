# Real Estate App - Screen Flow Documentation

## Authentication Screens

### 1. SplashScreen
**Purpose:** Entry point of the application, shows loading animation before redirecting.

**Behavior:**
- Displays a Lottie animation for 3 seconds
- Automatically navigates to LoginScreen after animation
- No user interaction required

**Technical Details:**
- Uses `Future.delayed()` to navigate after a set time
- Uses GetX navigation (`Get.offNamed('/login')`) for screen transition
- Stateful widget with simple UI

### 2. LoginScreen
**Purpose:** Allows existing users to authenticate with the app.

**Components:**
- Email field with validation
- Password field with validation and toggle visibility
- Forgot Password link
- Login button with loading state
- Google Sign-in option
- Register link for new users

**Data Flow:**
1. User enters credentials
2. Form validation checks fields
3. On submit, `_handleLogin()` is called
4. `AuthController.signIn()` processes the request
5. On success: Navigate to HomeScreen
6. On error: Display error message

**Technical Details:**
- Uses `TextFormField` with validators
- Uses Obx from GetX for reactive UI updates
- GetX navigation for screen transitions

### 3. SignupScreen
**Purpose:** Allows new users to create an account.

**Components:**
- Full Name field
- Phone Number field
- Email field with validation
- Password field with validation and toggle visibility
- Confirm Password field with matching validation
- Register button with loading state
- Login link for existing users

**Data Flow:**
1. User fills all fields
2. Form validation checks fields and password match
3. On submit, `_handleSignup()` is called
4. `AuthController.signUp()` processes the request
5. Backend creates user in Supabase auth system
6. Backend creates profile record in 'profiles' table
7. On success: Navigate to EmailVerificationScreen
8. On error: Display error message

**Technical Details:**
- Uses layered architecture for clean separation
- Stores user data in both auth.users and profiles tables
- Uses Obx from GetX for reactive UI (loading state)

### 4. ForgotPasswordScreen
**Purpose:** Allows users to reset their password via email.

**Components:**
- Email field with validation
- Send Reset Link button with loading state
- Back button to return to login

**Data Flow:**
1. User enters email address
2. Form validation checks email format
3. On submit, `_requestPasswordReset()` is called
4. `AuthController.resetPassword()` processes the request
5. Supabase sends password reset email
6. On success: Show success dialog and return to login
7. On error: Show error dialog

**Technical Details:**
- Simple form with single email field
- Uses Supabase's `resetPasswordForEmail` API
- Shows modal dialog to confirm action

### 5. EmailVerificationScreen
**Purpose:** Informs user to check their email after signup.

**Components:**
- Informational message
- Animation/illustration
- Return to Login button

**Data Flow:**
- Static screen shown after signup
- User directed to check email and verify account
- User can return to login screen

## Main App Screens

### 1. HomeScreen
**Purpose:** Main landing page after authentication, shows property listings.

**Components:**
- Property listings (Featured, Nearby, etc.)
- Search bar
- Navigation menu
- Property cards

**Data Flow:**
1. Screen loads and fetches properties from Supabase
2. Properties displayed in different categories
3. User can tap property to view details
4. User can search or filter properties

### 2. PropertyDetailScreen
**Purpose:** Shows detailed information about a selected property.

**Components:**
- Property images gallery
- Property details (price, bedrooms, etc.)
- Amenities list
- Description
- Contact button
- Favorite button

**Data Flow:**
1. Receives property ID as parameter
2. Fetches complete property details from Supabase
3. Displays information in organized sections
4. User can perform actions (favorite, contact agent)

### 3. SearchScreen
**Purpose:** Allows users to search and filter properties.

**Components:**
- Search input
- Filter options (price range, bedrooms, etc.)
- Results list
- Sort options

**Data Flow:**
1. User enters search criteria
2. Queries Supabase database with filters
3. Results displayed in scrollable list
4. User can refine search or select property

### 4. ProfileScreen
**Purpose:** Shows user profile information and settings.

**Components:**
- User information
- Settings options
- Favorite properties
- Logout button

**Data Flow:**
1. Fetches current user data from AuthController
2. Displays user information
3. Provides options to edit profile, view favorites, etc.
4. Logout functionality clears session

## Data Storage in Supabase

### Authentication Data:
- User credentials stored in Supabase Auth system
- Profile data stored in 'profiles' table
- JWT tokens used for session management

### Property Data:
- Properties stored in 'properties' table
- Images in 'property_images' table
- Amenities in 'property_amenities' table

### User Interactions:
- Favorites stored in 'favorites' table (many-to-many)
- Contact inquiries stored in 'contact_queries' table

## Benefits of the Current Implementation

1. **Clean Architecture:**
   - Separation of UI, business logic, and data access
   - Easy to test and maintain

2. **Reactive UI:**
   - GetX provides reactive state management
   - UI updates automatically based on state changes

3. **Performance:**
   - Lazy loading of dependencies
   - Efficient widget rebuilds
   - Resource cleanup on screen disposal 