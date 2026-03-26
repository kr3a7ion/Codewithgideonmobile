import { useNavigate, useParams } from "react-router";
import { ArrowLeft, Calendar, Clock, Users, Video, FileText, Download, Play } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";

export function ClassDetailsScreen() {
  const navigate = useNavigate();
  const { id } = useParams();

  const classDetails = {
    title: "React Hooks Deep Dive",
    instructor: "Sarah Chen",
    date: "Today, 3:00 PM - 5:00 PM",
    duration: "2 hours",
    students: 24,
    topic: "React",
    description:
      "Master React Hooks with hands-on examples. We'll cover useState, useEffect, useContext, and custom hooks. Perfect for intermediate developers looking to level up their React skills.",
    learningOutcomes: [
      "Understand useState and useEffect in depth",
      "Create custom hooks for reusable logic",
      "Master useContext for state management",
      "Learn performance optimization with useMemo and useCallback",
    ],
    prerequisites: ["Basic React knowledge", "JavaScript ES6+"],
    resources: [
      { name: "React Hooks Cheatsheet.pdf", size: "2.4 MB" },
      { name: "Example Code Repository", size: "Link" },
      { name: "Slides.pdf", size: "5.1 MB" },
    ],
  };

  return (
    <MobileScreen>
      <div className="min-h-full bg-gray-50">
        {/* Header with Image */}
        <div className="relative h-48 bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] overflow-hidden">
          <div className="absolute inset-0 opacity-20">
            <div className="absolute top-10 right-10 w-32 h-32 bg-teal-400 rounded-full blur-3xl" />
            <div className="absolute bottom-10 left-10 w-32 h-32 bg-orange-400 rounded-full blur-3xl" />
          </div>
          <button
            onClick={() => navigate(-1)}
            className="absolute top-12 left-6 p-2 bg-white/10 backdrop-blur-sm rounded-lg hover:bg-white/20 transition-colors z-10"
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <div className="absolute bottom-4 left-6 right-6">
            <span className="inline-block px-3 py-1 bg-teal-500 text-white rounded-full text-xs font-semibold mb-2">
              {classDetails.topic}
            </span>
            <h1 className="text-2xl font-bold text-white">{classDetails.title}</h1>
          </div>
        </div>

        <div className="px-6 py-4">
          {/* Info Cards */}
          <div className="grid grid-cols-3 gap-3 mb-6">
            {[
              { icon: Calendar, label: "Today", value: "3:00 PM" },
              { icon: Clock, label: "Duration", value: "2 hours" },
              { icon: Users, label: "Students", value: "24" },
            ].map((item, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                className="bg-white rounded-xl p-3 text-center shadow-sm"
              >
                <item.icon className="w-5 h-5 text-[#14B8A6] mx-auto mb-1" />
                <p className="text-xs text-gray-600 mb-0.5">{item.label}</p>
                <p className="text-sm font-bold text-gray-900">{item.value}</p>
              </motion.div>
            ))}
          </div>

          {/* Join Button */}
          <Button
            variant="primary"
            size="lg"
            fullWidth
            onClick={() => navigate("/live/1")}
            className="mb-6"
          >
            <Video className="w-5 h-5" />
            Join Live Class
          </Button>

          {/* Instructor */}
          <div className="bg-white rounded-2xl p-4 mb-4 shadow-sm">
            <p className="text-xs font-semibold text-gray-500 mb-2">INSTRUCTOR</p>
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-[#14B8A6] to-[#5EEAD4] rounded-full flex items-center justify-center">
                <span className="text-lg font-bold text-white">SC</span>
              </div>
              <div>
                <h3 className="font-bold text-gray-900">{classDetails.instructor}</h3>
                <p className="text-sm text-gray-600">Senior React Developer</p>
              </div>
            </div>
          </div>

          {/* Description */}
          <div className="bg-white rounded-2xl p-4 mb-4 shadow-sm">
            <h3 className="font-bold text-gray-900 mb-2">About This Class</h3>
            <p className="text-sm text-gray-600 leading-relaxed">
              {classDetails.description}
            </p>
          </div>

          {/* Learning Outcomes */}
          <div className="bg-white rounded-2xl p-4 mb-4 shadow-sm">
            <h3 className="font-bold text-gray-900 mb-3">What You'll Learn</h3>
            <div className="space-y-2">
              {classDetails.learningOutcomes.map((outcome, index) => (
                <div key={index} className="flex gap-2">
                  <div className="w-5 h-5 bg-teal-100 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
                    <div className="w-2 h-2 bg-teal-600 rounded-full" />
                  </div>
                  <p className="text-sm text-gray-700">{outcome}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Prerequisites */}
          <div className="bg-white rounded-2xl p-4 mb-4 shadow-sm">
            <h3 className="font-bold text-gray-900 mb-3">Prerequisites</h3>
            <div className="space-y-2">
              {classDetails.prerequisites.map((prereq, index) => (
                <div key={index} className="flex items-center gap-2">
                  <div className="w-1.5 h-1.5 bg-[#0A2463] rounded-full" />
                  <p className="text-sm text-gray-700">{prereq}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Resources */}
          <div className="bg-white rounded-2xl p-4 mb-6 shadow-sm">
            <h3 className="font-bold text-gray-900 mb-3">Class Resources</h3>
            <div className="space-y-2">
              {classDetails.resources.map((resource, index) => (
                <button
                  key={index}
                  className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <FileText className="w-5 h-5 text-[#0A2463]" />
                    <div className="text-left">
                      <p className="text-sm font-medium text-gray-900">{resource.name}</p>
                      <p className="text-xs text-gray-500">{resource.size}</p>
                    </div>
                  </div>
                  <Download className="w-5 h-5 text-gray-400" />
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </MobileScreen>
  );
}
