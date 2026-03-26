import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Search, FileText, Download, Folder, Filter } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";

export function ResourcesLibraryScreen() {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState("");
  const [activeFilter, setActiveFilter] = useState("all");

  const folders = [
    { name: "Week 1 - Basics", count: 12, color: "from-blue-500 to-blue-600" },
    { name: "Week 2 - Advanced", count: 8, color: "from-purple-500 to-purple-600" },
    { name: "Projects", count: 5, color: "from-orange-500 to-orange-600" },
  ];

  const resources = [
    {
      name: "React Hooks Cheatsheet.pdf",
      type: "PDF",
      size: "2.4 MB",
      date: "Feb 10, 2026",
      folder: "Week 2",
    },
    {
      name: "ES6 Guide.pdf",
      type: "PDF",
      size: "3.1 MB",
      date: "Feb 9, 2026",
      folder: "Week 1",
    },
    {
      name: "API Project Code",
      type: "ZIP",
      size: "5.6 MB",
      date: "Feb 8, 2026",
      folder: "Projects",
    },
    {
      name: "CSS Flexbox Examples.pdf",
      type: "PDF",
      size: "1.8 MB",
      date: "Feb 7, 2026",
      folder: "Week 1",
    },
  ];

  const filters = ["all", "pdf", "code", "video"];

  return (
    <MobileScreen>
      <div className="min-h-full bg-gray-50">
        {/* Header */}
        <div className="bg-gradient-to-br from-[#0A2463] to-[#1E3A8A] px-6 pt-12 pb-6">
          <div className="flex items-center gap-3 mb-6">
            <button
              onClick={() => navigate(-1)}
              className="p-2 -ml-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6 text-white" />
            </button>
            <h1 className="text-2xl font-bold text-white">Resources</h1>
          </div>

          {/* Search */}
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search resources..."
              className="w-full pl-12 pr-4 py-3 bg-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#14B8A6]"
            />
          </div>
        </div>

        <div className="px-6 py-4">
          {/* Filters */}
          <div className="flex gap-2 mb-6 overflow-x-auto pb-2 scrollbar-hide">
            {filters.map((filter) => (
              <button
                key={filter}
                onClick={() => setActiveFilter(filter)}
                className={`px-4 py-2 rounded-lg font-medium text-sm whitespace-nowrap transition-all ${
                  activeFilter === filter
                    ? "bg-[#0A2463] text-white"
                    : "bg-white text-gray-600 hover:bg-gray-100"
                }`}
              >
                {filter.charAt(0).toUpperCase() + filter.slice(1)}
              </button>
            ))}
          </div>

          {/* Folders */}
          <div className="mb-6">
            <h2 className="text-lg font-bold text-gray-900 mb-3">Folders</h2>
            <div className="grid grid-cols-2 gap-3">
              {folders.map((folder, index) => (
                <motion.button
                  key={index}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className="bg-white rounded-2xl p-4 shadow-sm hover:shadow-md transition-shadow text-left"
                >
                  <div className={`w-12 h-12 bg-gradient-to-br ${folder.color} rounded-xl flex items-center justify-center mb-3`}>
                    <Folder className="w-6 h-6 text-white" />
                  </div>
                  <h3 className="font-semibold text-gray-900 mb-1 text-sm">
                    {folder.name}
                  </h3>
                  <p className="text-xs text-gray-600">{folder.count} files</p>
                </motion.button>
              ))}
            </div>
          </div>

          {/* All Resources */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-lg font-bold text-gray-900">All Resources</h2>
              <button className="text-sm text-[#14B8A6] font-medium">
                Sort by
              </button>
            </div>
            <div className="space-y-2">
              {resources.map((resource, index) => (
                <motion.button
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.2 + index * 0.05 }}
                  className="w-full bg-white rounded-2xl p-4 shadow-sm hover:shadow-md transition-shadow flex items-center gap-3"
                >
                  <div className="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center flex-shrink-0">
                    <FileText className="w-6 h-6 text-blue-600" />
                  </div>
                  <div className="flex-1 min-w-0 text-left">
                    <h4 className="font-semibold text-gray-900 mb-1 text-sm">
                      {resource.name}
                    </h4>
                    <div className="flex items-center gap-2 text-xs text-gray-600">
                      <span className="px-2 py-0.5 bg-gray-100 rounded-full font-medium">
                        {resource.type}
                      </span>
                      <span>{resource.size}</span>
                      <span>•</span>
                      <span>{resource.date}</span>
                    </div>
                  </div>
                  <Download className="w-5 h-5 text-gray-400 flex-shrink-0" />
                </motion.button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </MobileScreen>
  );
}
