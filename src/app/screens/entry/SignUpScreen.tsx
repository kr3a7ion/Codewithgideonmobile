import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Mail, Lock, Eye, EyeOff, CheckCircle2, Sparkles } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function SignUpScreen() {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSignUp = async () => {
    if (password !== confirmPassword) {
      alert("Passwords don't match!");
      return;
    }
    
    setLoading(true);
    // Simulate account creation
    await new Promise((resolve) => setTimeout(resolve, 1500));
    setLoading(false);
    
    // Redirect to web for payment and full registration
    // In production, this would be the actual web URL
    window.location.href = `https://codewithgideon.com/complete-registration?email=${encodeURIComponent(email)}&temp=true`;
  };

  const passwordStrength = password.length >= 8 ? "strong" : password.length >= 5 ? "medium" : "weak";

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
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-[#14B8A6]/10 to-[#0A2463]/10 rounded-full mb-4 backdrop-blur-sm border border-[#14B8A6]/20">
              <Sparkles className="w-4 h-4 text-[#14B8A6]" />
              <span className="text-sm font-medium text-[#0A2463]">
                Start Your Journey
              </span>
            </div>
            <h1 className="text-4xl font-bold text-gray-900 mb-3 tracking-tight">
              Create Account
            </h1>
            <p className="text-gray-600 text-lg">
              Begin your learning adventure with CodeWithGideon
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
                    placeholder="you@example.com"
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
                    placeholder="Create a strong password"
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
              {/* Password Strength Indicator */}
              {password && (
                <motion.div
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="mt-3 space-y-2"
                >
                  <div className="flex gap-2">
                    <div className={`h-1.5 flex-1 rounded-full ${passwordStrength === "weak" ? "bg-red-500" : "bg-gray-200"}`} />
                    <div className={`h-1.5 flex-1 rounded-full ${passwordStrength === "medium" || passwordStrength === "strong" ? "bg-yellow-500" : "bg-gray-200"}`} />
                    <div className={`h-1.5 flex-1 rounded-full ${passwordStrength === "strong" ? "bg-green-500" : "bg-gray-200"}`} />
                  </div>
                  <p className="text-xs text-gray-600">
                    {passwordStrength === "weak" && "Password is too weak"}
                    {passwordStrength === "medium" && "Password strength: Good"}
                    {passwordStrength === "strong" && "Password strength: Strong"}
                  </p>
                </motion.div>
              )}
            </div>

            {/* Confirm Password Input */}
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-3">
                Confirm Password
              </label>
              <div className="relative group">
                <div className="absolute inset-0 bg-gradient-to-r from-[#14B8A6]/20 to-[#0A2463]/20 rounded-2xl blur-xl opacity-0 group-focus-within:opacity-100 transition-opacity duration-300" />
                <div className="relative">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 group-focus-within:text-[#14B8A6] transition-colors duration-300" />
                  <input
                    type={showConfirmPassword ? "text" : "password"}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="Re-enter your password"
                    className="w-full pl-12 pr-12 py-4 bg-white border-2 border-gray-200 rounded-2xl focus:outline-none focus:border-[#14B8A6] focus:bg-white transition-all duration-300 shadow-sm hover:shadow-md"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-[#14B8A6] transition-colors duration-300"
                  >
                    {showConfirmPassword ? (
                      <EyeOff className="w-5 h-5" />
                    ) : (
                      <Eye className="w-5 h-5" />
                    )}
                  </button>
                </div>
              </div>
              {confirmPassword && password !== confirmPassword && (
                <motion.p
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="text-xs text-red-600 mt-2"
                >
                  Passwords don't match
                </motion.p>
              )}
            </div>

            {/* Benefits List */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="bg-gradient-to-br from-[#14B8A6]/5 to-[#0A2463]/5 rounded-2xl p-5 border border-[#14B8A6]/10 backdrop-blur-sm"
            >
              <p className="text-sm font-semibold text-gray-900 mb-3">
                What you'll get:
              </p>
              <div className="space-y-2">
                {[
                  "Access to live coding sessions",
                  "Complete course library",
                  "AI-powered tutor assistance",
                  "Community support & networking"
                ].map((benefit, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.3 + index * 0.1 }}
                    className="flex items-center gap-2"
                  >
                    <CheckCircle2 className="w-4 h-4 text-[#14B8A6] flex-shrink-0" />
                    <span className="text-sm text-gray-700">{benefit}</span>
                  </motion.div>
                ))}
              </div>
            </motion.div>

            {/* Sign Up Button */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
            >
              <Button
                variant="primary"
                size="lg"
                fullWidth
                onClick={handleSignUp}
                loading={loading}
                disabled={!email || !password || !confirmPassword || password !== confirmPassword}
                className="relative overflow-hidden group shadow-lg hover:shadow-xl transition-all duration-300"
              >
                <span className="relative z-10">Continue to Payment</span>
                <div className="absolute inset-0 bg-gradient-to-r from-[#14B8A6] to-[#0A2463] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              </Button>
              <p className="text-xs text-center text-gray-500 mt-3">
                You'll be redirected to complete payment on our secure website
              </p>
            </motion.div>

            {/* Terms */}
            <motion.p
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.4 }}
              className="text-xs text-center text-gray-500 px-4"
            >
              By creating an account, you agree to our{" "}
              <button className="text-[#14B8A6] font-medium">
                Terms of Service
              </button>{" "}
              and{" "}
              <button className="text-[#14B8A6] font-medium">
                Privacy Policy
              </button>
            </motion.p>

            {/* Login Link */}
            <div className="relative my-6">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-200" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-4 bg-background text-gray-500">
                  Already have an account?
                </span>
              </div>
            </div>

            <button
              onClick={() => navigate("/login")}
              className="w-full text-center py-3 text-[#0A2463] font-semibold hover:text-[#14B8A6] transition-colors duration-300"
            >
              Sign In
            </button>
          </motion.div>
        </div>
      </div>
    </MobileScreen>
  );
}
