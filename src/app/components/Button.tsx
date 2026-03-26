import { ReactNode, ButtonHTMLAttributes } from "react";
import { Loader2 } from "lucide-react";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode;
  variant?: "primary" | "secondary" | "outline" | "ghost" | "danger";
  size?: "sm" | "md" | "lg";
  loading?: boolean;
  fullWidth?: boolean;
}

export function Button({
  children,
  variant = "primary",
  size = "md",
  loading = false,
  fullWidth = false,
  className = "",
  disabled,
  ...props
}: ButtonProps) {
  const baseStyles = "rounded-2xl font-semibold transition-all duration-300 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed";
  
  const variants = {
    primary: "bg-gradient-to-r from-[#0A2463] to-[#1E3A8A] text-white hover:from-[#051642] hover:to-[#0A2463] shadow-lg shadow-[#0A2463]/30 hover:shadow-xl hover:shadow-[#0A2463]/40",
    secondary: "bg-gradient-to-r from-[#14B8A6] to-[#5EEAD4] text-white hover:from-[#0F766E] hover:to-[#14B8A6] shadow-lg shadow-[#14B8A6]/30 hover:shadow-xl hover:shadow-[#14B8A6]/40",
    outline: "border-2 border-[#0A2463] text-[#0A2463] hover:bg-[#0A2463] hover:text-white backdrop-blur-sm",
    ghost: "text-[#0A2463] hover:bg-gray-100/50 backdrop-blur-sm",
    danger: "bg-gradient-to-r from-[#FF6B35] to-[#FF8A65] text-white hover:from-[#E64A19] hover:to-[#FF6B35] shadow-lg shadow-[#FF6B35]/30 hover:shadow-xl hover:shadow-[#FF6B35]/40",
  };

  const sizes = {
    sm: "px-5 py-2.5 text-sm",
    md: "px-6 py-3.5",
    lg: "px-8 py-4 text-lg",
  };

  return (
    <button
      className={`${baseStyles} ${variants[variant]} ${sizes[size]} ${
        fullWidth ? "w-full" : ""
      } ${className} flex items-center justify-center gap-2`}
      disabled={disabled || loading}
      {...props}
    >
      {loading && <Loader2 className="w-4 h-4 animate-spin" />}
      {children}
    </button>
  );
}