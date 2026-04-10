import 'package:flutter/material.dart';

class CourseResource {
  const CourseResource({
    required this.name,
    required this.type,
    required this.size,
    this.date = '',
    this.folder = '',
  });

  final String name;
  final String type;
  final String size;
  final String date;
  final String folder;
}

enum ClassStatus { upcoming, live, completed }

class LearningClass {
  const LearningClass({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.instructor,
    required this.students,
    required this.topic,
    required this.status,
    required this.description,
    required this.learningOutcomes,
    required this.prerequisites,
    required this.resources,
  });

  final String id;
  final String title;
  final String date;
  final String duration;
  final String instructor;
  final int students;
  final String topic;
  final ClassStatus status;
  final String description;
  final List<String> learningOutcomes;
  final List<String> prerequisites;
  final List<CourseResource> resources;
}

class RecordedLesson {
  const RecordedLesson({
    required this.id,
    required this.title,
    required this.instructor,
    required this.duration,
    required this.watched,
    required this.completed,
    required this.description,
    required this.resources,
  });

  final String id;
  final String title;
  final String instructor;
  final String duration;
  final String watched;
  final int completed;
  final String description;
  final List<CourseResource> resources;
}

class QuizQuestionData {
  const QuizQuestionData({
    required this.number,
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  final int number;
  final String text;
  final List<String> options;
  final int correctIndex;
}

class Channel {
  const Channel({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.unread,
    required this.colors,
  });

  final String id;
  final String name;
  final String description;
  final int members;
  final int unread;
  final List<Color> colors;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.user,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.online,
    required this.isMentor,
  });

  final String id;
  final String user;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unread;
  final bool online;
  final bool isMentor;
}

class CommunityMessage {
  const CommunityMessage({
    required this.id,
    required this.user,
    required this.avatar,
    required this.message,
    required this.time,
    this.isMentor = false,
    this.isCode = false,
    this.isUser = false,
  });

  final String id;
  final String user;
  final String avatar;
  final String message;
  final String time;
  final bool isMentor;
  final bool isCode;
  final bool isUser;
}

class TutorMessage {
  const TutorMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isUser,
  });

  final String id;
  final String text;
  final String time;
  final bool isUser;
}

class CertificateItem {
  const CertificateItem({
    required this.id,
    required this.title,
    required this.issueDate,
    required this.instructor,
  });

  final String id;
  final String title;
  final String issueDate;
  final String instructor;
}

class BadgeItem {
  const BadgeItem({
    required this.name,
    required this.icon,
    required this.colors,
    required this.description,
    required this.earned,
  });

  final String name;
  final IconData icon;
  final List<Color> colors;
  final String description;
  final bool earned;
}

class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.bio,
    required this.memberSince,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String bio;
  final String memberSince;

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? bio,
    String? memberSince,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      memberSince: memberSince ?? this.memberSince,
    );
  }
}

class DemoData {
  static const userProfile = UserProfile(
    firstName: 'Gideon',
    lastName: 'Kamau',
    email: 'gideon.kamau@email.com',
    phone: '+254 712 345 678',
    bio: 'Aspiring full-stack developer passionate about web technologies.',
    memberSince: 'Since Jan 2026',
  );

