import { Home, BookOpen, Users, User } from "lucide-react";
import { useNavigate, useLocation } from "react-router";
import { motion } from "motion/react";

export function BottomNav() {
  const navigate = useNavigate();
  const location = useLocation();

  const tabs = [
    { id: "home", label: "Home", icon: Home, path: "/dashboard" },
    { id: "classes", label: "Classes", icon: BookOpen, path: "/classes" },
    { id: "community", label: "Community", icon: Users, path: "/community" },
    { id: "profile", label: "Profile", icon: User, path: "/profile" },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 z-50">
      {/* Blur backdrop */}
      <div className="absolute inset-0 bg-white/70 backdrop-blur-2xl border-t border-gray-200/50 shadow-[0_-8px_32px_rgba(0,0,0,0.08)]" />
      
      {/* Premium gradient overlay */}
      <div className="absolute inset-x-0 bottom-0 h-[1px] bg-gradient-to-r from-transparent via-[#14B8A6]/30 to-transparent" />
      
      <div className="relative max-w-md mx-auto px-6 pb-safe">
        <div className="flex items-center justify-around py-3">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = location.pathname.startsWith(tab.path);

            return (
              <motion.button
                key={tab.id}
                onClick={() => navigate(tab.path)}
                className="relative flex flex-col items-center gap-1.5 px-4 py-2 transition-all duration-300"
                whileTap={{ scale: 0.92 }}
                whileHover={{ scale: 1.05 }}
              >
                {/* Active indicator line at top */}
                {isActive && (
                  <motion.div
                    layoutId="activeTab"
                    className="absolute -top-3 left-1/2 -translate-x-1/2 w-12 h-1 rounded-full"
                    style={{
                      background: "linear-gradient(90deg, #0A2463 0%, #14B8A6 100%)"
                    }}
                    transition={{ type: "spring", stiffness: 300, damping: 30 }}
                  />
                )}
                
                {/* Icon container with enhanced effects */}
                <div className="relative">
                  {/* Glow effect when active */}
                  {isActive && (
                    <motion.div
                      className="absolute inset-0 rounded-2xl"
                      style={{
                        background: "radial-gradient(circle, rgba(20, 184, 166, 0.15) 0%, transparent 70%)",
                        filter: "blur(8px)",
                      }}
                      initial={{ opacity: 0, scale: 0.8 }}
                      animate={{ opacity: 1, scale: 1.4 }}
                      transition={{ duration: 0.3 }}
                    />
                  )}
                  
                  {/* Icon background pill when active */}
                  {isActive && (
                    <motion.div
                      className="absolute inset-0 -inset-x-3 -inset-y-2 bg-gradient-to-br from-[#0A2463]/10 to-[#14B8A6]/10 rounded-2xl"
                      initial={{ opacity: 0, scale: 0.8 }}
                      animate={{ opacity: 1, scale: 1 }}
                      transition={{ type: "spring", stiffness: 300, damping: 25 }}
                    />
                  )}
                  
                  {/* Icon */}
                  <motion.div
                    className="relative z-10"
                    animate={{
                      y: isActive ? -2 : 0,
                    }}
                    transition={{ type: "spring", stiffness: 300, damping: 20 }}
                  >
                    <Icon
                      className={`w-6 h-6 transition-all duration-300 ${
                        isActive 
                          ? "text-[#0A2463] drop-shadow-[0_2px_8px_rgba(20,184,166,0.3)]" 
                          : "text-gray-400"
                      }`}
                      strokeWidth={isActive ? 2.5 : 2}
                    />
                  </motion.div>
                  
                  {/* Sparkle effect when active */}
                  {isActive && (
                    <>
                      <motion.div
                        className="absolute -top-1 -right-1 w-1.5 h-1.5 bg-[#14B8A6] rounded-full"
                        animate={{
                          scale: [0, 1, 0],
                          opacity: [0, 1, 0],
                        }}
                        transition={{
                          duration: 2,
                          repeat: Infinity,
                          repeatDelay: 0.5,
                        }}
                      />
                      <motion.div
                        className="absolute -bottom-1 -left-1 w-1 h-1 bg-[#0A2463] rounded-full"
                        animate={{
                          scale: [0, 1, 0],
                          opacity: [0, 1, 0],
                        }}
                        transition={{
                          duration: 2,
                          repeat: Infinity,
                          repeatDelay: 0.5,
                          delay: 0.3,
                        }}
                      />
                    </>
                  )}
                </div>
                
                {/* Label with gradient when active */}
                <motion.span
                  className={`text-[11px] font-bold transition-all duration-300 ${
                    isActive 
                      ? "bg-gradient-to-r from-[#0A2463] to-[#14B8A6] bg-clip-text text-transparent" 
                      : "text-gray-400"
                  }`}
                  animate={{
                    y: isActive ? 0 : 0,
                  }}
                >
                  {tab.label}
                </motion.span>

                {/* Notification badge (example for Community) */}
                {tab.id === "community" && !isActive && (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    className="absolute top-1 right-2 w-2 h-2 bg-[#FF6B35] rounded-full border border-white shadow-lg"
                  />
                )}
              </motion.button>
            );
          })}
        </div>
      </div>

      {/* Bottom safe area gradient */}
      <div className="absolute inset-x-0 bottom-0 h-safe bg-gradient-to-b from-white/0 to-white/90" />
    </div>
  );
}