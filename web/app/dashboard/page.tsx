"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Users, CheckCircle, AlertTriangle } from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { staggerContainer, staggerItem } from "@/lib/motion"
import { getUsers, type User } from "@/lib/api"

export default function DashboardPage() {
  const [users, setUsers] = useState<User[]>([])

  useEffect(() => {
    getUsers().then(setUsers).catch(() => {})
  }, [])

  const total = users.length
  const active = users.filter((u) => u.is_active).length
  const inactive = users.filter((u) => !u.is_active).length

  const stats = [
    { label: "账户总数", value: String(total), icon: Users, color: "hsl(var(--primary))" },
    { label: "已激活账户", value: String(active), icon: CheckCircle, color: "hsl(142 60% 45%)" },
    { label: "待激活账户", value: String(inactive), icon: AlertTriangle, color: "hsl(var(--destructive))" },
  ]

  return (
    <div>
      <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ type: "spring", stiffness: 300, damping: 30 }}>
        <h1 className="text-2xl font-bold mb-1">控制台</h1>
        <p className="text-muted-foreground text-sm mb-6">欢迎回来，今日一切正常。</p>
      </motion.div>

      <motion.div className="grid grid-cols-1 sm:grid-cols-3 gap-4" variants={staggerContainer} initial="hidden" animate="visible">
        {stats.map(({ label, value, icon: Icon, color }) => (
          <motion.div key={label} variants={staggerItem}>
            <Card className="hover:scale-[1.02] transition-transform duration-200 cursor-default">
              <CardContent className="p-6 flex items-center gap-4">
                <div
                  className="w-12 h-12 rounded-2xl flex items-center justify-center flex-shrink-0"
                  style={{
                    background: `linear-gradient(135deg, ${color} 0%, color-mix(in srgb, ${color} 75%, black) 100%)`,
                    boxShadow: `0 4px 12px color-mix(in srgb, ${color} 35%, transparent)`,
                  }}
                >
                  <Icon size={20} color="white" />
                </div>
                <div>
                  <p className="text-muted-foreground text-xs">{label}</p>
                  <p className="text-3xl font-bold mt-0.5">{value}</p>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </motion.div>
    </div>
  )
}