  static const classes = [
    LearningClass(
      id: '1',
      title: 'React Hooks Deep Dive',
      date: 'Today, 3:00 PM - 5:00 PM',
      duration: '2 hours',
      instructor: 'Sarah Chen',
      students: 24,
      topic: 'React',
      status: ClassStatus.upcoming,
      description:
          'Master React Hooks with hands-on examples covering state, effects, context, and reusable hook patterns.',
      learningOutcomes: [
        'Understand useState and useEffect in depth',
        'Create custom hooks for reusable logic',
        'Master useContext for state management',
        'Learn performance optimization patterns',
      ],
      prerequisites: ['Basic React knowledge', 'JavaScript ES6+'],
      resources: [
        CourseResource(
          name: 'React Hooks Cheatsheet.pdf',
          type: 'PDF',
          size: '2.4 MB',
        ),
        CourseResource(
          name: 'Example Code Repository',
          type: 'Link',
          size: 'GitHub',
        ),
        CourseResource(name: 'Slides.pdf', type: 'PDF', size: '5.1 MB'),
      ],
    ),
    LearningClass(
      id: '2',
      title: 'TypeScript Fundamentals',
      date: 'Tomorrow, 2:00 PM - 3:30 PM',
      duration: '1.5 hours',
      instructor: 'James Wilson',
      students: 18,
      topic: 'TypeScript',
      status: ClassStatus.upcoming,
      description:
          'Build confidence with types, interfaces, utility types, and safer component APIs.',
      learningOutcomes: [
        'Model data using interfaces and types',
        'Use unions, enums, and utility helpers',
        'Type React props and hooks cleanly',
      ],
      prerequisites: ['JavaScript fundamentals'],
      resources: [
        CourseResource(
          name: 'TS Starter Pack.pdf',
          type: 'PDF',
          size: '1.9 MB',
        ),
      ],
    ),
    LearningClass(
      id: '3',
      title: 'Node.js API Development',
      date: 'Feb 13, 4:00 PM - 6:00 PM',
      duration: '2 hours',
      instructor: 'Maria Garcia',
      students: 22,
      topic: 'Backend',
      status: ClassStatus.upcoming,
      description:
          'Design clean REST APIs with Node.js, Express, validation, and deployment best practices.',
      learningOutcomes: [
        'Structure controllers and services cleanly',
        'Handle validation and error states',
        'Ship an API ready for frontend integration',
      ],
      prerequisites: ['JavaScript ES6+', 'Basic backend concepts'],
      resources: [
        CourseResource(name: 'API Checklist.pdf', type: 'PDF', size: '1.5 MB'),
      ],
    ),
    LearningClass(
      id: '4',
      title: 'JavaScript ES6 Workshop',
      date: 'Live Now',
      duration: '45 min left',
      instructor: 'David Kim',
      students: 32,
      topic: 'JavaScript',
      status: ClassStatus.live,
      description:
          'A workshop covering arrow functions, destructuring, modules, and the spread operator.',
      learningOutcomes: [
        'Use arrow functions confidently',
        'Understand destructuring patterns',
        'Compose arrays and objects with spread',
      ],
      prerequisites: ['JavaScript basics'],
      resources: [
        CourseResource(
          name: 'ES6 Quick Reference.pdf',
          type: 'PDF',
          size: '2.1 MB',
        ),
      ],
    ),
    LearningClass(
      id: '5',
      title: 'CSS Grid & Flexbox',
      date: 'Feb 9, 2026',
      duration: '2 hours',
      instructor: 'Emily Brown',
      students: 28,
      topic: 'CSS',
      status: ClassStatus.completed,
      description:
          'Build responsive layouts with modern CSS layout primitives and clean spacing systems.',
      learningOutcomes: [
        'Create one-dimensional and two-dimensional layouts',
        'Debug alignment issues quickly',
      ],
      prerequisites: ['Basic HTML and CSS'],
      resources: [
        CourseResource(
          name: 'Layout Patterns.pdf',
          type: 'PDF',
          size: '1.2 MB',
        ),
      ],
    ),
    LearningClass(
      id: '6',
      title: 'Git Version Control',
      date: 'Feb 7, 2026',
      duration: '1.5 hours',
      instructor: 'Alex Johnson',
      students: 25,
      topic: 'Tools',
      status: ClassStatus.completed,
      description:
          'Use Git for everyday team workflows including branching, rebasing, and code review.',
      learningOutcomes: [
        'Understand branch workflows',
        'Resolve merge conflicts with confidence',
      ],
      prerequisites: ['Terminal basics'],
      resources: [
        CourseResource(
          name: 'Git Cheat Sheet.pdf',
          type: 'PDF',
          size: '950 KB',
        ),
      ],
    ),
  ];

  static const recordedLessons = [
    RecordedLesson(
      id: '1',
      title: 'JavaScript ES6 Features',
      instructor: 'David Kim',
      duration: '45:30',
      watched: '15:45',
      completed: 35,
      description:
          'Learn modern JavaScript ES6+ features including arrow functions, destructuring, spread operator, and more.',
      resources: [
        CourseResource(
          name: 'Code Examples',
          type: 'GitHub',
          size: 'Repository',
        ),
        CourseResource(name: 'ES6 Cheatsheet.pdf', type: 'PDF', size: '2.4 MB'),
      ],
    ),
    RecordedLesson(
      id: '2',
      title: 'Building REST APIs',
      instructor: 'Maria Garcia',
      duration: '1:12:00',
      watched: '29:08',
      completed: 40,
      description:
          'Build maintainable REST APIs with routing, services, validation, and error handling.',
      resources: [
        CourseResource(
          name: 'Postman Collection.json',
          type: 'JSON',
          size: '230 KB',
        ),
      ],
    ),
  ];

  static const libraryFolders = [
    ('Week 1 - Basics', 12),
    ('Week 2 - Advanced', 8),
    ('Projects', 5),
  ];

  static const libraryResources = [
    CourseResource(
      name: 'React Hooks Cheatsheet.pdf',
      type: 'PDF',
      size: '2.4 MB',
      date: 'Feb 10, 2026',
      folder: 'Week 2',
    ),
    CourseResource(
      name: 'ES6 Guide.pdf',
      type: 'PDF',
      size: '3.1 MB',
      date: 'Feb 9, 2026',
      folder: 'Week 1',
    ),
    CourseResource(
      name: 'API Project Code',
      type: 'ZIP',
      size: '5.6 MB',
      date: 'Feb 8, 2026',
      folder: 'Projects',
    ),
    CourseResource(
      name: 'CSS Flexbox Examples.pdf',
      type: 'PDF',
      size: '1.8 MB',
      date: 'Feb 7, 2026',
      folder: 'Week 1',
    ),
  ];

