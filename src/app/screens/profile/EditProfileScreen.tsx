import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Camera, Check } from "lucide-react";
import { motion } from "motion/react";
import { MobileScreen } from "../../components/MobileScreen";
import { Button } from "../../components/Button";
import { Input } from "../../components/Input";

export function EditProfileScreen() {
  const navigate = useNavigate();
  const [firstName, setFirstName] = useState("Gideon");
  const [lastName, setLastName] = useState("Kamau");
  const [email, setEmail] = useState("gideon.kamau@email.com");
  const [phone, setPhone] = useState("+254 712 345 678");
  const [bio, setBio] = useState("Aspiring full-stack developer passionate about web technologies");
  const [showSuccess, setShowSuccess] = useState(false);

  const handleSave = () => {
    setShowSuccess(true);
    setTimeout(() => {
      navigate(-1);
    }, 1500);
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
            <h1 className="text-2xl font-bold text-white">Edit Profile</h1>
          </div>
        </div>

        <div className="px-6 py-6">
          {/* Profile Photo */}
          <div className="flex justify-center mb-8">
            <div className="relative">
              <div className="w-28 h-28 bg-gradient-to-br from-[#14B8A6] to-[#5EEAD4] rounded-full flex items-center justify-center shadow-xl">
                <span className="text-4xl font-bold text-white">GK</span>
              </div>
              <button className="absolute bottom-0 right-0 p-3 bg-white rounded-full shadow-lg hover:shadow-xl transition-shadow">
                <Camera className="w-5 h-5 text-[#0A2463]" />
              </button>
            </div>
          </div>

          {/* Form */}
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <Input
                label="First Name"
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
              />
              <Input
                label="Last Name"
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
              />
            </div>

            <Input
              label="Email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />

            <Input
              label="Phone Number"
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
            />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Bio
              </label>
              <textarea
                value={bio}
                onChange={(e) => setBio(e.target.value)}
                rows={4}
                className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#14B8A6] focus:border-transparent resize-none"
              />
            </div>

            {/* Save Button */}
            <div className="pt-4">
              <Button
                variant="primary"
                size="lg"
                fullWidth
                onClick={handleSave}
              >
                Save Changes
              </Button>
            </div>
          </div>
        </div>

        {/* Success Toast */}
        {showSuccess && (
          <motion.div
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            className="fixed bottom-6 left-6 right-6 bg-green-600 text-white rounded-2xl p-4 shadow-2xl flex items-center gap-3 z-50"
          >
            <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
              <Check className="w-6 h-6 text-white" />
            </div>
            <div className="flex-1">
              <p className="font-semibold">Profile Updated!</p>
              <p className="text-sm text-green-100">Your changes have been saved</p>
            </div>
          </motion.div>
        )}
      </div>
    </MobileScreen>
  );
}
