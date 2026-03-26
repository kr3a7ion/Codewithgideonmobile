import { useState } from "react";
import { useNavigate, useParams } from "react-router";
import {
  ArrowLeft,
  Play,
  Pause,
  SkipForward,
  SkipBack,
  Volume2,
  Settings,
  Maximize,
  CheckCircle,
  MessageCircle,
  Download,
  Share2,
  ChevronRight,
} from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function RecordedPlayerScreen() {
  const navigate = useNavigate();
  const { id } = useParams();
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(35);
  const [showCompleteModal, setShowCompleteModal] = useState(false);

  const lesson = {
    title: "JavaScript ES6 Features",
    instructor: "David Kim",
    duration: "45:30",
    watched: "15:45",
    completed: 35,
    description:
      "Learn modern JavaScript ES6+ features including arrow functions, destructuring, spread operator, and more.",
    resources: [
      { name: "Code Examples", type: "GitHub" },
      { name: "ES6 Cheatsheet.pdf", type: "PDF" },
    ],
  };

  const handleMarkComplete = () => {
    setShowCompleteModal(true);
  };

  return (
    <MobileScreen>
      <div className="h-full bg-black flex flex-col">
        {/* Video Player Area */}
        <div className="relative bg-gray-900 aspect-video">
          {/* Mock Video Placeholder */}
          <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-gray-800 to-gray-900">
            <div className="text-center">
              <div className="w-20 h-20 bg-white/10 backdrop-blur-sm rounded-full flex items-center justify-center mx-auto mb-3">
                {isPlaying ? (
                  <Pause className="w-10 h-10 text-white" />
                ) : (
                  <Play className="w-10 h-10 text-white ml-1" />
                )}
              </div>
              <p className="text-white text-sm opacity-75">
                {isPlaying ? "Playing..." : "Paused"}
              </p>
            </div>
          </div>

          {/* Top Bar */}
          <div className="absolute top-0 left-0 right-0 p-4 bg-gradient-to-b from-black/60 to-transparent">
            <div className="flex items-center justify-between">
              <button
                onClick={() => navigate(-1)}
                className="p-2 bg-white/10 backdrop-blur-sm rounded-lg hover:bg-white/20"
              >
                <ArrowLeft className="w-5 h-5 text-white" />
              </button>
              <div className="flex gap-2">
                <button className="p-2 bg-white/10 backdrop-blur-sm rounded-lg hover:bg-white/20">
                  <Share2 className="w-5 h-5 text-white" />
                </button>
                <button className="p-2 bg-white/10 backdrop-blur-sm rounded-lg hover:bg-white/20">
                  <Settings className="w-5 h-5 text-white" />
                </button>
              </div>
            </div>
          </div>

          {/* Progress Bar */}
          <div className="absolute bottom-14 left-0 right-0 px-4">
            <div className="flex items-center gap-2 text-white text-xs mb-2">
              <span>{lesson.watched}</span>
              <div className="flex-1 h-1 bg-white/30 rounded-full overflow-hidden">
                <motion.div
                  className="h-full bg-[#14B8A6]"
                  initial={{ width: 0 }}
                  animate={{ width: `${progress}%` }}
                />
              </div>
              <span>{lesson.duration}</span>
            </div>
          </div>

          {/* Controls */}
          <div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/80 to-transparent">
            <div className="flex items-center justify-center gap-6">
              <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
                <SkipBack className="w-6 h-6 text-white" />
              </button>
              <button
                onClick={() => setIsPlaying(!isPlaying)}
                className="p-4 bg-[#14B8A6] rounded-full hover:bg-[#0F766E] transition-colors"
              >
                {isPlaying ? (
                  <Pause className="w-7 h-7 text-white" />
                ) : (
                  <Play className="w-7 h-7 text-white ml-0.5" />
                )}
              </button>
              <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
                <SkipForward className="w-6 h-6 text-white" />
              </button>
            </div>
          </div>
        </div>

        {/* Content Area */}
        <div className="flex-1 bg-white overflow-y-auto">
          <div className="p-6">
            {/* Title & Info */}
            <div className="mb-6">
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                {lesson.title}
              </h1>
              <p className="text-gray-600 mb-3">{lesson.description}</p>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gradient-to-br from-[#14B8A6] to-[#5EEAD4] rounded-full flex items-center justify-center">
                  <span className="text-sm font-bold text-white">
                    {lesson.instructor.split(" ").map((n) => n[0]).join("")}
                  </span>
                </div>
                <div>
                  <p className="font-semibold text-gray-900">{lesson.instructor}</p>
                  <p className="text-sm text-gray-600">{lesson.duration} • Recording</p>
                </div>
              </div>
            </div>

            {/* Progress */}
            <div className="bg-gradient-to-r from-teal-50 to-blue-50 rounded-2xl p-4 mb-6">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-semibold text-gray-700">
                  Your Progress
                </span>
                <span className="text-sm font-bold text-[#14B8A6]">
                  {progress}% Complete
                </span>
              </div>
              <div className="w-full h-2 bg-white rounded-full overflow-hidden">
                <motion.div
                  className="h-full bg-gradient-to-r from-[#14B8A6] to-[#5EEAD4]"
                  initial={{ width: 0 }}
                  animate={{ width: `${progress}%` }}
                  transition={{ duration: 0.5 }}
                />
              </div>
            </div>

            {/* Actions */}
            <div className="grid grid-cols-3 gap-3 mb-6">
              <button
                onClick={handleMarkComplete}
                className="flex flex-col items-center gap-2 p-4 bg-green-50 rounded-2xl hover:bg-green-100 transition-colors"
              >
                <CheckCircle className="w-6 h-6 text-green-600" />
                <span className="text-xs font-medium text-green-700">
                  Mark Complete
                </span>
              </button>
              <button
                onClick={() => navigate(`/ai-tutor/${id}`)}
                className="flex flex-col items-center gap-2 p-4 bg-purple-50 rounded-2xl hover:bg-purple-100 transition-colors"
              >
                <MessageCircle className="w-6 h-6 text-purple-600" />
                <span className="text-xs font-medium text-purple-700">
                  Ask AI Tutor
                </span>
              </button>
              <button
                onClick={() => navigate("/resources")}
                className="flex flex-col items-center gap-2 p-4 bg-blue-50 rounded-2xl hover:bg-blue-100 transition-colors"
              >
                <Download className="w-6 h-6 text-blue-600" />
                <span className="text-xs font-medium text-blue-700">
                  Resources
                </span>
              </button>
            </div>

            {/* Resources */}
            <div className="bg-gray-50 rounded-2xl p-4">
              <h3 className="font-bold text-gray-900 mb-3">Lesson Resources</h3>
              <div className="space-y-2">
                {lesson.resources.map((resource, index) => (
                  <button
                    key={index}
                    className="w-full flex items-center justify-between p-3 bg-white rounded-xl hover:shadow-sm transition-shadow"
                  >
                    <div className="flex items-center gap-3">
                      <Download className="w-5 h-5 text-[#0A2463]" />
                      <div className="text-left">
                        <p className="text-sm font-medium text-gray-900">
                          {resource.name}
                        </p>
                        <p className="text-xs text-gray-500">{resource.type}</p>
                      </div>
                    </div>
                    <ChevronRight className="w-5 h-5 text-gray-400" />
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Complete Modal */}
        {showCompleteModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="absolute inset-0 bg-black/70 flex items-center justify-center p-6 z-50"
            onClick={() => setShowCompleteModal(false)}
          >
            <motion.div
              initial={{ scale: 0.9, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              onClick={(e) => e.stopPropagation()}
              className="bg-white rounded-3xl p-8 w-full max-w-sm text-center"
            >
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.2, type: "spring" }}
                className="w-20 h-20 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center mx-auto mb-4"
              >
                <CheckCircle className="w-12 h-12 text-white" strokeWidth={2.5} />
              </motion.div>
              <h3 className="text-2xl font-bold text-gray-900 mb-2">
                Lesson Complete!
              </h3>
              <p className="text-gray-600 mb-6">
                Great job! You've completed this lesson. Keep up the momentum!
              </p>
              <Button
                variant="primary"
                fullWidth
                onClick={() => {
                  setShowCompleteModal(false);
                  navigate("/dashboard");
                }}
                className="mb-2"
              >
                Back to Dashboard
              </Button>
              <button
                onClick={() => setShowCompleteModal(false)}
                className="text-gray-600 hover:text-gray-900"
              >
                Continue Watching
              </button>
            </motion.div>
          </motion.div>
        )}
      </div>
    </MobileScreen>
  );
}