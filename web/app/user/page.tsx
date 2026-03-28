"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { CheckCircle, AlertTriangle, Clock, MapPin, ArrowRight } from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { staggerContainer, staggerItem } from "@/lib/motion"
import Link from "next/link"
import { Button } from "@/components/ui/button"
import { getCheckins, getUser, type CheckIn, type User } from "@/lib/api"
import { useAuth } from "@/lib/auth-context"

export default function UserHomePage() {
  const { userId } = useAuth()
  const [user, setUser] = useState<User | null>(null)
  const [records, setRecords] = useState<CheckIn[]>([])

  useEffect(() => {
    if (!userId) return
    getUser(userId).then(setUser).catch(() => {})
    getCheckins({ user_id: userId }).then(setRecords).catch(() => {})
  }, [userId])

  const total = records.length
  const ok = records.filter((r) => r.status === "ok").length
  const abnormal = total - ok

  // 今日是否已打卡（使用本地日期避免时区偏移）
  const now = new Date()
  const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`
  const todayRecord = records.find((r) => {
    const d = new Date(r.timestamp)
    const local = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`
    return local === today
  })

  const stats = [
    { label: "累计打卡", value: String(total), icon: CheckCircle, color: "hsl(var(--primary))" },
    { label: "正常次数", value: String(ok), icon: Clock, color: "hsl(142 60% 45%)" },
    { label: "异常次数", value: String(abnormal), icon: AlertTriangle, color: "hsl(var(--destructive))" },
  ]

  return (
    <div>
      <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} transition={{ type: "spring", stiffness: 300, damping: 30 }}>
        <h1 className="text-2xl font-bold mb-1">首页</h1>
        <p className="text-muted-foreground text-sm mb-6">
          {user ? `你好，${user.full_name}` : "加载中..."}
        </p>
      </motion.div>

      {/* 今日打卡状态 */}
      <motion.div className="mb-6" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ type: "spring", stiffness: 300, damping: 30, delay: 0.05 }}>
        <Card>
          <CardContent className="p-6 flex items-center gap-4">
            <div
              className="w-12 h-12 rounded-2xl flex items-center justify-center flex-shrink-0"
              style={{
                background: todayRecord
                  ? todayRecord.status === "ok"
                    ? "linear-gradient(135deg, hsl(142 60% 45%) 0%, hsl(142 60% 35%) 100%)"
                    : "linear-gradient(135deg, hsl(var(--destructive)) 0%, color-mix(in srgb, hsl(var(--destructive)) 75%, black) 100%)"
                  : "linear-gradient(135deg, hsl(var(--muted)) 0%, hsl(var(--muted)) 100%)",
                boxShadow: todayRecord
                  ? todayRecord.status === "ok"
                    ? "0 4px 12px color-mix(in srgb, hsl(142 60% 45%) 35%, transparent)"
                    : "0 4px 12px color-mix(in srgb, hsl(var(--destructive)) 35%, transparent)"
                  : "none",
              }}
            >
              {todayRecord ? (
                todayRecord.status === "ok" ? <CheckCircle size={20} color="white" /> : <AlertTriangle size={20} color="white" />
              ) : (
                <MapPin size={20} className="text-muted-foreground" />
              )}
            </div>
            <div className="flex-1">
              <p className="text-muted-foreground text-xs">今日打卡</p>
              <p className="text-lg font-semibold mt-0.5">
                {todayRecord
                  ? todayRecord.status === "ok" ? "已打卡 · 正常" : "已打卡 · 异常"
                  : "尚未打卡"}
              </p>
            </div>
            {!todayRecord && (
              <Link href="/user/checkin">
                <Button size="sm" leftIcon={<ArrowRight size={14} />}>去打卡</Button>
              </Link>
            )}
          </CardContent>
        </Card>
      </motion.div>

      {/* 统计数据 */}
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
