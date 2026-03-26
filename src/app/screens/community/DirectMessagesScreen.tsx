import { useNavigate } from "react-router";
import { ArrowLeft, Search, ChevronRight } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";

export function DirectMessagesScreen() {
  const navigate = useNavigate();

  const conversations = [
    {
      id: 1,
      user: "Sarah Chen",
      avatar: "SC",
      lastMessage: "Great question! I'll explain that in our next class.",
      time: "2 min ago",
      unread: 2,
      online: true,
      isMentor: true,
    },
    {
      id: 2,
      user: "John Doe",
      avatar: "JD",
      lastMessage: "Thanks for sharing that resource!",
      time: "1 hour ago",
      unread: 0,
      online: true,
      isMentor: false,
    },
    {
      id: 3,
      user: "Emily Wilson",
      avatar: "EW",
      lastMessage: "Want to pair program on the project?",
      time: "Yesterday",
      unread: 1,
      online: false,
      isMentor: false,
    },
    {
      id: 4,
      user: "David Kim",
      avatar: "DK",
      lastMessage: "See you in the next class!",
      time: "2 days ago",
      unread: 0,
      online: false,
      isMentor: true,
    },
  ];

  return (
    <MobileScreen>
      <div className="min-h-full bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-6">
          <div className="flex items-center gap-3 mb-6">
            <button
              onClick={() => navigate(-1)}
              className="p-2 -ml-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </button>
            <h1 className="text-2xl font-bold text-white">Messages</h1>
          </div>

          {/* Search */}
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search messages..."
              className="w-full pl-12 pr-4 py-3 bg-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#14B8A6]"
            />
          </div>
        </div>

        {/* Conversations List */}
        <div className="px-6 py-4 space-y-2">
          {conversations.map((conversation, index) => (
            <motion.button
              key={conversation.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
              className="w-full bg-white rounded-2xl p-4 shadow-sm hover:shadow-md transition-shadow"
            >
              <div className="flex items-start gap-3">
                <div className="relative">
                  <div className={`w-14 h-14 ${
                    conversation.isMentor
                      ? "bg-gradient-to-br from-orange-500 to-orange-600"
                      : "bg-gradient-to-br from-gray-400 to-gray-500"
                  } rounded-full flex items-center justify-center flex-shrink-0`}>
                    <span className="text-white font-bold">{conversation.avatar}</span>
                  </div>
                  {conversation.online && (
                    <div className="absolute bottom-0 right-0 w-4 h-4 bg-green-500 border-2 border-white rounded-full" />
                  )}
                </div>
                <div className="flex-1 min-w-0 text-left">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="font-bold text-gray-900">{conversation.user}</h3>
                    {conversation.isMentor && (
                      <span className="px-2 py-0.5 bg-orange-100 text-orange-700 rounded text-xs font-semibold">
                        Mentor
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-gray-600 truncate mb-1">
                    {conversation.lastMessage}
                  </p>
                  <span className="text-xs text-gray-500">{conversation.time}</span>
                </div>
                <div className="flex flex-col items-end gap-2">
                  {conversation.unread > 0 && (
                    <span className="px-2 py-1 bg-[#FF6B35] text-white rounded-full text-xs font-bold min-w-[24px] text-center">
                      {conversation.unread}
                    </span>
                  )}
                  <ChevronRight className="w-5 h-5 text-gray-400" />
                </div>
              </div>
            </motion.button>
          ))}
        </div>
      </div>
    </MobileScreen>
  );
}
