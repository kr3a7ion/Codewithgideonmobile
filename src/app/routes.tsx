import { createBrowserRouter } from "react-router";

// Entry Screens
import { SplashScreen } from "./screens/entry/SplashScreen";
import { OnboardingScreen } from "./screens/entry/OnboardingScreen";
import { WelcomeScreen } from "./screens/entry/WelcomeScreen";
import { LoginScreen } from "./screens/entry/LoginScreen";
import { SignUpScreen } from "./screens/entry/SignUpScreen";
import { ForgotPasswordScreen } from "./screens/entry/ForgotPasswordScreen";
import { EnrollmentGateScreen } from "./screens/entry/EnrollmentGateScreen";

// Home Screens
import { DashboardScreen } from "./screens/home/DashboardScreen";

// Classes Screens
import { ClassListScreen } from "./screens/classes/ClassListScreen";
import { ClassDetailsScreen } from "./screens/classes/ClassDetailsScreen";

// Live Classroom Screens
import { LiveSessionScreen } from "./screens/live/LiveSessionScreen";

// Recorded Lessons Screens
import { RecordedPlayerScreen } from "./screens/recorded/RecordedPlayerScreen";
import { ResourcesLibraryScreen } from "./screens/recorded/ResourcesLibraryScreen";
import { AiTutorScreen } from "./screens/recorded/AiTutorScreen";

// Assessment Screens
import { QuizIntroScreen } from "./screens/assessments/QuizIntroScreen";
import { QuizQuestionScreen } from "./screens/assessments/QuizQuestionScreen";
import { QuizResultsScreen } from "./screens/assessments/QuizResultsScreen";
import { AssignmentSubmissionScreen } from "./screens/assessments/AssignmentSubmissionScreen";

// Community Screens
import { CommunityChannelsScreen } from "./screens/community/CommunityChannelsScreen";
import { ClassChatScreen } from "./screens/community/ClassChatScreen";
import { DirectMessagesScreen } from "./screens/community/DirectMessagesScreen";

// Profile Screens
import { ProfileScreen } from "./screens/profile/ProfileScreen";
import { CertificatesScreen } from "./screens/profile/CertificatesScreen";
import { EditProfileScreen } from "./screens/profile/EditProfileScreen";
import { SettingsScreen } from "./screens/profile/SettingsScreen";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: SplashScreen,
  },
  {
    path: "/onboarding",
    Component: OnboardingScreen,
  },
  {
    path: "/welcome",
    Component: WelcomeScreen,
  },
  {
    path: "/login",
    Component: LoginScreen,
  },
  {
    path: "/signup",
    Component: SignUpScreen,
  },
  {
    path: "/forgot-password",
    Component: ForgotPasswordScreen,
  },
  {
    path: "/enrollment",
    Component: EnrollmentGateScreen,
  },
  {
    path: "/dashboard",
    Component: DashboardScreen,
  },
  {
    path: "/classes",
    Component: ClassListScreen,
  },
  {
    path: "/classes/:id",
    Component: ClassDetailsScreen,
  },
  {
    path: "/live/:id",
    Component: LiveSessionScreen,
  },
  {
    path: "/recorded/:id",
    Component: RecordedPlayerScreen,
  },
  {
    path: "/resources",
    Component: ResourcesLibraryScreen,
  },
  {
    path: "/ai-tutor/:lessonId",
    Component: AiTutorScreen,
  },
  {
    path: "/quiz/:id/intro",
    Component: QuizIntroScreen,
  },
  {
    path: "/quiz/:id/question/:questionId",
    Component: QuizQuestionScreen,
  },
  {
    path: "/quiz/:id/results",
    Component: QuizResultsScreen,
  },
  {
    path: "/assignment/:id",
    Component: AssignmentSubmissionScreen,
  },
  {
    path: "/community",
    Component: CommunityChannelsScreen,
  },
  {
    path: "/community/chat/:channelId",
    Component: ClassChatScreen,
  },
  {
    path: "/community/messages",
    Component: DirectMessagesScreen,
  },
  {
    path: "/profile",
    Component: ProfileScreen,
  },
  {
    path: "/certificates",
    Component: CertificatesScreen,
  },
  {
    path: "/profile/edit",
    Component: EditProfileScreen,
  },
  {
    path: "/settings",
    Component: SettingsScreen,
  },
]);