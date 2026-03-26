import { useNavigate } from "react-router";
import { Bell, Play, Clock, BookOpen, Users, Award, ChevronRight, Video, TrendingUp, Star, Zap, Trophy } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { BottomNav } from "../../components/BottomNav";
import { Button } from "../../components/Button";

export function DashboardScreen() {
  const navigate = useNavigate();

  return (
    <MobileScreen showBottomNav>
      <div className="min-h-full bg-gradient-to-b from-[#F8FAFC] via-white to-[#F8FAFC]">
        {/* Premium Header */}
        <div className="relative overflow-hidden rounded-b-[2.5rem] px-6 pt-14 pb-10">
          {/* Animated gradient background */}
          <div className="absolute inset-0 bg-gradient-to-br from-[#0A2463] via-[#1E3A8A] to-[#0A2463]" />
          <motion.div 
            className="absolute inset-0 opacity-30"
            style={{
              backgroundImage: `radial-gradient(circle at 20% 50%, rgba(20, 184, 166, 0.3) 0%, transparent 50%),
                               radial-gradient(circle at 80% 80%, rgba(94, 234, 212, 0.3) 0%, transparent 50%)`
            }}
            animate={{
              scale: [1, 1.1, 1],
              opacity: [0.3, 0.5, 0.3],
            }}
            transition={{
              duration: 8,
              repeat: Infinity,
              ease: "easeInOut",
            }}
          />
          
          {/* Decorative elements */}
          <div className="absolute top-0 right-0 w-72 h-72 bg-[#14B8A6] rounded-full blur-[120px] opacity-20 -translate-y-32 translate-x-32" />
          <div className="absolute bottom-0 left-0 w-64 h-64 bg-[#5EEAD4] rounded-full blur-[100px] opacity-15 translate-y-20 -translate-x-20" />
          
          <div className="relative z-10">
            {/* Top bar */}
            <div className="flex items-center justify-between mb-8">
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
              >
                <p className="text-[#5EEAD4] text-sm font-semibold mb-1">Welcome back,</p>
                <h1 className="text-3xl font-bold text-white flex items-center gap-2">
                  Gideon 
                  <span className="text-2xl">👋</span>
                </h1>
              </motion.div>
              <div className="flex items-center gap-3">
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  className="relative p-3 bg-white/10 rounded-2xl backdrop-blur-md hover:bg-white/20 transition-all duration-300 border border-white/20"
                  onClick={() => {}}
                >
                  <Trophy className="w-6 h-6 text-[#FFD700]" />
                  <span className="absolute -top-1 -right-1 w-5 h-5 bg-[#FF6B35] rounded-full text-[10px] font-bold text-white flex items-center justify-center border-2 border-[#0A2463]">
                    5
                  </span>
                </motion.button>
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  className="relative p-3 bg-white/10 rounded-2xl backdrop-blur-md hover:bg-white/20 transition-all duration-300 border border-white/20"
                  onClick={() => {}}
                >
                  <Bell className="w-6 h-6 text-white" />
                  <span className="absolute top-2 right-2 w-2.5 h-2.5 bg-[#FF6B35] rounded-full ring-2 ring-white/50 animate-pulse" />
                </motion.button>
              </div>
            </div>

            {/* Stats Cards Row */}
            <div className="grid grid-cols-3 gap-3 mb-6">
              {[
                { icon: TrendingUp, label: "Streak", value: "12", unit: "days", color: "from-[#FF6B35] to-[#FF8A65]" },
                { icon: Star, label: "Points", value: "2.4k", unit: "pts", color: "from-[#FFD700] to-[#FFA500]" },
                { icon: Zap, label: "Level", value: "Pro", unit: "tier", color: "from-[#14B8A6] to-[#5EEAD4]" },
              ].map((stat, index) => (
                <motion.div
                  key={stat.label}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.1 + index * 0.05 }}
                  className="relative overflow-hidden bg-white/10 backdrop-blur-md rounded-2xl p-4 border border-white/20"
                >
                  <div className="absolute top-0 right-0 w-20 h-20 bg-gradient-to-br opacity-10 rounded-full blur-2xl" 
                       style={{ backgroundImage: `linear-gradient(135deg, ${stat.color})` }} />
                  <div className={`w-8 h-8 bg-gradient-to-br ${stat.color} rounded-xl flex items-center justify-center mb-2 shadow-lg`}>
                    <stat.icon className="w-4 h-4 text-white" />
                  </div>
                  <p className="text-2xl font-bold text-white mb-0.5">{stat.value}</p>
                  <p className="text-xs text-white/70 font-medium">{stat.label}</p>
                </motion.div>
              ))}
            </div>

            {/* Next Class Card - Ultra Premium */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.25 }}
              className="relative overflow-hidden bg-white rounded-[2rem] p-6 shadow-2xl"
            >
              {/* Decorative gradient */}
              <div className="absolute top-0 right-0 w-40 h-40 bg-gradient-to-br from-[#14B8A6]/10 via-[#5EEAD4]/5 to-transparent rounded-full blur-3xl" />
              <div className="absolute bottom-0 left-0 w-32 h-32 bg-gradient-to-tr from-[#0A2463]/5 to-transparent rounded-full blur-2xl" />
              
              <div className="relative z-10">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-gradient-to-r from-[#14B8A6]/10 to-[#5EEAD4]/10 rounded-xl mb-3 border border-[#14B8A6]/20">
                      <motion.div 
                        className="w-2 h-2 bg-[#14B8A6] rounded-full"
                        animate={{ scale: [1, 1.3, 1], opacity: [1, 0.5, 1] }}
                        transition={{ duration: 2, repeat: Infinity }}
                      />
                      <p className="text-xs font-bold text-[#14B8A6] uppercase tracking-wider">
                        Starting in 45 min
                      </p>
                    </div>
                    <h3 className="font-bold text-gray-900 text-xl mb-2 leading-tight">
                      React Hooks Deep Dive
                    </h3>
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Clock className="w-4 h-4" />
                      <span className="font-medium">Today, 3:00 PM - 5:00 PM</span>
                    </div>
                    <div className="flex items-center gap-2 mt-2">
                      <div className="flex -space-x-2">
                        {[1, 2, 3].map((i) => (
                          <div key={i} className="w-7 h-7 rounded-full bg-gradient-to-br from-[#0A2463] to-[#14B8A6] border-2 border-white flex items-center justify-center text-[10px] font-bold text-white">
                            {i}
                          </div>
                        ))}
                      </div>
                      <span className="text-xs text-gray-500 font-medium">+24 joined</span>
                    </div>
                  </div>
                  <div className="relative">
                    <div className="absolute inset-0 bg-gradient-to-br from-[#14B8A6] to-[#5EEAD4] rounded-2xl blur-xl opacity-40" />
                    <div className="relative w-16 h-16 bg-gradient-to-br from-[#14B8A6] to-[#5EEAD4] rounded-2xl flex items-center justify-center shadow-xl">
                      <Video className="w-8 h-8 text-white" />
                    </div>
                  </div>
                </div>
                <Button
                  variant="primary"
                  size="md"
                  fullWidth
                  onClick={() => navigate("/live/1")}
                  className="mt-4 relative overflow-hidden group shadow-lg hover:shadow-2xl"
                >
                  <Play className="w-5 h-5 relative z-10" />
                  <span className="relative z-10 font-bold">Join Live Class</span>
                  <motion.div 
                    className="absolute inset-0 bg-gradient-to-r from-[#14B8A6] to-[#0A2463]"
                    initial={{ x: "-100%" }}
                    whileHover={{ x: "0%" }}
                    transition={{ duration: 0.3 }}
                  />
                </Button>
              </div>
            </motion.div>
          </div>
        </div>

        {/* Quick Actions - Premium Grid */}
        <div className="px-6 mt-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
            Quick Actions
            <Zap className="w-5 h-5 text-[#FF6B35]" />
          </h2>
          <div className="grid grid-cols-4 gap-4">
            {[
              { icon: BookOpen, label: "Classes", path: "/classes", gradient: "from-[#0A2463] to-[#1E3A8A]", glow: "from-[#0A2463]/20 to-[#1E3A8A]/20" },
              { icon: Play, label: "Recordings", path: "/recorded/1", gradient: "from-[#14B8A6] to-[#5EEAD4]", glow: "from-[#14B8A6]/20 to-[#5EEAD4]/20" },
              { icon: Users, label: "Community", path: "/community", gradient: "from-purple-600 to-purple-400", glow: "from-purple-600/20 to-purple-400/20" },
              { icon: Award, label: "Certificates", path: "/certificates", gradient: "from-[#FF6B35] to-[#FF8A65]", glow: "from-[#FF6B35]/20 to-[#FF8A65]/20" },
            ].map((action, index) => (
              <motion.button
                key={action.label}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 + index * 0.05 }}
                whileHover={{ y: -4 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => navigate(action.path)}
                className="flex flex-col items-center gap-3 group"
              >
                <div className="relative">
                  <motion.div 
                    className={`absolute inset-0 bg-gradient-to-br ${action.glow} rounded-[1.5rem] blur-xl`}
                    animate={{ scale: [1, 1.1, 1], opacity: [0.5, 0.8, 0.5] }}
                    transition={{ duration: 3, repeat: Infinity, delay: index * 0.2 }}
                  />
                  <div className={`relative w-16 h-16 bg-gradient-to-br ${action.gradient} rounded-[1.5rem] flex items-center justify-center shadow-xl group-hover:shadow-2xl transition-all duration-300`}>
                    <action.icon className="w-7 h-7 text-white relative z-10" />
                    <div className="absolute inset-0 bg-white rounded-[1.5rem] opacity-0 group-hover:opacity-20 transition-opacity duration-300" />
                  </div>
                </div>
                <span className="text-xs text-gray-700 font-bold group-hover:text-gray-900 transition-colors">
                  {action.label}
                </span>
              </motion.button>
            ))}
          </div>
        </div>

        {/* Progress Section - Enhanced */}
        <div className="px-6 mt-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
              Your Progress
              <TrendingUp className="w-5 h-5 text-[#14B8A6]" />
            </h2>
            <button className="text-sm text-[#14B8A6] font-bold hover:text-[#0F766E] transition-colors flex items-center gap-1">
              View All
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>

          <div className="relative overflow-hidden bg-gradient-to-br from-white to-[#F8FAFC] rounded-[2rem] p-6 shadow-xl border border-gray-100">
            {/* Animated background */}
            <div className="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-[#14B8A6]/10 to-transparent rounded-full blur-3xl" />
            <motion.div 
              className="absolute bottom-0 left-0 w-40 h-40 bg-gradient-to-tr from-[#0A2463]/5 to-transparent rounded-full blur-2xl"
              animate={{ scale: [1, 1.2, 1], opacity: [0.3, 0.5, 0.3] }}
              transition={{ duration: 4, repeat: Infinity }}
            />
            
            <div className="relative z-10">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <p className="text-sm text-gray-500 mb-2 font-semibold">Course Completion</p>
                  <div className="flex items-baseline gap-2">
                    <p className="text-4xl font-bold text-gray-900">65%</p>
                    <span className="text-sm text-[#14B8A6] font-bold flex items-center gap-1">
                      <TrendingUp className="w-4 h-4" />
                      +5%
                    </span>
                  </div>
                </div>
                <div className="relative">
                  <svg className="w-24 h-24 -rotate-90">
                    <circle
                      cx="48"
                      cy="48"
                      r="40"
                      stroke="currentColor"
                      strokeWidth="8"
                      fill="none"
                      className="text-gray-100"
                    />
                    <motion.circle
                      cx="48"
                      cy="48"
                      r="40"
                      stroke="url(#gradient)"
                      strokeWidth="8"
                      fill="none"
                      strokeLinecap="round"
                      initial={{ strokeDasharray: "0 251.2" }}
                      animate={{ strokeDasharray: "163.28 251.2" }}
                      transition={{ duration: 1.5, ease: "easeOut", delay: 0.5 }}
                    />
                    <defs>
                      <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stopColor="#14B8A6" />
                        <stop offset="100%" stopColor="#5EEAD4" />
                      </linearGradient>
                    </defs>
                  </svg>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <span className="text-xl font-bold text-gray-900">65%</span>
                  </div>
                </div>
              </div>

              {/* Mini stats */}
              <div className="grid grid-cols-3 gap-3">
                {[
                  { label: "Completed", value: "18", total: "28", color: "text-[#14B8A6]" },
                  { label: "In Progress", value: "4", total: "28", color: "text-[#0A2463]" },
                  { label: "Remaining", value: "6", total: "28", color: "text-gray-400" },
                ].map((stat, index) => (
                  <motion.div
                    key={stat.label}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.6 + index * 0.1 }}
                    className="bg-white/50 backdrop-blur-sm rounded-xl p-3 border border-gray-100"
                  >
                    <p className={`text-lg font-bold ${stat.color}`}>{stat.value}</p>
                    <p className="text-[10px] text-gray-500 font-medium uppercase tracking-wide">{stat.label}</p>
                  </motion.div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Continue Learning - Premium Cards */}
        <div className="px-6 mt-8 pb-28">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
              Continue Learning
              <Play className="w-5 h-5 text-[#0A2463]" />
            </h2>
          </div>

          <div className="space-y-4">
            {[
              {
                title: "JavaScript ES6 Features",
                progress: 75,
                duration: "45 min left",
                type: "Recording",
                thumbnail: "from-yellow-500 to-orange-500",
              },
              {
                title: "Building REST APIs",
                progress: 40,
                duration: "2h 15m left",
                type: "Recording",
                thumbnail: "from-blue-500 to-purple-500",
              },
            ].map((item, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.7 + index * 0.1 }}
                whileHover={{ x: 4 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => navigate("/recorded/1")}
                className="relative overflow-hidden bg-white rounded-[2rem] p-5 shadow-lg border border-gray-100 cursor-pointer hover:shadow-2xl transition-all duration-300"
              >
                {/* Gradient background */}
                <div className="absolute top-0 right-0 w-40 h-40 bg-gradient-to-br from-[#0A2463]/5 to-transparent rounded-full blur-3xl" />
                
                <div className="relative z-10">
                  <div className="flex items-start gap-4">
                    {/* Thumbnail */}
                    <div className="relative flex-shrink-0">
                      <div className={`w-20 h-20 bg-gradient-to-br ${item.thumbnail} rounded-2xl flex items-center justify-center shadow-lg`}>
                        <Play className="w-8 h-8 text-white" />
                      </div>
                      {/* Progress ring */}
                      <svg className="absolute inset-0 w-20 h-20 -rotate-90">
                        <circle
                          cx="40"
                          cy="40"
                          r="38"
                          stroke="currentColor"
                          strokeWidth="3"
                          fill="none"
                          className="text-white/30"
                        />
                        <circle
                          cx="40"
                          cy="40"
                          r="38"
                          stroke="currentColor"
                          strokeWidth="3"
                          fill="none"
                          strokeLinecap="round"
                          className="text-white"
                          strokeDasharray={`${item.progress * 2.387} 238.7`}
                        />
                      </svg>
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <h4 className="font-bold text-gray-900 mb-2 text-lg leading-tight">
                        {item.title}
                      </h4>
                      <div className="flex items-center gap-2 mb-3">
                        <span className="px-3 py-1 bg-gradient-to-r from-[#14B8A6]/10 to-[#5EEAD4]/10 text-[#14B8A6] rounded-lg text-xs font-bold border border-[#14B8A6]/20">
                          {item.type}
                        </span>
                        <span className="text-xs text-gray-500 font-medium flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          {item.duration}
                        </span>
                      </div>
                      
                      {/* Progress bar */}
                      <div className="relative w-full h-2 bg-gray-100 rounded-full overflow-hidden">
                        <motion.div
                          className="h-full bg-gradient-to-r from-[#14B8A6] to-[#5EEAD4] relative"
                          initial={{ width: 0 }}
                          animate={{ width: `${item.progress}%` }}
                          transition={{ duration: 1, delay: 0.8 + index * 0.1 }}
                        >
                          <div className="absolute inset-0 bg-white/30 animate-pulse" />
                        </motion.div>
                      </div>
                      <p className="text-xs text-gray-500 font-semibold mt-1">
                        {item.progress}% complete
                      </p>
                    </div>

                    {/* Arrow */}
                    <ChevronRight className="w-6 h-6 text-gray-300 flex-shrink-0 group-hover:text-gray-600 transition-colors" />
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      <BottomNav />
    </MobileScreen>
  );
}