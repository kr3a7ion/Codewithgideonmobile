# CodeWithGideon Mobile App - Navigation Guide

## 🚀 Quick Start
The app launches at the Splash Screen and automatically navigates through the onboarding flow.

## 📱 Complete User Flow

### Entry Flow
1. **/** - Splash Screen (auto-redirects after 2.5s)
2. **/onboarding** - 3-slide onboarding with swipe/next
3. **/welcome** - Login or Sign Up options
4. **/login** - Login form with forgot password link
5. **/forgot-password** - Password reset flow
6. **/enrollment** - Enrollment status gate (Enrolled/Pending/Not Registered)

### Main App (After Login)
7. **/dashboard** - Main dashboard with:
   - Next class card with "Join Live Class" button
   - Quick action buttons (Classes, Recordings, Community, Certificates)
   - Progress tracking
   - Continue learning section
   - Bottom navigation

### Classes Section
8. **/classes** - Class list with tabs (Upcoming/Live/Completed)
9. **/classes/:id** - Class details with resources and join button

### Live Classroom
10. **/live/:id** - Live session screen with:
    - Video area
    - Chat panel (toggle)
    - Raise hand modal
    - Ask mentor modal
    - Notes overlay
    - Leave confirmation dialog

### Recorded Lessons
11. **/recorded/:id** - Video player with:
    - Playback controls
    - Progress tracking
    - Mark complete modal
    - Resources section
12. **/resources** - Resources library with folders
13. **/ai-tutor/:lessonId** - AI tutor chat interface

### Assessments
14. **/quiz/:id/intro** - Quiz introduction
15. **/quiz/:id/question/:questionId** - Quiz questions with navigation
16. **/quiz/:id/results** - Results with score and achievement
17. **/assignment/:id** - Assignment submission with file upload

### Community
18. **/community** - Community channels list
19. **/community/chat/:channelId** - Class chat with mentor highlighting
20. **/community/messages** - Direct messages list

### Profile
21. **/profile** - Profile overview with stats
22. **/certificates** - Certificates and badges
23. **/profile/edit** - Edit profile form
24. **/settings** - Settings with logout

## 🎨 Design Features
- **Color System**: Deep Blue (#0A2463), Teal (#14B8A6), Deep Orange (#FF6B35)
- **Animations**: Smooth transitions with Motion (Framer Motion)
- **Gradients**: Soft gradients on cards and headers
- **Shadows**: Subtle shadows for depth
- **Rounded Cards**: Consistent 12px-24px border radius
- **Bottom Navigation**: Fixed navigation on main screens

## 🔗 Key User Journeys

### Journey 1: First Time User
/ → /onboarding → /welcome → /login → /enrollment → /dashboard

### Journey 2: Join Live Class
/dashboard → Click "Join Live Class" → /live/1 → (Interact with chat, raise hand, take notes)

### Journey 3: Watch Recording
/dashboard → Click recording card → /recorded/1 → (Watch, mark complete, ask AI tutor)

### Journey 4: Take Quiz
/classes/1 → /quiz/1/intro → /quiz/1/question/1 → /quiz/1/results

### Journey 5: Community Chat
/community → Select channel → /community/chat/1 → (Chat with classmates and mentor)

### Journey 6: View Achievements
/profile → /certificates → (View certificates and badges)

## 🎯 Interactive Elements

### Modals & Overlays
- Raise hand confirmation
- Ask mentor question
- Notes overlay
- Leave class confirmation
- Mark complete success
- Quiz submission
- Logout confirmation

### State Management
- Loading skeletons for async content
- Empty states for no data
- Success toasts for actions
- Error alerts for failures

## 📦 Component Structure
- **MobileScreen**: Container wrapper with fixed mobile dimensions
- **BottomNav**: Fixed bottom navigation (4 tabs)
- **Button**: Reusable button with variants (primary, secondary, outline, ghost, danger)
- **Input**: Form input with label and error states
- **LoadingSkeleton**: Loading states
- **EmptyState**: No data states

## 🎭 Animations
- Page transitions: Fade and slide
- Card animations: Staggered entrance
- Modal animations: Scale and fade
- Progress bars: Smooth width transitions
- Splash screen: Rotating sparkles and pulsing elements
