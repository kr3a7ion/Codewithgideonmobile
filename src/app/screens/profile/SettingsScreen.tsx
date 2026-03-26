import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Bell, Moon, Globe, HelpCircle, Shield, LogOut, ChevronRight } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function SettingsScreen() {
  const navigate = useNavigate();
  const [notifications, setNotifications] = useState(true);
  const [darkMode, setDarkMode] = useState(false);
  const [showLogoutModal, setShowLogoutModal] = useState(false);

  const settingsGroups = [
    {
      title: "Preferences",
      items: [
        {
          icon: Bell,
          label: "Notifications",
          type: "toggle",
          value: notifications,
          onChange: setNotifications,
        },
        {
          icon: Moon,
          label: "Dark Mode",
          type: "toggle",
          value: darkMode,
          onChange: setDarkMode,
        },
        {
          icon: Globe,
          label: "Language",
          type: "link",
          value: "English",
        },
      ],
    },
    {
      title: "Support",
      items: [
        {
          icon: HelpCircle,
          label: "Help Center",
          type: "link",
        },
        {
          icon: Shield,
          label: "Privacy Policy",
          type: "link",
        },
      ],
    },
  ];

  const handleLogout = () => {
    setShowLogoutModal(false);
    // In real app, clear auth and redirect
    navigate("/welcome");
  };

  return (
    <MobileScreen>
      <div className="min-h-full bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-6">
          <div className="flex items-center gap-3">
            <button
              onClick={() => navigate(-1)}
              className="p-2 -ml-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </button>
            <h1 className="text-2xl font-bold text-white">Settings</h1>
          </div>
        </div>

        <div className="px-6 py-4">
          {/* Settings Groups */}
          {settingsGroups.map((group, groupIndex) => (
            <div key={groupIndex} className="mb-6">
              <h2 className="text-xs font-bold text-gray-500 uppercase tracking-wide mb-3">
                {group.title}
              </h2>
              <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
                {group.items.map((item, itemIndex) => (
                  <motion.div
                    key={itemIndex}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: groupIndex * 0.1 + itemIndex * 0.05 }}
                    className={`flex items-center gap-3 p-4 ${
                      itemIndex < group.items.length - 1 ? "border-b border-gray-100" : ""
                    }`}
                  >
                    <div className="w-10 h-10 bg-gray-50 rounded-xl flex items-center justify-center">
                      <item.icon className="w-5 h-5 text-gray-600" />
                    </div>
                    <div className="flex-1">
                      <p className="font-semibold text-gray-900">{item.label}</p>
                      {item.type === "link" && item.value && (
                        <p className="text-sm text-gray-500">{item.value}</p>
                      )}
                    </div>
                    {item.type === "toggle" && item.onChange && (
                      <button
                        onClick={() => item.onChange(!item.value)}
                        className={`relative w-14 h-8 rounded-full transition-colors ${
                          item.value ? "bg-[#14B8A6]" : "bg-gray-300"
                        }`}
                      >
                        <motion.div
                          className="absolute top-1 w-6 h-6 bg-white rounded-full shadow-md"
                          animate={{ left: item.value ? 28 : 4 }}
                          transition={{ type: "spring", stiffness: 500, damping: 30 }}
                        />
                      </button>
                    )}
                    {item.type === "link" && (
                      <ChevronRight className="w-5 h-5 text-gray-400" />
                    )}
                  </motion.div>
                ))}
              </div>
            </div>
          ))}

          {/* App Info */}
          <div className="bg-white rounded-2xl shadow-sm p-4 mb-6">
            <div className="text-center">
              <p className="text-sm text-gray-600 mb-1">CodeWithGideon</p>
              <p className="text-xs text-gray-500">Version 1.0.0</p>
            </div>
          </div>

          {/* Logout Button */}
          <Button
            variant="danger"
            size="lg"
            fullWidth
            onClick={() => setShowLogoutModal(true)}
            className="flex items-center justify-center gap-2"
          >
            <LogOut className="w-5 h-5" />
            Logout
          </Button>
        </div>

        {/* Logout Confirmation Modal */}
        <AnimatePresence>
          {showLogoutModal && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="absolute inset-0 bg-black/70 flex items-center justify-center p-6 z-50"
              onClick={() => setShowLogoutModal(false)}
            >
              <motion.div
                initial={{ scale: 0.9, y: 20 }}
                animate={{ scale: 1, y: 0 }}
                exit={{ scale: 0.9, y: 20 }}
                onClick={(e) => e.stopPropagation()}
                className="bg-white rounded-2xl p-6 w-full max-w-sm"
              >
                <div className="text-center mb-6">
                  <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <LogOut className="w-8 h-8 text-red-600" />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">
                    Logout
                  </h3>
                  <p className="text-gray-600">
                    Are you sure you want to logout?
                  </p>
                </div>
                <div className="flex gap-3">
                  <Button
                    variant="outline"
                    fullWidth
                    onClick={() => setShowLogoutModal(false)}
                  >
                    Cancel
                  </Button>
                  <Button
                    variant="danger"
                    fullWidth
                    onClick={handleLogout}
                  >
                    Logout
                  </Button>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </MobileScreen>
  );
}
