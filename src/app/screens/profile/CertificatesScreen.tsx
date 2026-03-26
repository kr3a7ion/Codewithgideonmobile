import { useNavigate } from "react-router";
import { ArrowLeft, Award, Download, Share2, Trophy, Star, CheckCircle } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function CertificatesScreen() {
  const navigate = useNavigate();

  const certificates = [
    {
      id: 1,
      title: "React Fundamentals",
      issueDate: "Feb 1, 2026",
      instructor: "Sarah Chen",
      status: "completed",
    },
    {
      id: 2,
      title: "JavaScript ES6 Mastery",
      issueDate: "Jan 15, 2026",
      instructor: "David Kim",
      status: "completed",
    },
  ];

  const badges = [
    { name: "Fast Learner", icon: "⚡", description: "Completed 5 courses in a month", earned: true },
    { name: "Perfect Score", icon: "💯", description: "Got 100% on a quiz", earned: true },
    { name: "Helpful", icon: "🤝", description: "Answered 10 questions", earned: true },
    { name: "Dedicated", icon: "🎯", description: "30 day streak", earned: false },
    { name: "Expert", icon: "🏆", description: "Complete all courses", earned: false },
  ];

  return (
    <MobileScreen>
      <div className="min-h-full bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-6">
          <div className="flex items-center gap-3 mb-2">
            <button
              onClick={() => navigate(-1)}
              className="p-2 -ml-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </button>
            <h1 className="text-2xl font-bold text-white">Achievements</h1>
          </div>
        </div>

        <div className="px-6 py-4">
          {/* Certificates Section */}
          <div className="mb-8">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold text-gray-900">Certificates</h2>
              <span className="text-sm text-gray-600">{certificates.length} earned</span>
            </div>

            <div className="space-y-3">
              {certificates.map((cert, index) => (
                <motion.div
                  key={cert.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100"
                >
                  {/* Certificate Design */}
                  <div className="bg-gradient-to-br from-yellow-50 to-orange-50 border-2 border-yellow-200 rounded-xl p-4 mb-4">
                    <div className="flex items-center justify-center mb-3">
                      <div className="w-16 h-16 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full flex items-center justify-center shadow-lg">
                        <Award className="w-8 h-8 text-white" strokeWidth={2.5} />
                      </div>
                    </div>
                    <div className="text-center">
                      <p className="text-xs font-semibold text-yellow-700 mb-1">
                        CERTIFICATE OF COMPLETION
                      </p>
                      <h3 className="text-lg font-bold text-gray-900 mb-1">
                        {cert.title}
                      </h3>
                      <p className="text-xs text-gray-600">
                        Instructor: {cert.instructor}
                      </p>
                      <p className="text-xs text-gray-500 mt-2">
                        Issued: {cert.issueDate}
                      </p>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex gap-2">
                    <Button variant="outline" size="sm" className="flex-1">
                      <Download className="w-4 h-4" />
                      Download
                    </Button>
                    <Button variant="ghost" size="sm" className="flex-1">
                      <Share2 className="w-4 h-4" />
                      Share
                    </Button>
                  </div>
                </motion.div>
              ))}
            </div>
          </div>

          {/* Badges Section */}
          <div>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold text-gray-900">Badges</h2>
              <span className="text-sm text-gray-600">
                {badges.filter(b => b.earned).length} of {badges.length}
              </span>
            </div>

            <div className="grid grid-cols-3 gap-3">
              {badges.map((badge, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.2 + index * 0.05 }}
                  className={`bg-white rounded-2xl p-4 text-center shadow-sm ${
                    badge.earned ? "border-2 border-teal-200" : "opacity-50"
                  }`}
                >
                  <div className={`text-4xl mb-2 ${
                    badge.earned ? "" : "grayscale"
                  }`}>
                    {badge.icon}
                  </div>
                  <h4 className="text-xs font-bold text-gray-900 mb-1">
                    {badge.name}
                  </h4>
                  <p className="text-xs text-gray-600 leading-tight">
                    {badge.description}
                  </p>
                  {badge.earned && (
                    <div className="mt-2 flex items-center justify-center">
                      <CheckCircle className="w-4 h-4 text-teal-600" />
                    </div>
                  )}
                </motion.div>
              ))}
            </div>
          </div>

          {/* Stats */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
            className="mt-8 bg-gradient-to-r from-purple-50 to-blue-50 border border-purple-200 rounded-2xl p-5"
          >
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl flex items-center justify-center">
                <Trophy className="w-6 h-6 text-white" />
              </div>
              <div>
                <h3 className="font-bold text-gray-900">Achievement Points</h3>
                <p className="text-sm text-gray-600">Keep learning to earn more!</p>
              </div>
            </div>
            <div className="flex items-end gap-2">
              <span className="text-4xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent">
                2,450
              </span>
              <span className="text-gray-600 mb-1.5">points</span>
            </div>
            <div className="mt-3 w-full h-2 bg-white rounded-full overflow-hidden">
              <div className="h-full bg-gradient-to-r from-purple-500 to-blue-500 w-3/4" />
            </div>
            <p className="text-xs text-gray-600 mt-2">
              750 points until next level
            </p>
          </motion.div>
        </div>
      </div>
    </MobileScreen>
  );
}