  static const channels = [
    Channel(
      id: '1',
      name: 'general',
      description: 'General discussions and announcements',
      members: 124,
      unread: 5,
      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    ),
    Channel(
      id: '2',
      name: 'react-hooks-class',
      description: 'React Hooks class discussions',
      members: 24,
      unread: 12,
      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    ),
    Channel(
      id: '3',
      name: 'javascript-help',
      description: 'Get help with JavaScript',
      members: 89,
      unread: 0,
      colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
    ),
    Channel(
      id: '4',
      name: 'project-showcase',
      description: 'Share your projects',
      members: 156,
      unread: 3,
      colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    ),
    Channel(
      id: '5',
      name: 'career-advice',
      description: 'Career tips and job opportunities',
      members: 92,
      unread: 0,
      colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    ),
  ];

  static const conversations = [
    Conversation(
      id: '1',
      user: 'Sarah Chen',
      avatar: 'SC',
      lastMessage: 'Great question! I will explain that in our next class.',
      time: '2 min ago',
      unread: 2,
      online: true,
      isMentor: true,
    ),
    Conversation(
      id: '2',
      user: 'John Doe',
      avatar: 'JD',
      lastMessage: 'Thanks for sharing that resource!',
      time: '1 hour ago',
      unread: 0,
      online: true,
      isMentor: false,
    ),
    Conversation(
      id: '3',
      user: 'Emily Wilson',
      avatar: 'EW',
      lastMessage: 'Want to pair program on the project?',
      time: 'Yesterday',
      unread: 1,
      online: false,
      isMentor: false,
    ),
    Conversation(
      id: '4',
      user: 'David Kim',
      avatar: 'DK',
      lastMessage: 'See you in the next class!',
      time: '2 days ago',
      unread: 0,
      online: false,
      isMentor: true,
    ),
  ];

  static const communityMessages = [
    CommunityMessage(
      id: '1',
      user: 'Sarah Chen',
      avatar: 'SC',
      message:
          'Welcome to the React Hooks class chat! Feel free to ask questions anytime.',
      time: '10:30 AM',
      isMentor: true,
    ),
    CommunityMessage(
      id: '2',
      user: 'John Doe',
      avatar: 'JD',
      message: 'Thanks! Quick question about useEffect cleanup functions.',
      time: '10:32 AM',
    ),
    CommunityMessage(
      id: '3',
      user: 'Sarah Chen',
      avatar: 'SC',
      message:
          'Great question! Cleanup functions are returned from useEffect to prevent memory leaks. Here is an example:',
      time: '10:33 AM',
      isMentor: true,
    ),
    CommunityMessage(
      id: '4',
      user: 'Sarah Chen',
      avatar: 'SC',
      message:
          "useEffect(() {\n  final timer = Timer.periodic(...);\n  return () => timer.cancel();\n}, const []);",
      time: '10:33 AM',
      isMentor: true,
      isCode: true,
    ),
    CommunityMessage(
      id: '5',
      user: 'Emily Wilson',
      avatar: 'EW',
      message: 'That is super helpful! Thanks Sarah.',
      time: '10:35 AM',
    ),
    CommunityMessage(
      id: '6',
      user: 'You',
      avatar: 'ME',
      message: 'Can you explain dependency arrays?',
      time: '10:37 AM',
      isUser: true,
    ),
  ];

  static const liveChatMessages = [
    CommunityMessage(
      id: '1',
      user: 'Sarah Chen',
      avatar: 'SC',
      message: 'Welcome everyone!',
      time: '3:01 PM',
      isMentor: true,
    ),
    CommunityMessage(
      id: '2',
      user: 'John Doe',
      avatar: 'JD',
      message: 'Excited to learn!',
      time: '3:02 PM',
    ),
    CommunityMessage(
      id: '3',
      user: 'You',
      avatar: 'ME',
      message: 'Thank you for the class!',
      time: '3:05 PM',
      isUser: true,
    ),
  ];

  static const tutorSeedMessages = [
    TutorMessage(
      id: '1',
      text:
          "Hi! I'm your AI tutor. I'm here to help you understand JavaScript ES6 features. What would you like to know?",
      time: '3:45 PM',
      isUser: false,
    ),
  ];

  static const quickTutorQuestions = [
    'Explain arrow functions',
    'What is destructuring?',
    'How does spread operator work?',
    'Difference between let and const',
  ];

