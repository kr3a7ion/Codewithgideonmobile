import { useNavigate } from "react-router";
import { Search, Hash, Users, ChevronRight, MessageCircle } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { BottomNav } from "../../components/BottomNav";

export function CommunityChannelsScreen() {
  const navigate = useNavigate();

  const channels = [
    {
      id: 1,
      name: "general",
      description: "General discussions and announcements",
      members: 124,
      unread: 5,
      color: "from-blue-500 to-blue-600",
    },
    {
      id: 2,
      name: "react-hooks-class",
      description: "React Hooks class discussions",
      members: 24,
      unread: 12,
      color: "from-purple-500 to-purple-600",
    },
    {
      id: 3,
      name: "javascript-help",
      description: "Get help with JavaScript",
      members: 89,
      unread: 0,
      color: "from-yellow-500 to-yellow-600",
    },
    {
      id: 4,
      name: "project-showcase",
      description: "Share your projects",
      members: 156,
      unread: 3,
      color: "from-green-500 to-green-600",
    },
    {
      id: 5,
      name: "career-advice",
      description: "Career tips and job opportunities",
      members: 92,
      unread: 0,
      color: "from-orange-500 to-orange-600",
    },
  ];

  return (
    <MobileScreen showBottomNav>
      <div className="min-h-full bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-6">
          <div className="flex items-center justify-between mb-6">
            <h1 className="text-2xl font-bold text-white">Community</h1>
            <button
              onClick={() => navigate("/community/messages")}
              className="p-2 bg-white/10 backdrop-blur-sm rounded-xl hover:bg-white/20 transition-colors relative"
            >
              <MessageCircle className="w-6 h-6 text-white" />
              <span className="absolute top-1 right-1 w-2 h-2 bg-[#FF6B35] rounded-full" />
            </button>
          </div>

          {/* Search */}
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search channels..."
              className="w-full pl-12 pr-4 py-3 bg-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#14B8A6]"
            />
          </div>
        </div>

        {/* Channels List */}
        <div className="px-6 py-4 space-y-3 pb-24">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-sm font-bold text-gray-600 uppercase tracking-wide">
              Channels
            </h2>
            <span className="text-sm text-gray-500">{channels.length} total</span>
          </div>

          {channels.map((channel, index) => (
            <motion.button
              key={channel.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.05 }}
              onClick={() => navigate(`/community/chat/${channel.id}`)}
              className="w-full bg-white rounded-2xl p-4 shadow-sm hover:shadow-md transition-shadow"
            >
              <div className="flex items-start gap-3">
                <div className={`w-12 h-12 bg-gradient-to-br ${channel.color} rounded-xl flex items-center justify-center flex-shrink-0`}>
                  <Hash className="w-6 h-6 text-white" />
                </div>
                <div className="flex-1 min-w-0 text-left">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="font-bold text-gray-900">#{channel.name}</h3>
                    {channel.unread > 0 && (
                      <span className="px-2 py-0.5 bg-[#FF6B35] text-white rounded-full text-xs font-bold">
                        {channel.unread}
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-gray-600 mb-2">
                    {channel.description}
                  </p>
                  <div className="flex items-center gap-2 text-xs text-gray-500">
                    <Users className="w-3.5 h-3.5" />
                    <span>{channel.members} members</span>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400 flex-shrink-0 mt-1" />
              </div>
            </motion.button>
          ))}
        </div>
      </div>

      <BottomNav />
    </MobileScreen>
  );
}
