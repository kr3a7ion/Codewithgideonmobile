import { ReactNode } from "react";

interface MobileScreenProps {
  children: ReactNode;
  showBottomNav?: boolean;
  className?: string;
}

export function MobileScreen({ children, showBottomNav = false, className = "" }: MobileScreenProps) {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-white rounded-3xl shadow-2xl overflow-hidden relative" style={{ height: "844px" }}>
        <div className={`h-full overflow-y-auto ${showBottomNav ? "pb-20" : ""} ${className}`}>
          {children}
        </div>
      </div>
    </div>
  );
}
