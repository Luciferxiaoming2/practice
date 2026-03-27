import { UserSidebar } from "@/components/layout/UserSidebar"

export default function UserLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen bg-background">
      <UserSidebar />
      <main className="flex-1 p-8 overflow-auto">{children}</main>
    </div>
  )
}
