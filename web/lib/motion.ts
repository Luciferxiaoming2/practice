// Apple-level Spring motion variants
import type { Variants } from "framer-motion"

export const snappy = { type: "spring" as const, stiffness: 400, damping: 30 }
export const gentle = { type: "spring" as const, stiffness: 300, damping: 35 }
export const bouncy = { type: "spring" as const, stiffness: 500, damping: 25, mass: 0.8 }
export const smooth = { type: "spring" as const, stiffness: 200, damping: 40, mass: 1.2 }

export const fadeInUp: Variants = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 300, damping: 30 } },
}

export const scaleIn: Variants = {
  hidden: { opacity: 0, scale: 0.9 },
  visible: { opacity: 1, scale: 1, transition: { type: "spring", stiffness: 400, damping: 25 } },
}

export const staggerContainer: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
}

export const staggerItem: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { type: "spring", stiffness: 350, damping: 30 } },
}

export const hoverLift: Variants = {
  rest: { scale: 1, y: 0, boxShadow: "0 4px 12px rgba(0,0,0,0.1)" },
  hover: {
    scale: 1.02, y: -4, boxShadow: "0 12px 32px rgba(0,0,0,0.15)",
    transition: { type: "spring", stiffness: 400, damping: 25 },
  },
}

export const modalContent: Variants = {
  hidden: { opacity: 0, scale: 0.95, y: 20 },
  visible: { opacity: 1, scale: 1, y: 0, transition: { type: "spring", stiffness: 300, damping: 35 } },
  exit: { opacity: 0, scale: 0.95, transition: { duration: 0.15 } },
}

export const pageTransition: Variants = {
  initial: { opacity: 0, x: 20 },
  animate: { opacity: 1, x: 0, transition: { type: "spring", stiffness: 260, damping: 40 } },
  exit: { opacity: 0, x: -20, transition: { duration: 0.2 } },
}
