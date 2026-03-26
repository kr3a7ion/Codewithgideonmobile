import { useState } from "react";
import { useNavigate, useParams } from "react-router";
import {
  Video,
  Mic,
  MicOff,
  MessageSquare,
  Hand,
  HelpCircle,
  FileText,
  X,
  Send,
  ChevronDown,
} from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function LiveSessionScreen() {
  const navigate = useNavigate();
  const { id } = useParams();
  const [isMuted, setIsMuted] = useState(false);
  const [showChat, setShowChat] = useState(false);
  const [showHandModal, setShowHandModal] = useState(false);
  const [showAskModal, setShowAskModal] = useState(false);
  const [showNotesModal, setShowNotesModal] = useState(false);
  const [showLeaveModal, setShowLeaveModal] = useState(false);
  const [message, setMessage] = useState("");
  const [question, setQuestion] = useState("");
  const [notes, setNotes] = useState("");

  const [chatMessages] = useState([
    { id: 1, user: "Sarah Chen", message: "Welcome everyone!", isMentor: true, time: "3:01 PM" },
    { id: 2, user: "John Doe", message: "Excited to learn!", isMentor: false, time: "3:02 PM" },
    { id: 3, user: "You", message: "Thank you for the class!", isMentor: false, time: "3:05 PM" },
  ]);

  return (
    <MobileScreen>
      <div className="h-full bg-black flex flex-col">
        {/* Video Area */}
        <div className="flex-1 relative bg-gradient-to-br from-gray-900 to-gray-800">
          {/* Mock Video Placeholder */}
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="text-center">
              <div className="w-24 h-24 bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] rounded-full flex items-center justify-center mx-auto mb-4">
                <Video className="w-12 h-12 text-white" />
              </div>
              <p className="text-white text-lg font-semibold">React Hooks Deep Dive</p>
              <p className="text-gray-400 text-sm">Live Session in Progress</p>
            </div>
          </div>

          {/* Top Bar */}
          <div className="absolute top-0 left-0 right-0 p-4 bg-gradient-to-b from-black/60 to-transparent">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 bg-red-500 rounded-full animate-pulse" />
                <span className="text-white text-sm font-semibold">45:23</span>
              </div>
              <div className="flex items-center gap-2 text-white text-sm">
                <div className="w-2 h-2 bg-green-500 rounded-full" />
                <span>24 participants</span>
              </div>
            </div>
          </div>

          {/* Chat Panel Overlay */}
          <AnimatePresence>
            {showChat && (
              <motion.div
                initial={{ x: "100%" }}
                animate={{ x: 0 }}
                exit={{ x: "100%" }}
                transition={{ type: "spring", damping: 25 }}
                className="absolute top-0 right-0 bottom-20 w-full bg-white shadow-2xl flex flex-col"
              >
                {/* Chat Header */}
                <div className="p-4 bg-gradient-to-r from-[#0A2463] to-[#1E3A8A] flex items-center justify-between">
                  <h3 className="text-white font-bold">Live Chat</h3>
                  <button
                    onClick={() => setShowChat(false)}
                    className="p-1 hover:bg-white/10 rounded-lg"
                  >
                    <X className="w-5 h-5 text-white" />
                  </button>
                </div>

                {/* Messages */}
                <div className="flex-1 overflow-y-auto p-4 space-y-3">
                  {chatMessages.map((msg) => (
                    <div key={msg.id} className="flex gap-2">
                      <div className={`w-8 h-8 ${
                        msg.isMentor
                          ? "bg-gradient-to-br from-orange-500 to-orange-600"
                          : "bg-gradient-to-br from-gray-400 to-gray-500"
                      } rounded-full flex items-center justify-center flex-shrink-0`}>
                        <span className="text-white text-xs font-bold">
                          {msg.user.charAt(0)}
                        </span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-0.5">
                          <span className={`text-sm font-semibold ${
                            msg.isMentor ? "text-orange-600" : "text-gray-900"
                          }`}>
                            {msg.user}
                            {msg.isMentor && (
                              <span className="ml-1 text-xs px-1.5 py-0.5 bg-orange-100 text-orange-700 rounded">
                                Mentor
                              </span>
                            )}
                          </span>
                          <span className="text-xs text-gray-400">{msg.time}</span>
                        </div>
                        <p className="text-sm text-gray-700">{msg.message}</p>
                      </div>
                    </div>
                  ))}
                </div>

                {/* Input */}
                <div className="p-4 border-t border-gray-200">
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={message}
                      onChange={(e) => setMessage(e.target.value)}
                      placeholder="Type a message..."
                      className="flex-1 px-4 py-2 bg-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#14B8A6]"
                    />
                    <button className="p-2 bg-[#14B8A6] text-white rounded-lg hover:bg-[#0F766E] transition-colors">
                      <Send className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Bottom Controls */}
        <div className="bg-gray-900 p-4">
          <div className="flex items-center justify-between mb-4">
            {/* Action Buttons */}
            <div className="flex gap-2">
              <button
                onClick={() => setShowHandModal(true)}
                className="flex flex-col items-center gap-1 px-3 py-2 bg-gray-800 rounded-xl hover:bg-gray-700 transition-colors"
              >
                <Hand className="w-5 h-5 text-yellow-400" />
                <span className="text-xs text-gray-300">Raise Hand</span>
              </button>
              <button
                onClick={() => setShowAskModal(true)}
                className="flex flex-col items-center gap-1 px-3 py-2 bg-gray-800 rounded-xl hover:bg-gray-700 transition-colors"
              >
                <HelpCircle className="w-5 h-5 text-teal-400" />
                <span className="text-xs text-gray-300">Ask Mentor</span>
              </button>
              <button
                onClick={() => setShowNotesModal(true)}
                className="flex flex-col items-center gap-1 px-3 py-2 bg-gray-800 rounded-xl hover:bg-gray-700 transition-colors"
              >
                <FileText className="w-5 h-5 text-blue-400" />
                <span className="text-xs text-gray-300">Notes</span>
              </button>
            </div>
          </div>

          {/* Main Controls */}
          <div className="flex items-center justify-center gap-4">
            <button
              onClick={() => setIsMuted(!isMuted)}
              className={`p-4 ${
                isMuted ? "bg-red-500" : "bg-gray-800"
              } rounded-full hover:opacity-90 transition-all`}
            >
              {isMuted ? (
                <MicOff className="w-6 h-6 text-white" />
              ) : (
                <Mic className="w-6 h-6 text-white" />
              )}
            </button>

            <button
              onClick={() => setShowChat(!showChat)}
              className="p-4 bg-gray-800 rounded-full hover:bg-gray-700 transition-colors relative"
            >
              <MessageSquare className="w-6 h-6 text-white" />
              <span className="absolute top-2 right-2 w-3 h-3 bg-teal-500 rounded-full" />
            </button>

            <button
              onClick={() => setShowLeaveModal(true)}
              className="p-4 bg-red-500 rounded-full hover:bg-red-600 transition-colors"
            >
              <X className="w-6 h-6 text-white" />
            </button>
          </div>
        </div>

        {/* Modals */}
        <AnimatePresence>
          {/* Raise Hand Modal */}
          {showHandModal && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-black/70 flex items-center justify-center p-6 z-50"
              onClick={() => setShowHandModal(false)}
            >
              <motion.div
                initial={{ scale: 0.9, y: 20 }}
                animate={{ scale: 1, y: 0 }}
                exit={{ scale: 0.9, y: 20 }}
                onClick={(e) => e.stopPropagation()}
                className="bg-white rounded-2xl p-6 w-full max-w-sm"
              >
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <Hand className="w-8 h-8 text-yellow-600" />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">
                    Raise Your Hand
                  </h3>
                  <p className="text-gray-600">
                    The instructor will be notified and may call on you
                  </p>
                </div>
                <div className="flex gap-3">
                  <Button
                    variant="outline"
                    fullWidth
                    onClick={() => setShowHandModal(false)}
                  >
                    Cancel
                  </Button>
                  <Button
                    variant="secondary"
                    fullWidth
                    onClick={() => {
                      setShowHandModal(false);
                      // Show success toast
                    }}
                  >
                    Confirm
                  </Button>
                </div>
              </motion.div>
            </motion.div>
          )}

          {/* Ask Mentor Modal */}
          {showAskModal && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-black/70 flex items-end justify-center p-6 z-50"
              onClick={() => setShowAskModal(false)}
            >
              <motion.div
                initial={{ y: "100%" }}
                animate={{ y: 0 }}
                exit={{ y: "100%" }}
                onClick={(e) => e.stopPropagation()}
                className="bg-white rounded-t-3xl p-6 w-full max-w-md"
              >
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xl font-bold text-gray-900">Ask Mentor</h3>
                  <button
                    onClick={() => setShowAskModal(false)}
                    className="p-1 hover:bg-gray-100 rounded-lg"
                  >
                    <X className="w-6 h-6 text-gray-600" />
                  </button>
                </div>
                <textarea
                  value={question}
                  onChange={(e) => setQuestion(e.target.value)}
                  placeholder="Type your question here..."
                  className="w-full h-32 px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#14B8A6] resize-none mb-4"
                />
                <Button
                  variant="secondary"
                  fullWidth
                  onClick={() => {
                    setShowAskModal(false);
                    setQuestion("");
                  }}
                >
                  Send Question
                </Button>
              </motion.div>
            </motion.div>
          )}

          {/* Notes Modal */}
          {showNotesModal && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-white z-50 flex flex-col"
            >
              <div className="p-4 bg-gradient-to-r from-[#0A2463] to-[#1E3A8A] flex items-center justify-between">
                <h3 className="text-white font-bold text-lg">My Notes</h3>
                <button
                  onClick={() => setShowNotesModal(false)}
                  className="p-2 hover:bg-white/10 rounded-lg"
                >
                  <ChevronDown className="w-6 h-6 text-white" />
                </button>
              </div>
              <div className="flex-1 p-4">
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Take notes during the class..."
                  className="w-full h-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#14B8A6] resize-none"
                />
              </div>
            </motion.div>
          )}

          {/* Leave Confirmation Modal */}
          {showLeaveModal && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-black/70 flex items-center justify-center p-6 z-50"
              onClick={() => setShowLeaveModal(false)}
            >
              <motion.div
                initial={{ scale: 0.9, y: 20 }}
                animate={{ scale: 1, y: 0 }}
                exit={{ scale: 0.9, y: 20 }}
                onClick={(e) => e.stopPropagation()}
                className="bg-white rounded-2xl p-6 w-full max-w-sm"
              >
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <X className="w-8 h-8 text-red-600" />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">
                    Leave Class?
                  </h3>
                  <p className="text-gray-600">
                    Are you sure you want to leave this live session?
                  </p>
                </div>
                <div className="flex gap-3">
                  <Button
                    variant="outline"
                    fullWidth
                    onClick={() => setShowLeaveModal(false)}
                  >
                    Cancel
                  </Button>
                  <Button
                    variant="danger"
                    fullWidth
                    onClick={() => navigate("/dashboard")}
                  >
                    Leave
                  </Button>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </MobileScreen>
  );
}
