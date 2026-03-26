import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Calendar, Search, Clock, Users, Video, CheckCircle } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { BottomNav } from "../../components/BottomNav";

type ClassTab = "upcoming" | "live" | "completed";

export function ClassListScreen() {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<ClassTab>("upcoming");
  const [searchQuery, setSearchQuery] = useState("");

  const classes = {
    upcoming: [
      {
        id: 1,
        title: "React Hooks Deep Dive",
        date: "Today, 3:00 PM",
        duration: "2h",
        instructor: "Sarah Chen",
        students: 24,
        topic: "React",
      },
      {
        id: 2,
        title: "TypeScript Fundamentals",
        date: "Tomorrow, 2:00 PM",
        duration: "1.5h",
        instructor: "James Wilson",
        students: 18,
        topic: "TypeScript",
      },
      {
        id: 3,
        title: "Node.js API Development",
        date: "Feb 13, 4:00 PM",
        duration: "2h",
        instructor: "Maria Garcia",
        students: 22,
        topic: "Backend",
      },
    ],
    live: [
      {
        id: 4,
        title: "JavaScript ES6 Workshop",
        date: "Live Now",
        duration: "45 min left",
        instructor: "David Kim",
        students: 32,
        topic: "JavaScript",
      },
    ],
    completed: [
      {
        id: 5,
        title: "CSS Grid & Flexbox",
        date: "Feb 9, 2026",
        duration: "2h",
        instructor: "Emily Brown",
        students: 28,
        topic: "CSS",
        attendance: true,
      },
      {
        id: 6,
        title: "Git Version Control",
        date: "Feb 7, 2026",
        duration: "1.5h",
        instructor: "Alex Johnson",
        students: 25,
        topic: "Tools",
        attendance: true,
      },
    ],
  };

  const currentClasses = classes[activeTab];

  return (
    <MobileScreen showBottomNav>
      <div className="min-h-full bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-6">
          <div className="flex items-center gap-3 mb-6">
            <button
              onClick={() => navigate("/dashboard")}
              className="p-2 -ml-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </button>
            <h1 className="text-2xl font-bold text-white">My Classes</h1>
          </div>

          {/* Search */}
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search classes..."
              className="w-full pl-12 pr-4 py-3 bg-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#14B8A6]"
            />
          </div>
        </div>

        {/* Tabs */}
        <div className="bg-white px-6 py-3 border-b border-gray-200">
          <div className="flex gap-2">
            {(["upcoming", "live", "completed"] as ClassTab[]).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-4 py-2 rounded-lg font-medium text-sm transition-all ${
                  activeTab === tab
                    ? "bg-[#0A2463] text-white"
                    : "text-gray-600 hover:bg-gray-100"
                }`}
              >
                {tab.charAt(0).toUpperCase() + tab.slice(1)}
                {tab === "live" && classes.live.length > 0 && (
                  <span className="ml-1 px-1.5 py-0.5 bg-[#FF6B35] text-white rounded-full text-xs">
                    {classes.live.length}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>

        {/* Class List */}
        <div className="px-6 py-4 space-y-3 pb-24">
          {currentClasses.map((classItem, index) => (
            <motion.div
              key={classItem.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => navigate(`/classes/${classItem.id}`)}
              className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 cursor-pointer hover:shadow-md transition-shadow"
            >
              <div className="flex items-start gap-3 mb-3">
                <div className={`w-12 h-12 ${
                  activeTab === "live"
                    ? "bg-gradient-to-br from-red-500 to-red-600 animate-pulse"
                    : "bg-gradient-to-br from-[#0A2463] to-[#1E3A8A]"
                } rounded-xl flex items-center justify-center flex-shrink-0`}>
                  {activeTab === "completed" ? (
                    <CheckCircle className="w-6 h-6 text-white" />
                  ) : (
                    <Video className="w-6 h-6 text-white" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-bold text-gray-900 mb-1">
                    {classItem.title}
                  </h3>
                  <div className="flex items-center gap-2 text-xs text-gray-600 mb-2">
                    <Calendar className="w-3.5 h-3.5" />
                    <span className={activeTab === "live" ? "text-red-600 font-semibold" : ""}>
                      {classItem.date}
                    </span>
                    <span>•</span>
                    <Clock className="w-3.5 h-3.5" />
                    <span>{classItem.duration}</span>
                  </div>
                  <span className="inline-block px-2 py-0.5 bg-teal-50 text-teal-700 rounded-full text-xs font-medium">
                    {classItem.topic}
                  </span>
                </div>
              </div>

              <div className="flex items-center justify-between pt-3 border-t border-gray-100">
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Users className="w-4 h-4" />
                  <span>{classItem.students} students</span>
                </div>
                <span className="text-sm text-gray-600">
                  by {classItem.instructor}
                </span>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      <BottomNav />
    </MobileScreen>
  );
}
