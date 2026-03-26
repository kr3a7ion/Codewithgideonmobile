import { motion, AnimatePresence } from "motion/react";
import { CheckCircle, XCircle, AlertCircle, Info, X } from "lucide-react";

export type ToastType = "success" | "error" | "warning" | "info";

interface ToastProps {
  show: boolean;
  type: ToastType;
  message: string;
  onClose: () => void;
}

export function Toast({ show, type, message, onClose }: ToastProps) {
  const configs = {
    success: {
      icon: CheckCircle,
      bgColor: "bg-green-600",
      iconColor: "text-white",
    },
    error: {
      icon: XCircle,
      bgColor: "bg-red-600",
      iconColor: "text-white",
    },
    warning: {
      icon: AlertCircle,
      bgColor: "bg-orange-600",
      iconColor: "text-white",
    },
    info: {
      icon: Info,
      bgColor: "bg-blue-600",
      iconColor: "text-white",
    },
  };

  const config = configs[type];
  const Icon = config.icon;

  return (
    <AnimatePresence>
      {show && (
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 50 }}
          className={`fixed bottom-6 left-6 right-6 ${config.bgColor} text-white rounded-2xl p-4 shadow-2xl flex items-center gap-3 z-50`}
        >
          <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center flex-shrink-0">
            <Icon className={`w-6 h-6 ${config.iconColor}`} />
          </div>
          <p className="flex-1 font-medium">{message}</p>
          <button
            onClick={onClose}
            className="p-1 hover:bg-white/10 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
