# Expiry Date Checker & Medication Adherence Assistant

## Application Overview
A comprehensive medication management system with a Flask backend and Flutter frontend that helps users track their prescriptions and receive timely medication reminders.

## System Architecture

### Backend (Flask)
- **Database**: SQLite3
- **APIs**: RESTful endpoints
- **Authentication**: Basic authentication
- **Background Tasks**: Celery

### Frontend (Flutter)
- **State Management**: Basic setState
- **Local Storage**: SQLite
- **Notifications**: flutter_local_notifications
- **Platform Support**: Android, iOS

## Detailed Workflow

### 1. User Registration & Authentication

#### Registration Flow:
1. User opens app
2. Taps "Sign Up"
3. Enters:
   - Username
   - Password
   - Email
   - Phone number (optional)
   - Date of birth
   - Gender
4. Data validation:
   - Username uniqueness check
   - Password strength verification
   - Email format validation
5. Data sent to backend via POST request to `/register`
6. Backend:
   - Validates data
   - Hashes password
   - Creates user record
   - Returns success/failure response

#### Login Flow:
1. User enters credentials
2. Frontend sends POST request to `/login`
3. Backend:
   - Verifies credentials
   - Returns user data and prescriptions
4. Frontend:
   - Stores credentials securely
   - Navigates to Dashboard

### 2. Dashboard Screen

#### Layout:
1. **Profile Section**
   - User's name
   - Email
   - Profile picture placeholder
   - Edit button

2. **Quick Stats**
   - Total prescriptions
   - Completion rate
   - Upcoming reminders

3. **Personal Information**
   - Phone
   - Date of birth
   - Gender

4. **Prescription Cards**
   Each card shows:
   - Medicine name
   - Prescription ID
   - Frequency (times/day)
   - Recommended dosage
   - Side effects
   - Reminder settings button

### 3. Medication Reminder System

#### Setting Up Reminders
1. User taps "Set Reminder" on a prescription card
2. App shows ReminderTimesDialog:
   - Displays number of reminders based on frequency
   - Default times are equally spaced:
     - For frequency=1: 8:00 AM
     - For frequency=2: 8:00 AM, 8:00 PM
     - For frequency=3: 8:00 AM, 2:00 PM, 8:00 PM
     - For frequency=4: 8:00 AM, 12:00 PM, 4:00 PM, 8:00 PM

#### Custom Time Selection:
1. User can modify each reminder time:
   - Hour selector (1-12)
   - Minute selector (0-55, 5-minute intervals)
   - AM/PM toggle
2. Visual feedback:
   - Selected time highlighted
   - Smooth scrolling animation
   - Clear visual hierarchy

#### Reminder Storage & Management
1. When times are confirmed:
   - Cancels any existing notifications for this prescription
   - Creates new notification schedules
   - Stores in local notification system

#### Notification Handling
1. When notification triggers:
   - Shows medication name
   - Time of dose
   - Uses high-priority channel
   - Plays sound and vibrates
   - Shows even if app is closed

### 4. Backend Services

#### User Data Management
- `/get-user-data`: Returns user profile and prescriptions
- `/update-user`: Updates user information
- `/add-prescription`: Adds new prescription
- `/update-prescription`: Modifies existing prescription

#### Data Synchronization
1. Local changes synced with server
2. Periodic backend checks for:
   - Expired medications
   - Missed doses
   - Upcoming refills

### 5. Error Handling

#### Network Errors
- Offline support for notifications
- Retry mechanism for failed API calls
- Local data caching

#### User Input Validation
- Real-time input validation
- Clear error messages
- Guided correction hints

### 6. Performance Considerations

#### Frontend
1. Lazy loading of prescription data
2. Efficient notification scheduling
3. Optimized state management
4. Image caching where applicable

#### Backend
1. Database indexing
2. Query optimization
3. Connection pooling
4. Rate limiting on APIs

### 7. Security Measures

1. **Data Security**
   - Encrypted local storage
   - Secure password hashing
   - Token-based authentication

2. **Privacy**
   - Minimal data collection
   - Local notification processing
   - No third-party data sharing

### 8. Future Enhancements

1. **Planned Features**
   - Medication tracking history
   - Refill reminders
   - Doctor appointments
   - Medicine interaction warnings
   - Family member management

2. **Technical Improvements**
   - Push notifications
   - Cloud sync
   - Analytics dashboard
   - Multi-language support

## Development Guidelines

### Code Organization
- Feature-based structure
- Clear separation of concerns
- Consistent naming conventions
- Comprehensive documentation

### Testing Strategy
1. Unit tests for core functions
2. Integration tests for API endpoints
3. Widget tests for UI components
4. End-to-end testing for critical flows

### Deployment Process
1. Version control best practices
2. Automated testing pipeline
3. Staged rollout strategy
4. Monitoring and analytics

## Maintenance

### Regular Tasks
1. Database backups
2. Log rotation
3. Security updates
4. Performance monitoring

### Support Procedures
1. Bug reporting workflow
2. User feedback system
3. Documentation updates
4. Version compatibility checks
