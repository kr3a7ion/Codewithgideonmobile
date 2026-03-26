import { useNavigate, useParams } from "react-router";
import { Trophy, Target, CheckCircle, XCircle, Clock, Award } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function QuizResultsScreen() {
  const navigate = useNavigate();
  const { id } = useParams();

  const results = {
    score: 85,
    correct: 17,
    incorrect: 3,
    total: 20,
    timeSpent: "12:45",
    passed: true,
    passingScore: 70,
  };

  return (
    <MobileScreen>
      <div className="min-h-full bg-gradient-to-b from-white to-gray-50">
        {/* Celebration Header */}
        <div className="relative bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-16 pb-24 overflow-hidden">
          {/* Confetti-like decorations */}
          <div className="absolute inset-0 overflow-hidden">
            {[...Array(20)].map((_, i) => (
              <motion.div
                key={i}
                className="absolute w-2 h-2 bg-yellow-400 rounded-full"
                initial={{ y: -20, x: Math.random() * 400, opacity: 1 }}
                animate={{
                  y: 400,
                  rotate: 360,
                  opacity: 0,
                }}
                transition={{
                  duration: 2 + Math.random() * 2,
                  delay: Math.random() * 0.5,
                  repeat: Infinity,
                }}
              />
            ))}
          </div>

          <div className="relative text-center">
            <motion.div
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{ type: "spring", stiffness: 200 }}
              className="w-24 h-24 bg-gradient-to-br from-yellow-400 to-yellow-500 rounded-full flex items-center justify-center mx-auto mb-4 shadow-2xl"
            >
              <Trophy className="w-12 h-12 text-white" strokeWidth={2.5} />
            </motion.div>
            <motion.h1
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="text-3xl font-bold text-white mb-2"
            >
              {results.passed ? "Congratulations!" : "Keep Trying!"}
            </motion.h1>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="text-blue-200"
            >
              {results.passed
                ? "You've passed the quiz!"
                : "You can retake the quiz"}
            </motion.p>
          </div>
        </div>

        {/* Score Card */}
        <div className="px-6 -mt-16 mb-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="bg-white rounded-3xl p-8 shadow-2xl text-center"
          >
            <div className="mb-6">
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.5, type: "spring", stiffness: 200 }}
                className={`inline-flex items-center justify-center w-32 h-32 rounded-full ${
                  results.passed
                    ? "bg-gradient-to-br from-green-500 to-green-600"
                    : "bg-gradient-to-br from-orange-500 to-orange-600"
                } mb-4`}
              >
                <span className="text-5xl font-bold text-white">{results.score}%</span>
              </motion.div>
              <p className="text-gray-600">
                Your Score
                {results.passed && (
                  <span className="block text-sm text-green-600 font-semibold mt-1">
                    Passed (Required: {results.passingScore}%)
                  </span>
                )}
              </p>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-3 gap-4">
              <div className="text-center">
                <div className="w-12 h-12 bg-green-100 rounded-2xl flex items-center justify-center mx-auto mb-2">
                  <CheckCircle className="w-6 h-6 text-green-600" />
                </div>
                <p className="text-2xl font-bold text-gray-900">{results.correct}</p>
                <p className="text-xs text-gray-600">Correct</p>
              </div>
              <div className="text-center">
                <div className="w-12 h-12 bg-red-100 rounded-2xl flex items-center justify-center mx-auto mb-2">
                  <XCircle className="w-6 h-6 text-red-600" />
                </div>
                <p className="text-2xl font-bold text-gray-900">{results.incorrect}</p>
                <p className="text-xs text-gray-600">Incorrect</p>
              </div>
              <div className="text-center">
                <div className="w-12 h-12 bg-blue-100 rounded-2xl flex items-center justify-center mx-auto mb-2">
                  <Clock className="w-6 h-6 text-blue-600" />
                </div>
                <p className="text-2xl font-bold text-gray-900">{results.timeSpent}</p>
                <p className="text-xs text-gray-600">Time</p>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Achievement Badge (if passed) */}
        {results.passed && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
            className="mx-6 mb-6 bg-gradient-to-r from-yellow-50 to-orange-50 border border-yellow-200 rounded-2xl p-4"
          >
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-xl flex items-center justify-center">
                <Award className="w-6 h-6 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="font-bold text-gray-900">Achievement Unlocked!</h3>
                <p className="text-sm text-gray-600">React Hooks Master Badge</p>
              </div>
            </div>
          </motion.div>
        )}

        {/* Actions */}
        <div className="px-6 pb-6 space-y-3">
          <Button
            variant="primary"
            size="lg"
            fullWidth
            onClick={() => navigate("/dashboard")}
          >
            Back to Dashboard
          </Button>
          <Button
            variant="outline"
            size="lg"
            fullWidth
            onClick={() => navigate(`/quiz/${id}/intro`)}
          >
            {results.passed ? "Retake Quiz" : "Try Again"}
          </Button>
        </div>
      </div>
    </MobileScreen>
  );
}
