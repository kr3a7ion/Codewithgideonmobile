import { useState } from "react";
import { useNavigate } from "react-router";
import { motion, AnimatePresence } from "motion/react";
import { Code2, Video, Trophy, ChevronRight } from "lucide-react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

const slides = [
  {
    id: 1,
    icon: Code2,
    title: "Learn to Code",
    description: "Master programming with live interactive classes from expert instructors",
    color: "#0A2463",
    bgGradient: "from-blue-900 to-blue-700",
  },
  {
    id: 2,
    icon: Video,
    title: "Watch Anytime",
    description: "Access recorded lessons and resources 24/7 at your own pace",
    color: "#14B8A6",
    bgGradient: "from-teal-600 to-teal-400",
  },
  {
    id: 3,
    icon: Trophy,
    title: "Earn Certificates",
    description: "Complete courses and get recognized with industry-standard certificates",
    color: "#FF6B35",
    bgGradient: "from-orange-600 to-orange-400",
  },
];

export function OnboardingScreen() {
  const [currentSlide, setCurrentSlide] = useState(0);
  const navigate = useNavigate();

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      navigate("/welcome");
    }
  };

  const handleSkip = () => {
    navigate("/welcome");
  };

  const slide = slides[currentSlide];
  const Icon = slide.icon;

  return (
    <MobileScreen>
      <div className="h-full flex flex-col">
        {/* Skip Button */}
        <div className="p-6 flex justify-end">
          <button
            onClick={handleSkip}
            className="text-gray-500 hover:text-gray-700 font-medium"
          >
            Skip
          </button>
        </div>

        {/* Slides Content */}
        <div className="flex-1 flex flex-col items-center justify-center px-8">
          <AnimatePresence mode="wait">
            <motion.div
              key={slide.id}
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -50 }}
              transition={{ duration: 0.3 }}
              className="text-center"
            >
              {/* Icon with gradient background */}
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.1, type: "spring", stiffness: 200 }}
                className="mb-12 flex justify-center"
              >
                <div
                  className={`w-32 h-32 bg-gradient-to-br ${slide.bgGradient} rounded-3xl flex items-center justify-center shadow-2xl`}
                >
                  <Icon className="w-16 h-16 text-white" strokeWidth={2} />
                </div>
              </motion.div>

              {/* Title */}
              <motion.h2
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="text-3xl font-bold text-gray-900 mb-4"
              >
                {slide.title}
              </motion.h2>

              {/* Description */}
              <motion.p
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
                className="text-lg text-gray-600 leading-relaxed"
              >
                {slide.description}
              </motion.p>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Progress Dots */}
        <div className="flex justify-center gap-2 mb-8">
          {slides.map((_, index) => (
            <div
              key={index}
              className={`h-2 rounded-full transition-all duration-300 ${
                index === currentSlide
                  ? "w-8 bg-[#0A2463]"
                  : "w-2 bg-gray-300"
              }`}
            />
          ))}
        </div>

        {/* Next Button */}
        <div className="p-6">
          <Button
            variant="primary"
            size="lg"
            fullWidth
            onClick={handleNext}
            className="flex items-center justify-center gap-2"
          >
            {currentSlide === slides.length - 1 ? "Get Started" : "Next"}
            <ChevronRight className="w-5 h-5" />
          </Button>
        </div>
      </div>
    </MobileScreen>
  );
}