  static const quizQuestions = [
    QuizQuestionData(
      number: 1,
      text: 'What is the correct way to use the useState hook in React?',
      options: [
        'const [state, setState] = useState(initialValue);',
        'const state = useState(initialValue);',
        'const setState = useState(initialValue);',
        'useState(state, setState);',
      ],
      correctIndex: 0,
    ),
    QuizQuestionData(
      number: 2,
      text: 'Which hook should you use for side effects?',
      options: ['useMemo', 'useEffect', 'useRef', 'useId'],
      correctIndex: 1,
    ),
    QuizQuestionData(
      number: 3,
      text: 'What does a dependency array control?',
      options: [
        'Component styling',
        'When an effect reruns',
        'Routing behavior',
        'State initialization',
      ],
      correctIndex: 1,
    ),
    QuizQuestionData(
      number: 4,
      text: 'Which hook is useful for sharing state through a tree?',
      options: ['useContext', 'useDebug', 'useCache', 'useLayout'],
      correctIndex: 0,
    ),
    QuizQuestionData(
      number: 5,
      text: 'Which option best describes a custom hook?',
      options: [
        'A hook that returns JSX only',
        'A function that starts with use and reuses hook logic',
        'A CSS utility',
        'A library-only concept',
      ],
      correctIndex: 1,
    ),
    QuizQuestionData(
      number: 6,
      text: 'What is a common reason to use useRef?',
      options: [
        'To trigger rerenders',
        'To persist a mutable value without rerendering',
        'To fetch APIs',
        'To change routes',
      ],
      correctIndex: 1,
    ),
    QuizQuestionData(
      number: 7,
      text: 'Which hook helps optimize expensive calculations?',
      options: ['useMemo', 'useEffect', 'useState', 'useContext'],
      correctIndex: 0,
    ),
    QuizQuestionData(
      number: 8,
      text: 'What should cleanup functions typically prevent?',
      options: ['Page reloads', 'Memory leaks', 'Compilation', 'Navigation'],
      correctIndex: 1,
    ),
    QuizQuestionData(
      number: 9,
      text: 'When should a custom hook be preferred?',
      options: [
        'When repeated hook logic appears across components',
        'Only when using TypeScript',
        'Only in class components',
        'Never',
      ],
      correctIndex: 0,
    ),
    QuizQuestionData(
      number: 10,
      text: 'Which statement about hooks is true?',
      options: [
        'Hooks can be called conditionally',
        'Hooks can be called inside loops freely',
        'Hooks should be called at the top level of components and custom hooks',
        'Hooks only work in production',
      ],
      correctIndex: 2,
    ),
  ];

  static const certificates = [
    CertificateItem(
      id: '1',
      title: 'React Fundamentals',
      issueDate: 'Feb 1, 2026',
      instructor: 'Sarah Chen',
    ),
    CertificateItem(
      id: '2',
      title: 'JavaScript ES6 Mastery',
      issueDate: 'Jan 15, 2026',
      instructor: 'David Kim',
    ),
  ];

  static const badges = [
    BadgeItem(
      name: 'Fast Learner',
      icon: Icons.bolt_rounded,
      colors: [Color(0xFFFFB347), Color(0xFFFF7A45)],
      description: 'Completed 5 courses in a month',
      earned: true,
    ),
    BadgeItem(
      name: 'Perfect Score',
      icon: Icons.workspace_premium_rounded,
      colors: [Color(0xFF14B8A6), Color(0xFF5EEAD4)],
      description: 'Got 100% on a quiz',
      earned: true,
    ),
    BadgeItem(
      name: 'Helpful',
      icon: Icons.volunteer_activism_rounded,
      colors: [Color(0xFF0A2463), Color(0xFF4F79C7)],
      description: 'Answered 10 questions',
      earned: true,
    ),
    BadgeItem(
      name: 'Dedicated',
      icon: Icons.gps_fixed_rounded,
      colors: [Color(0xFFFF8A65), Color(0xFFFFB347)],
      description: '30 day streak',
      earned: false,
    ),
    BadgeItem(
      name: 'Expert',
      icon: Icons.emoji_events_rounded,
      colors: [Color(0xFFFFC857), Color(0xFFFF8A65)],
      description: 'Complete all courses',
      earned: false,
    ),
  ];

  static LearningClass learningClass(String id) {
    return classes.firstWhere(
      (item) => item.id == id,
      orElse: () => classes.first,
    );
  }

  static RecordedLesson recordedLesson(String id) {
    return recordedLessons.firstWhere(
      (item) => item.id == id,
      orElse: () => recordedLessons.first,
    );
  }

  static QuizQuestionData quizQuestion(int number) {
    return quizQuestions[number - 1];
  }

  static Channel channel(String id) {
    return channels.firstWhere(
      (item) => item.id == id,
      orElse: () => channels[1],
    );
  }
}
