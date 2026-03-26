import { useNavigate } from "react-router";
import { Code2, LogIn, UserPlus, Sparkles } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function WelcomeScreen() {
  const navigate = useNavigate();

  return (
    <MobileScreen>
      <div className="h-full flex flex-col relative overflow-hidden">
        {/* Premium Background Gradient */}
        <div className="absolute inset-0 bg-gradient-to-br from-white via-[#F8FAFC] to-[#EFF6FF]" />
        
        {/* Enhanced Decorative elements */}
        <div className="absolute top-20 right-0 w-72 h-72 bg-[#14B8A6] rounded-full blur-[100px] opacity-[0.15]" />
        <div className="absolute bottom-40 left-0 w-72 h-72 bg-[#0A2463] rounded-full blur-[100px] opacity-[0.15]" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-gradient-to-br from-[#14B8A6]/10 to-[#0A2463]/10 rounded-full blur-3xl" />

        <div className="relative z-10 flex-1 flex flex-col justify-between p-8">
          {/* Top Section - Logo and Brand */}
          <div className="flex-1 flex flex-col justify-center items-center">
            <motion.div
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{ type: "spring", stiffness: 200, damping: 15 }}
              className="mb-8 relative"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-[#0A2463] to-[#14B8A6] rounded-[2rem] blur-2xl opacity-30 scale-110" />
              <div className="relative w-32 h-32 bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] rounded-[2rem] flex items-center justify-center shadow-2xl">
                <Code2 className="w-16 h-16 text-white" strokeWidth={2.5} />
                <div className="absolute -top-2 -right-2 bg-[#14B8A6] rounded-full p-2 shadow-lg">
                  <Sparkles className="w-4 h-4 text-white" />
                </div>
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="text-center"
            >
              <h1 className="text-4xl font-bold text-gray-900 mb-3">
                Welcome to
              </h1>
              <h2 className="text-5xl font-bold bg-gradient-to-r from-[#0A2463] via-[#1E3A8A] to-[#14B8A6] bg-clip-text text-transparent mb-6">
                CodeWithGideon
              </h2>
              <p className="text-lg text-gray-600 max-w-sm mx-auto leading-relaxed">
                Master coding with live classes, expert mentors, and a thriving community
              </p>
            </motion.div>

            {/* Feature Pills */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="flex flex-wrap gap-2 justify-center mt-8 max-w-xs"
            >
              {["Live Classes", "AI Tutor", "Certificates"].map((feature, index) => (
                <motion.div
                  key={feature}
                  initial={{ opacity: 0, scale: 0 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.4 + index * 0.1 }}
                  className="px-4 py-2 bg-white/80 backdrop-blur-sm rounded-full border-2 border-[#14B8A6]/20 shadow-sm"
                >
                  <span className="text-sm font-medium text-gray-700">{feature}</span>
                </motion.div>
              ))}
            </motion.div>
          </div>

          {/* Bottom Section - Buttons */}
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5 }}
            className="space-y-4"
          >
            <Button
              variant="primary"
              size="lg"
              fullWidth
              onClick={() => navigate("/signup")}
              className="flex items-center justify-center gap-2 relative overflow-hidden group shadow-lg hover:shadow-xl transition-all duration-300"
            >
              <UserPlus className="w-5 h-5 relative z-10" />
              <span className="relative z-10">Create Account</span>
              <div className="absolute inset-0 bg-gradient-to-r from-[#14B8A6] to-[#0A2463] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
            </Button>

            <Button
              variant="outline"
              size="lg"
              fullWidth
              onClick={() => navigate("/login")}
              className="flex items-center justify-center gap-2 border-2 hover:border-[#14B8A6] hover:text-[#14B8A6] transition-all duration-300"
            >
              <LogIn className="w-5 h-5" />
              Sign In
            </Button>

            <p className="text-center text-sm text-gray-500 pt-4">
              By continuing, you agree to our{" "}
              <button className="text-[#0A2463] font-semibold hover:text-[#14B8A6] transition-colors">Terms</button> and{" "}
              <button className="text-[#0A2463] font-semibold hover:text-[#14B8A6] transition-colors">Privacy Policy</button>
            </p>
          </motion.div>
        </div>
      </div>
    </MobileScreen>
  );
}