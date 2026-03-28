"use client"
import { useState } from "react"
import { UserSidebar } from "@/components/layout/UserSidebar"
import { Menu } from "lucide-react"

export default function UserLayout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(false)

  return (
    <div className="flex min-h-screen bg-background">
      {/* Mobile hamburger button */}
      <button
        className="md:hidden fixed top-4 left-4 z-30 p-2 rounded-xl bg-card border border-border shadow-sm"
        onClick={() => setSidebarOpen(true)}
      >
        <Menu size={20} />
      </button>

      <UserSidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <main className="flex-1 p-4 pt-16 md:p-8 md:pt-8 overflow-auto">{children}</main>
    </div>
  )
}
