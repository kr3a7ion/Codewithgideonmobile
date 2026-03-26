import { useState } from "react";
import { useNavigate, useParams } from "react-router";
import { Clock, ChevronLeft, ChevronRight } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function QuizQuestionScreen() {
  const navigate = useNavigate();
  const { id, questionId } = useParams();
  const [selectedAnswer, setSelectedAnswer] = useState<number | null>(null);
  const [timeLeft, setTimeLeft] = useState("14:35");

  const question = {
    number: parseInt(questionId || "1"),
    total: 10,
    text: "What is the correct way to use the useState hook in React?",
    options: [
      "const [state, setState] = useState(initialValue);",
      "const state = useState(initialValue);",
      "const setState = useState(initialValue);",
      "useState(state, setState);",
    ],
  };

  const handleNext = () => {
    if (question.number < question.total) {
      navigate(`/quiz/${id}/question/${question.number + 1}`);
    } else {
      navigate(`/quiz/${id}/results`);
    }
  };

  const handlePrevious = () => {
    if (question.number > 1) {
      navigate(`/quiz/${id}/question/${question.number - 1}`);
    }
  };

  return (
    <MobileScreen>
      <div className="h-full bg-gray-50 flex flex-col">
        {/* Header */}
        <div className="bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2 text-white">
              <Clock className="w-5 h-5" />
              <span className="font-semibold">{timeLeft}</span>
            </div>
            <div className="px-3 py-1 bg-white/20 backdrop-blur-sm rounded-full text-white text-sm font-semibold">
              {question.number} of {question.total}
            </div>
          </div>

          {/* Progress Bar */}
          <div className="w-full h-2 bg-white/20 rounded-full overflow-hidden">
            <motion.div
              className="h-full bg-gradient-to-r from-[#14B8A6] to-[#5EEAD4]"
              initial={{ width: 0 }}
              animate={{ width: `${(question.number / question.total) * 100}%` }}
              transition={{ duration: 0.3 }}
            />
          </div>
        </div>

        {/* Question */}
        <div className="flex-1 overflow-y-auto p-6">
          <motion.div
            key={question.number}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="mb-6"
          >
            <p className="text-xs font-semibold text-gray-500 mb-2">QUESTION {question.number}</p>
            <h2 className="text-xl font-bold text-gray-900 leading-relaxed">
              {question.text}
            </h2>
          </motion.div>

          {/* Options */}
          <div className="space-y-3">
            {question.options.map((option, index) => (
              <motion.button
                key={index}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 + index * 0.05 }}
                onClick={() => setSelectedAnswer(index)}
                className={`w-full p-4 rounded-2xl border-2 transition-all text-left ${
                  selectedAnswer === index
                    ? "border-[#14B8A6] bg-teal-50"
                    : "border-gray-200 bg-white hover:border-gray-300"
                }`}
              >
                <div className="flex items-start gap-3">
                  <div
                    className={`w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0 mt-0.5 ${
                      selectedAnswer === index
                        ? "border-[#14B8A6] bg-[#14B8A6]"
                        : "border-gray-300"
                    }`}
                  >
                    {selectedAnswer === index && (
                      <motion.div
                        initial={{ scale: 0 }}
                        animate={{ scale: 1 }}
                        className="w-2 h-2 bg-white rounded-full"
                      />
                    )}
                  </div>
                  <span className={`text-sm ${
                    selectedAnswer === index ? "text-gray-900 font-medium" : "text-gray-700"
                  }`}>
                    {option}
                  </span>
                </div>
              </motion.button>
            ))}
          </div>
        </div>

        {/* Navigation */}
        <div className="p-6 bg-white border-t border-gray-200">
          <div className="flex gap-3">
            <Button
              variant="outline"
              onClick={handlePrevious}
              disabled={question.number === 1}
              className="flex-1"
            >
              <ChevronLeft className="w-5 h-5" />
              Previous
            </Button>
            <Button
              variant="primary"
              onClick={handleNext}
              disabled={selectedAnswer === null}
              className="flex-1"
            >
              {question.number === question.total ? "Submit" : "Next"}
              <ChevronRight className="w-5 h-5" />
            </Button>
          </div>
        </div>
      </div>
    </MobileScreen>
  );
}
