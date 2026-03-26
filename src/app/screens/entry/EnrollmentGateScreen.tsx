import { useState } from "react";
import { useNavigate } from "react-router";
import { CheckCircle, Clock, AlertCircle, ExternalLink } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

type EnrollmentStatus = "enrolled" | "pending" | "not-registered";

export function EnrollmentGateScreen() {
  const navigate = useNavigate();
  // Mock status - in real app, this would come from auth/API
  const [status] = useState<EnrollmentStatus>("enrolled"); // Change to test different states

  const handleOpenWeb = () => {
    // Mock opening web registration
    alert("Would open web registration in browser");
  };

  if (status === "enrolled") {
    return (
      <MobileScreen>
        <div className="h-full flex items-center justify-center p-8">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center"
          >
            <div className="w-24 h-24 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center mx-auto mb-6 shadow-2xl">
              <CheckCircle className="w-14 h-14 text-white" strokeWidth={2.5} />
            </div>
            <h1 className="text-3xl font-bold text-gray-900 mb-3">
              You're All Set!
            </h1>
            <p className="text-lg text-gray-600 mb-8">
              Your enrollment is confirmed. Let's start learning!
            </p>
            <Button
              variant="primary"
              size="lg"
              fullWidth
              onClick={() => navigate("/dashboard")}
            >
              Go to Dashboard
            </Button>
          </motion.div>
        </div>
      </MobileScreen>
    );
  }

  if (status === "pending") {
    return (
      <MobileScreen>
        <div className="h-full flex items-center justify-center p-8">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="text-center"
          >
            <div className="w-24 h-24 bg-gradient-to-br from-orange-500 to-orange-600 rounded-full flex items-center justify-center mx-auto mb-6 shadow-2xl">
              <Clock className="w-14 h-14 text-white" strokeWidth={2.5} />
            </div>
            <h1 className="text-3xl font-bold text-gray-900 mb-3">
              Payment Pending
            </h1>
            <p className="text-lg text-gray-600 mb-8">
              Complete your payment to access all courses and features
            </p>
            
            <div className="bg-orange-50 border border-orange-200 rounded-2xl p-4 mb-6">
              <p className="text-sm text-orange-900">
                <strong>Note:</strong> Payment must be completed on our web platform
              </p>
            </div>

            <Button
              variant="primary"
              size="lg"
              fullWidth
              onClick={handleOpenWeb}
              className="mb-3"
            >
              <ExternalLink className="w-5 h-5 mr-2" />
              Complete Payment on Web
            </Button>
            
            <button
              onClick={() => navigate("/login")}
              className="text-gray-600 hover:text-gray-900"
            >
              Back to Login
            </button>
          </motion.div>
        </div>
      </MobileScreen>
    );
  }

  // Not Registered
  return (
    <MobileScreen>
      <div className="h-full flex items-center justify-center p-8">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center"
        >
          <div className="w-24 h-24 bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] rounded-full flex items-center justify-center mx-auto mb-6 shadow-2xl">
            <AlertCircle className="w-14 h-14 text-white" strokeWidth={2.5} />
          </div>
          <h1 className="text-3xl font-bold text-gray-900 mb-3">
            Registration Required
          </h1>
          <p className="text-lg text-gray-600 mb-8">
            Register on our web platform to access courses and start learning
          </p>
          
          <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-6 text-left">
            <h3 className="font-semibold text-blue-900 mb-2">What you'll get:</h3>
            <ul className="space-y-1 text-sm text-blue-800">
              <li>✓ Live interactive classes</li>
              <li>✓ Access to recorded lessons</li>
              <li>✓ AI tutor support</li>
              <li>✓ Community access</li>
              <li>✓ Industry certificates</li>
            </ul>
          </div>

          <Button
            variant="primary"
            size="lg"
            fullWidth
            onClick={handleOpenWeb}
            className="mb-3"
          >
            <ExternalLink className="w-5 h-5 mr-2" />
            Register on Web
          </Button>
          
          <button
            onClick={() => navigate("/welcome")}
            className="text-gray-600 hover:text-gray-900"
          >
            Back
          </button>
        </motion.div>
      </div>
    </MobileScreen>
  );
}
