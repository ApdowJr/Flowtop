import 'package:flutter/material.dart';

/// Brand colors — electric lime on graphite.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFC4F43D);   // electric lime
  static const Color secondary = Color(0xFFAAD939); // softer lime

  static const Color surface = Color(0xFFF5F6F0);
  static const Color surfaceVariant = Color(0xFFECF2DC);
  static const Color surfaceDark = Color(0xFF101110);
  static const Color surfaceDarkVariant = Color(0xFF1A1C1A);

  static const Color onPrimary = Color(0xFF141A08);
  static const Color onSurface = Color(0xFF171B16);
  static const Color onSurfaceDark = Colors.white;

  static const Color brightnessLow = Color(0xFF22C55E);   // green
  static const Color brightnessMedium = Color(0xFFF59E0B); // amber
  static const Color brightnessHigh = Color(0xFFEF4444);   // red

  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color textPrimary = Color(0xFF171B16);
  static const Color textSecondary = Color(0xFF838A7D);
  static const Color textOnDark = Colors.white;

  static const Color divider = Color(0xFFE2E5DB);
  static const Color dividerDark = Color(0xFF30332E);

  static const Color shadow = Color(0x1A000000);
}

/// App strings (English UI copy).
class AppStrings {
  AppStrings._();

  // General
  static const String appName = 'flowTop';
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String create = 'Create';
  static const String done = 'Done';
  static const String loading = 'Loading…';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String tryAgain = 'Try again';
  static const String noItems = 'No items yet';
  static const String signOut = 'Sign out';
  static const String language = 'English';

  // Auth
  static const String welcomeBack = 'Welcome back';
  static const String welcomeBackSub = 'Sign in to your flowTop account';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm password';
  static const String signIn = 'Sign in';
  static const String signInWithGoogle = 'Continue with Google';
  static const String createAccount = 'Create account';
  static const String createAccountSub = 'Join flowTop and start organizing your tasks';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String signUp = 'Sign up';
  static const String forgotPassword = 'Forgot password?';
  static const String resetPassword = 'Reset password';
  static const String sendResetLink = 'Send reset link';
  static const String emailRequired = 'Email is required';
  static const String validEmail = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';

  // Onboarding
  static const String onboardingTitle1 = 'Organize your work';
  static const String onboardingBody1 = 'Keep your personal tasks and team projects in one beautiful place.';
  static const String onboardingTitle2 = 'Collaborate with your team';
  static const String onboardingBody2 = 'Create workspaces, invite members, and assign tasks with roles and permissions.';
  static const String onboardingTitle3 = 'Never miss a deadline';
  static const String onboardingBody3 = 'Set due dates, reminders, and track progress across your calendar.';
  static const String getStarted = 'Get started';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String today = 'Today';
  static const String tasks = 'Tasks';
  static const String projects = 'Projects';
  static const String calendar = 'Calendar';
  static const String workspaces = 'Workspaces';
  static const String profile = 'Profile';
  static const String upcoming = 'Upcoming';
  static const String completed = 'Completed';
  static const String overdue = 'Overdue';
  static const String allTasks = 'All tasks';
  static const String addTask = 'Add task';

  // Tasks
  static const String taskDetails = 'Task details';
  static const String title = 'Title';
  static const String description = 'Description';
  static const String priority = 'Priority';
  static const String low = 'Low';
  static const String medium = 'Medium';
  static const String high = 'High';
  static const String dueDate = 'Due date';
  static const String reminder = 'Reminder';
  static const String status = 'Status';
  static const String todo = 'Todo';
  static const String inProgress = 'In progress';
  static const String doneStatus = 'Done';
  static const String assignee = 'Assignee';
  static const String category = 'Category';
  static const String attachments = 'Attachments';
  static const String noDueDate = 'No due date';
  static const String markComplete = 'Mark complete';
  static const String reopen = 'Reopen';
  static const String taskDeleted = 'Task deleted';
  static const String taskSaved = 'Task saved';

  // Projects
  static const String projectDetails = 'Project details';
  static const String projectName = 'Project name';
  static const String progress = 'Progress';
  static const String members = 'Members';
  static const String addProject = 'Add project';
  static const String noProjects = 'No projects yet';

  // Calendar
  static const String daily = 'Daily';
  static const String weekly = 'Weekly';
  static const String selectDate = 'Select date';

  // Workspaces
  static const String workspace = 'Workspace';
  static const String createWorkspace = 'Create workspace';
  static const String workspaceName = 'Workspace name';
  static const String inviteMembers = 'Invite members';
  static const String role = 'Role';
  static const String owner = 'Owner';
  static const String admin = 'Admin';
  static const String manager = 'Manager';
  static const String member = 'Member';
  static const String viewer = 'Viewer';
  static const String pending = 'Pending';
  static const String accepted = 'Accepted';
  static const String declined = 'Declined';
  static const String invitation = 'Invitation';
  static const String invitations = 'Invitations';
  static const String inviteSent = 'Invitation sent';
  static const String joinWorkspace = 'Join workspace';

  // Statistics
  static const String statistics = 'Statistics';
  static const String productivity = 'Productivity';
  static const String tasksCompleted = 'Tasks completed';
  static const String tasksOverdue = 'Tasks overdue';

  // Profile
  static const String profileTitle = 'Profile';
  static const String preferences = 'Preferences';
  static const String theme = 'Theme';
  static const String darkMode = 'Dark mode';
  static const String notifications = 'Notifications';
  static const String pushNotifications = 'Push notifications';
  static const String account = 'Account';
  static const String emailAddress = 'Email address';
  static const String photo = 'Profile photo';
  static const String changePhoto = 'Change photo';

  // Notifications
  static const String newTaskAssigned = 'New task assigned';
  static const String taskReminder = 'Task reminder';
  static const String workspaceInvitation = 'Workspace invitation';
  static const String taskDueSoon = 'Due soon';
}

/// App routes.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String taskList = '/tasks';
  static const String taskDetail = '/task-detail';
  static const String taskCreate = '/task-create';
  static const String taskEdit = '/task-edit';
  static const String projects = '/projects';
  static const String projectDetail = '/project-detail';
  static const String projectCreate = '/project-create';
  static const String calendar = '/calendar';
  static const String workspaces = '/workspaces';
  static const String workspaceDetail = '/workspace-detail';
  static const String workspaceCreate = '/workspace-create';
  static const String workspaceMembers = '/workspace-members';
  static const String workspaceInvitations = '/workspace-invitations';
  static const String statistics = '/statistics';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static bool isAuth(String path) =>
      path == signIn || path == signUp || path == resetPassword || path == auth;
}
