import { useNavigate } from "react-router";
import { Settings, Award, Edit, ChevronRight, Mail, Calendar, BookOpen } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { BottomNav } from "../../components/BottomNav";

export function ProfileScreen() {
  const navigate = useNavigate();

  const stats = [
    { label: "Courses", value: "3", icon: BookOpen, color: "from-blue-500 to-blue-600" },
    { label: "Completed", value: "12", icon: Award, color: "from-green-500 to-green-600" },
    { label: "Hours", value: "48", icon: Calendar, color: "from-purple-500 to-purple-600" },
  ];

  const menuItems = [
    { icon: Award, label: "Certificates & Achievements", path: "/certificates", color: "text-yellow-600", bg: "bg-yellow-50" },
    { icon: Edit, label: "Edit Profile", path: "/profile/edit", color: "text-blue-600", bg: "bg-blue-50" },
    { icon: Settings, label: "Settings", path: "/settings", color: "text-gray-600", bg: "bg-gray-50" },
  ];

  return (
    <MobileScreen showBottomNav>
      <div className="min-h-full bg-gray-50">
        {/* Header with Profile */}
        <div className="bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-24">
          <div className="flex items-center justify-between mb-8">
            <h1 className="text-2xl font-bold text-white">Profile</h1>
            <button
              onClick={() => navigate("/settings")}
              className="p-2 bg-white/10 backdrop-blur-sm rounded-xl hover:bg-white/20 transition-colors"
            >
              <Settings className="w-6 h-6 text-white" />
            </button>
          </div>

          {/* Profile Card */}
          <div className="text-center">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 200 }}
              className="w-24 h-24 bg-gradient-to-br from-[#14B8A6] to-[#5EEAD4] rounded-full flex items-center justify-center mx-auto mb-4 shadow-2xl"
            >
              <span className="text-3xl font-bold text-white">GK</span>
            </motion.div>
            <h2 className="text-2xl font-bold text-white mb-1">Gideon Kamau</h2>
            <div className="flex items-center justify-center gap-2 text-blue-200 mb-4">
              <Mail className="w-4 h-4" />
              <span className="text-sm">gideon.kamau@email.com</span>
            </div>
            <div className="flex items-center justify-center gap-2">
              <span className="px-3 py-1 bg-teal-500 text-white rounded-full text-xs font-semibold">
                Active Student
              </span>
              <span className="px-3 py-1 bg-white/20 backdrop-blur-sm text-white rounded-full text-xs font-semibold">
                Since Jan 2026
              </span>
            </div>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="px-6 -mt-16 mb-6">
          <div className="grid grid-cols-3 gap-3">
            {stats.map((stat, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                className="bg-white rounded-2xl p-4 text-center shadow-lg"
              >
                <div className={`w-12 h-12 bg-gradient-to-br ${stat.color} rounded-xl flex items-center justify-center mx-auto mb-2`}>
                  <stat.icon className="w-6 h-6 text-white" />
                </div>
                <p className="text-2xl font-bold text-gray-900 mb-1">{stat.value}</p>
                <p className="text-xs text-gray-600">{stat.label}</p>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Menu Items */}
        <div className="px-6 space-y-2 pb-24">
          {menuItems.map((item, index) => (
            <motion.button
              key={index}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.3 + index * 0.05 }}
              onClick={() => navigate(item.path)}
              className="w-full bg-white rounded-2xl p-4 shadow-sm hover:shadow-md transition-shadow flex items-center gap-3"
            >
              <div className={`w-12 h-12 ${item.bg} rounded-xl flex items-center justify-center`}>
                <item.icon className={`w-6 h-6 ${item.color}`} />
              </div>
              <span className="flex-1 text-left font-semibold text-gray-900">
                {item.label}
              </span>
              <ChevronRight className="w-5 h-5 text-gray-400" />
            </motion.button>
          ))}
        </div>
      </div>

      <BottomNav />
    </MobileScreen>
  );
}
