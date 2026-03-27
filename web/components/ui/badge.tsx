import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const badgeVariants = cva(
  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-all duration-200",
  {
    variants: {
      variant: {
        default: "text-primary-foreground",
        secondary: "bg-secondary text-secondary-foreground",
        destructive: "text-destructive-foreground",
        outline: "border border-input text-foreground",
        success: "bg-green-100 text-green-800",
        warning: "bg-yellow-100 text-yellow-800",
      },
    },
    defaultVariants: { variant: "default" },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant = "default", style, ...props }: BadgeProps) {
  const isGradient = variant === "default" || variant === "destructive"
  const gradientStyle = isGradient
    ? {
        background:
          variant === "destructive"
            ? "linear-gradient(135deg, hsl(var(--destructive)) 0%, color-mix(in srgb, hsl(var(--destructive)) 80%, black) 100%)"
            : "linear-gradient(135deg, hsl(var(--primary)) 0%, color-mix(in srgb, hsl(var(--primary)) 80%, black) 100%)",
        boxShadow: "0 2px 6px color-mix(in srgb, hsl(var(--primary)) 30%, transparent)",
      }
    : {}

  return (
    <div
      className={cn(badgeVariants({ variant }), className)}
      style={{ ...gradientStyle, ...style }}
      {...props}
    />
  )
}

export { Badge, badgeVariants }
