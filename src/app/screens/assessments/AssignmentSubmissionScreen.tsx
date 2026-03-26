import { useState } from "react";
import { useNavigate, useParams } from "react-router";
import { ArrowLeft, Upload, FileText, CheckCircle, X } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function AssignmentSubmissionScreen() {
  const navigate = useNavigate();
  const { id } = useParams();
  const [uploadedFile, setUploadedFile] = useState<string | null>(null);
  const [notes, setNotes] = useState("");
  const [showSuccessModal, setShowSuccessModal] = useState(false);

  const assignment = {
    title: "Build a Todo App with React Hooks",
    description:
      "Create a fully functional todo application using React Hooks. The app should support adding, completing, and deleting tasks.",
    dueDate: "Feb 15, 2026",
    points: 100,
    requirements: [
      "Use useState for state management",
      "Implement useEffect for side effects",
      "Create custom hooks for reusable logic",
      "Include proper error handling",
      "Write clean, commented code",
    ],
  };

  const handleSubmit = () => {
    setShowSuccessModal(true);
  };

  return (
    <MobileScreen>
      <div className="min-h-full bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-6">
          <div className="flex items-center gap-3 mb-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 -ml-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </button>
            <h1 className="text-xl font-bold text-white">Submit Assignment</h1>
          </div>
        </div>

        <div className="px-6 py-4">
          {/* Assignment Info */}
          <div className="bg-white rounded-2xl p-5 shadow-sm mb-4">
            <h2 className="text-xl font-bold text-gray-900 mb-2">
              {assignment.title}
            </h2>
            <p className="text-sm text-gray-600 mb-4">
              {assignment.description}
            </p>
            <div className="flex items-center gap-4 text-sm">
              <div className="flex items-center gap-1 text-orange-600">
                <FileText className="w-4 h-4" />
                <span className="font-semibold">{assignment.points} points</span>
              </div>
              <div className="text-gray-600">
                Due: <span className="font-semibold">{assignment.dueDate}</span>
              </div>
            </div>
          </div>

          {/* Requirements */}
          <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-4">
            <h3 className="font-bold text-blue-900 mb-3">Requirements</h3>
            <ul className="space-y-2">
              {assignment.requirements.map((req, index) => (
                <li key={index} className="flex gap-2 text-sm text-blue-800">
                  <span className="text-blue-600">•</span>
                  <span>{req}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* File Upload */}
          <div className="bg-white rounded-2xl p-5 shadow-sm mb-4">
            <h3 className="font-bold text-gray-900 mb-3">Upload Your Work</h3>
            
            {!uploadedFile ? (
              <button
                onClick={() => setUploadedFile("todo-app-project.zip")}
                className="w-full border-2 border-dashed border-gray-300 rounded-2xl p-8 hover:border-[#14B8A6] hover:bg-teal-50 transition-colors"
              >
                <Upload className="w-10 h-10 text-gray-400 mx-auto mb-3" />
                <p className="font-semibold text-gray-700 mb-1">
                  Upload your files
                </p>
                <p className="text-sm text-gray-500">
                  ZIP, GitHub link, or code files
                </p>
              </button>
            ) : (
              <div className="bg-teal-50 border border-teal-200 rounded-2xl p-4 flex items-center gap-3">
                <div className="w-12 h-12 bg-teal-100 rounded-xl flex items-center justify-center">
                  <FileText className="w-6 h-6 text-teal-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-gray-900 truncate">
                    {uploadedFile}
                  </p>
                  <p className="text-sm text-gray-600">2.4 MB</p>
                </div>
                <button
                  onClick={() => setUploadedFile(null)}
                  className="p-1 hover:bg-teal-100 rounded-lg"
                >
                  <X className="w-5 h-5 text-gray-600" />
                </button>
              </div>
            )}
          </div>

          {/* Notes */}
          <div className="bg-white rounded-2xl p-5 shadow-sm mb-4">
            <h3 className="font-bold text-gray-900 mb-3">Additional Notes</h3>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Add any notes or comments for your instructor..."
              className="w-full h-32 px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#14B8A6] resize-none"
            />
          </div>

          {/* Submit Button */}
          <Button
            variant="primary"
            size="lg"
            fullWidth
            onClick={handleSubmit}
            disabled={!uploadedFile}
          >
            Submit Assignment
          </Button>
        </div>

        {/* Success Modal */}
        <AnimatePresence>
          {showSuccessModal && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-black/70 flex items-center justify-center p-6 z-50"
              onClick={() => setShowSuccessModal(false)}
            >
              <motion.div
                initial={{ scale: 0.9, y: 20 }}
                animate={{ scale: 1, y: 0 }}
                exit={{ scale: 0.9, y: 20 }}
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
                  Submitted!
                </h3>
                <p className="text-gray-600 mb-6">
                  Your assignment has been submitted successfully. Your instructor
                  will review it soon.
                </p>
                <Button
                  variant="primary"
                  fullWidth
                  onClick={() => navigate("/dashboard")}
                >
                  Back to Dashboard
                </Button>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </MobileScreen>
  );
}
