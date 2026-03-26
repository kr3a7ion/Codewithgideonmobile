import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Mail, Lock, Eye, EyeOff } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";
import { Input } from "../../components/Input";

export function LoginScreen() {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    setLoading(true);
    // Simulate login
    await new Promise((resolve) => setTimeout(resolve, 1500));
    setLoading(false);
    navigate("/enrollment");
  };

  return (
    <MobileScreen>
      <div className="h-full flex flex-col relative overflow-hidden">
        {/* Premium Background */}
        <div className="absolute inset-0 bg-gradient-to-br from-[#0A2463] via-[#1E3A8A] to-[#14B8A6] opacity-[0.02]" />
        <div className="absolute top-0 right-0 w-72 h-72 bg-[#14B8A6] rounded-full blur-[120px] opacity-[0.08] -translate-y-20 translate-x-20" />
        <div className="absolute bottom-0 left-0 w-72 h-72 bg-[#0A2463] rounded-full blur-[120px] opacity-[0.08] translate-y-20 -translate-x-20" />

        {/* Header */}
        <div className="relative p-6 flex items-center z-10">
          <button
            onClick={() => navigate(-1)}
            className="p-2 -ml-2 hover:bg-white/50 rounded-xl transition-all duration-300 backdrop-blur-sm"
          >
            <ArrowLeft className="w-6 h-6 text-gray-900" />
          </button>
        </div>

        <div className="relative flex-1 px-8 py-4 overflow-y-auto">
          {/* Title Section */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-8"
          >
            <h1 className="text-4xl font-bold text-gray-900 mb-3 tracking-tight">
              Welcome back!
            </h1>
            <p className="text-gray-600 text-lg">
              Sign in to continue your learning journey
            </p>
          </motion.div>

          {/* Form */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="space-y-6"
          >
            {/* Email Input */}
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-3">
                Email Address
              </label>
              <div className="relative group">
                <div className="absolute inset-0 bg-gradient-to-r from-[#14B8A6]/20 to-[#0A2463]/20 rounded-2xl blur-xl opacity-0 group-focus-within:opacity-100 transition-opacity duration-300" />
                <div className="relative">
                  <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-[#14B8A6] transition-colors duration-300" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="Enter your email"
                    className="w-full pl-12 pr-4 py-4 bg-white border-2 border-gray-200 rounded-2xl focus:outline-none focus:border-[#14B8A6] focus:bg-white transition-all duration-300 shadow-sm hover:shadow-md"
                  />
                </div>
              </div>
            </div>

            {/* Password Input */}
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-3">
                Password
              </label>
              <div className="relative group">
                <div className="absolute inset-0 bg-gradient-to-r from-[#14B8A6]/20 to-[#0A2463]/20 rounded-2xl blur-xl opacity-0 group-focus-within:opacity-100 transition-opacity duration-300" />
                <div className="relative">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-[#14B8A6] transition-colors duration-300" />
                  <input
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter your password"
                    className="w-full pl-12 pr-12 py-4 bg-white border-2 border-gray-200 rounded-2xl focus:outline-none focus:border-[#14B8A6] focus:bg-white transition-all duration-300 shadow-sm hover:shadow-md"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-[#14B8A6] transition-colors duration-300"
                  >
                    {showPassword ? (
                      <EyeOff className="w-5 h-5" />
                    ) : (
                      <Eye className="w-5 h-5" />
                    )}
                  </button>
                </div>
              </div>
            </div>

            {/* Forgot Password */}
            <div className="flex justify-end">
              <button
                onClick={() => navigate("/forgot-password")}
                className="text-sm text-[#14B8A6] font-semibold hover:text-[#0F766E] transition-colors duration-300"
              >
                Forgot Password?
              </button>
            </div>

            {/* Login Button */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
            >
              <Button
                variant="primary"
                size="lg"
                fullWidth
                onClick={handleLogin}
                loading={loading}
                className="relative overflow-hidden group shadow-lg hover:shadow-xl transition-all duration-300"
              >
                <span className="relative z-10">Sign In</span>
                <div className="absolute inset-0 bg-gradient-to-r from-[#14B8A6] to-[#0A2463] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              </Button>
            </motion.div>

            {/* Divider */}
            <div className="relative my-8">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-200" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-4 bg-background text-gray-500">
                  Don't have an account?
                </span>
              </div>
            </div>

            {/* Sign Up Link */}
            <button
              onClick={() => navigate("/signup")}
              className="w-full text-center py-3 text-[#0A2463] font-semibold hover:text-[#14B8A6] transition-colors duration-300"
            >
              Create Account
            </button>
          </motion.div>
        </div>
      </div>
    </MobileScreen>
  );
}