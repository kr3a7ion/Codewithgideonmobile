import { useNavigate, useParams } from "react-router";
import { ArrowLeft, Clock, FileText, Trophy, CheckCircle } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function QuizIntroScreen() {
  const navigate = useNavigate();
  const { id } = useParams();

  const quiz = {
    title: "React Hooks Assessment",
    description: "Test your understanding of React Hooks concepts",
    questions: 10,
    duration: "15 minutes",
    passingScore: 70,
    attempts: "Unlimited",
  };

  return (
    <MobileScreen>
      <div className="min-h-full bg-gradient-to-b from-white to-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-16">
          <button
            onClick={() => navigate(-1)}
            className="p-2 -ml-2 mb-6 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <div className="text-center">
            <div className="w-20 h-20 bg-white rounded-3xl flex items-center justify-center mx-auto mb-4 shadow-xl">
              <FileText className="w-10 h-10 text-[#0A2463]" />
            </div>
            <h1 className="text-2xl font-bold text-white mb-2">{quiz.title}</h1>
            <p className="text-blue-200">{quiz.description}</p>
          </div>
        </div>

        {/* Content */}
        <div className="px-6 -mt-8">
          {/* Info Card */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-3xl p-6 shadow-xl mb-6"
          >
            <h2 className="font-bold text-gray-900 mb-4">Quiz Details</h2>
            <div className="space-y-3">
              {[
                { icon: FileText, label: "Questions", value: quiz.questions },
                { icon: Clock, label: "Duration", value: quiz.duration },
                { icon: Trophy, label: "Passing Score", value: `${quiz.passingScore}%` },
                { icon: CheckCircle, label: "Attempts", value: quiz.attempts },
              ].map((item, index) => (
                <div key={index} className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-teal-50 rounded-xl flex items-center justify-center">
                    <item.icon className="w-5 h-5 text-teal-600" />
                  </div>
                  <div className="flex-1">
                    <p className="text-sm text-gray-600">{item.label}</p>
                    <p className="font-semibold text-gray-900">{item.value}</p>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>

          {/* Instructions */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-blue-50 border border-blue-200 rounded-2xl p-5 mb-6"
          >
            <h3 className="font-bold text-blue-900 mb-3">Instructions</h3>
            <ul className="space-y-2 text-sm text-blue-800">
              <li className="flex gap-2">
                <span>•</span>
                <span>Read each question carefully before answering</span>
              </li>
              <li className="flex gap-2">
                <span>•</span>
                <span>You can navigate between questions</span>
              </li>
              <li className="flex gap-2">
                <span>•</span>
                <span>Make sure to submit before time runs out</span>
              </li>
              <li className="flex gap-2">
                <span>•</span>
                <span>Review your answers before final submission</span>
              </li>
            </ul>
          </motion.div>

          {/* Start Button */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            <Button
              variant="primary"
              size="lg"
              fullWidth
              onClick={() => navigate(`/quiz/${id}/question/1`)}
            >
              Start Quiz
            </Button>
          </motion.div>
        </div>
      </div>
    </MobileScreen>
  );
}
