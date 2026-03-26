import { useState, useRef, useEffect } from "react";
import { useNavigate, useParams } from "react-router";
import { ArrowLeft, Send, Code, Image as ImageIcon, MoreVertical } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";

interface Message {
  id: number;
  user: string;
  avatar: string;
  message: string;
  time: string;
  isMentor?: boolean;
  isCode?: boolean;
}

export function ClassChatScreen() {
  const navigate = useNavigate();
  const { channelId } = useParams();
  const [message, setMessage] = useState("");
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const messages: Message[] = [
    {
      id: 1,
      user: "Sarah Chen",
      avatar: "SC",
      message: "Welcome to the React Hooks class chat! Feel free to ask questions anytime.",
      time: "10:30 AM",
      isMentor: true,
    },
    {
      id: 2,
      user: "John Doe",
      avatar: "JD",
      message: "Thanks! Quick question about useEffect cleanup functions.",
      time: "10:32 AM",
    },
    {
      id: 3,
      user: "Sarah Chen",
      avatar: "SC",
      message: "Great question! Cleanup functions are returned from useEffect to prevent memory leaks. Here's an example:",
      time: "10:33 AM",
      isMentor: true,
    },
    {
      id: 4,
      user: "Sarah Chen",
      avatar: "SC",
      message: `useEffect(() => {\n  const timer = setInterval(() => {\n    console.log('tick');\n  }, 1000);\n  \n  return () => clearInterval(timer);\n}, []);`,
      time: "10:33 AM",
      isMentor: true,
      isCode: true,
    },
    {
      id: 5,
      user: "Emily Wilson",
      avatar: "EW",
      message: "That's super helpful! Thanks Sarah 🙌",
      time: "10:35 AM",
    },
    {
      id: 6,
      user: "You",
      avatar: "ME",
      message: "Can you explain dependency arrays?",
      time: "10:37 AM",
    },
  ];

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, []);

  const handleSend = () => {
    if (!message.trim()) return;
    // Handle sending message
    setMessage("");
  };

  return (
    <MobileScreen>
      <div className="h-full bg-gray-50 flex flex-col">
        {/* Header */}
        <div className="bg-gradient-to-r from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-4 shadow-lg">
          <div className="flex items-center gap-3">
            <button
              onClick={() => navigate(-1)}
              className="p-2 -ml-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </button>
            <div className="flex-1">
              <h1 className="text-lg font-bold text-white">#react-hooks-class</h1>
              <p className="text-xs text-blue-200">24 members active</p>
            </div>
            <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
              <MoreVertical className="w-5 h-5 text-white" />
            </button>
          </div>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map((msg, index) => (
            <motion.div
              key={msg.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.05 }}
              className="flex gap-3"
            >
              <div className={`w-10 h-10 ${
                msg.isMentor
                  ? "bg-gradient-to-br from-orange-500 to-orange-600"
                  : msg.user === "You"
                  ? "bg-gradient-to-br from-[#14B8A6] to-[#5EEAD4]"
                  : "bg-gradient-to-br from-gray-400 to-gray-500"
              } rounded-full flex items-center justify-center flex-shrink-0`}>
                <span className="text-white text-sm font-bold">{msg.avatar}</span>
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className={`font-semibold ${
                    msg.isMentor ? "text-orange-600" : "text-gray-900"
                  }`}>
                    {msg.user}
                    {msg.isMentor && (
                      <span className="ml-2 px-2 py-0.5 bg-orange-100 text-orange-700 rounded text-xs font-semibold">
                        Mentor
                      </span>
                    )}
                  </span>
                  <span className="text-xs text-gray-500">{msg.time}</span>
                </div>
                {msg.isCode ? (
                  <div className="bg-gray-900 rounded-xl p-3 overflow-x-auto">
                    <pre className="text-sm text-green-400 font-mono whitespace-pre">
                      {msg.message}
                    </pre>
                  </div>
                ) : (
                  <p className="text-sm text-gray-700 leading-relaxed">
                    {msg.message}
                  </p>
                )}
              </div>
            </motion.div>
          ))}
          <div ref={messagesEndRef} />
        </div>

        {/* Input */}
        <div className="p-4 bg-white border-t border-gray-200">
          <div className="flex items-end gap-2">
            <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors">
              <Code className="w-5 h-5" />
            </button>
            <button className="p-2 text-gray-400 hover:text-gray-600 transition-colors">
              <ImageIcon className="w-5 h-5" />
            </button>
            <div className="flex-1 relative">
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                onKeyPress={(e) => {
                  if (e.key === "Enter" && !e.shiftKey) {
                    e.preventDefault();
                    handleSend();
                  }
                }}
                placeholder="Type a message..."
                rows={1}
                className="w-full px-4 py-2 bg-gray-100 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#14B8A6] resize-none max-h-24"
              />
            </div>
            <button
              onClick={handleSend}
              disabled={!message.trim()}
              className="p-3 bg-[#14B8A6] text-white rounded-xl hover:bg-[#0F766E] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Send className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>
    </MobileScreen>
  );
}
