# Real Estate App - Architecture Overview

## Clean Architecture Implementation

This application follows the Clean Architecture pattern with a layered approach:

```
UI (Presentation) → Controller → Use Cases → Repository → Data Sources
```

### 1. Data Flow During User Authentication

#### Signup Process:
1. **UI Layer (SignupScreen):**
   - User enters full name, phone number, email, password
   - Validates input fields
   - Calls `_authController.signUp()`

2. **Controller Layer (AuthController):**
   - Sets loading state
   - Calls `signUpUseCase.execute()`
   - Handles success/error states
   - Shows appropriate messages

3. **Use Case Layer (SignUpUseCase):**
   - Single responsibility: execute the signup business logic
   - Calls `repository.signUp()`

4. **Repository Layer (AuthRepositoryImpl):**
   - Implements interface defined in domain layer
   - Calls Supabase Auth API to create user
   - Stores additional user data in 'profiles' table
   - Returns UserEntity on success

5. **Data Source (Supabase):**
   - Auth service creates user in auth.users table
   - Database service stores profile in profiles table

#### Why This Works:
- **Separation of Concerns:** Each layer has a specific responsibility
- **Testability:** Each component can be tested in isolation
- **Data Integrity:** Supabase transactions ensure data is consistent

### 2. Login Process:
1. **UI Layer (LoginScreen):**
   - User enters email, password
   - Validates input fields
   - Calls `_authController.signIn()`

2. **Controller → Use Case → Repository → Data Source**
   - Similar flow to signup
   - Retrieves user profile after authentication

### 3. Supabase Database Schema for Authentication

#### Auth Tables (Managed by Supabase):
- `auth.users`: Managed by Supabase Auth service
  - Stores email, hashed password, etc.

#### Custom Tables:
- `profiles`: 
  - Links to auth.users via ID
  - Stores additional user information
  - Referenced by properties and other tables

### 4. Error Handling Strategy

1. **Repository Layer:**
   - Catches API errors
   - Transforms into domain-specific exceptions
   - Includes meaningful error messages

2. **Controller Layer:**
   - Presents user-friendly error messages
   - Manages loading states

### 5. Performance Considerations

1. **GetX State Management:**
   - Reactive programming approach
   - Only rebuilds necessary widgets
   - Efficient dependency injection

2. **Lazy Loading:**
   - Dependencies are loaded only when needed
   - Use of the 'fenix' parameter keeps singletons alive

3. **Proper Disposal:**
   - Controllers dispose resources when not needed
   - Prevents memory leaks

## Testing This Architecture

### Manual Testing Steps for Signup:
1. Enter a valid email/password/name on signup screen
2. Check that data is saved in both Supabase Auth and profiles table
3. Verify that you can login with the created credentials
4. Check that profile data is correctly retrieved after login

### Error Cases to Test:
1. Invalid email format
2. Password too short
3. Email already in use
4. Network failure

## Key Benefits

1. **Maintainability:** Clear separation makes code easier to maintain
2. **Testability:** Each layer can be unit tested independently
3. **Flexibility:** Can swap implementations (e.g., replace Supabase with Firebase) with minimal changes
4. **Scalability:** New features can be added without modifying existing code 

lib/
  ├── core/            # Core functionality, constants, utilities
  │   ├── config/      # App configuration
  │   ├── utils/       # Utility functions
  │   └── theme/       # App theme data
  ├── data/            # Data layer
  │   ├── models/      # Data models
  │   ├── providers/   # Data providers/services
  │   └── repositories/ # Repository implementations
  ├── screens/         # UI screens
  ├── widgets/         # Reusable widgets
  ├── controllers/     # Business logic controllers
  └── main.dart        # Entry point 