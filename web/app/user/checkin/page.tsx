"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Loader2 } from "lucide-react"
import { fadeInUp } from "@/lib/motion"
import { getUser, getCheckins, createCheckin, type User, type CheckIn } from "@/lib/api"
import { useAuth } from "@/lib/auth-context"
import dynamic from "next/dynamic"

// 动态导入地图组件，禁用 SSR（高德 SDK 需要 window 对象）
const AMapCheckin = dynamic(() => import("@/components/checkin/AMapCheckin"), { ssr: false })

export default function CheckinPage() {
  const { userId } = useAuth()
  const [user, setUser] = useState<User | null>(null)
  const [todayRecord, setTodayRecord] = useState<CheckIn | null>(null)
  const [loading, setLoading] = useState(true)
  const [checkinType, setCheckinType] = useState<"sign_in" | "sign_out">("sign_in")

  useEffect(() => {
    if (!userId) return
    Promise.all([
      getUser(userId),
      getCheckins({ user_id: userId }),
    ]).then(([u, records]) => {
      setUser(u)
      // 检查今日是否已打卡
      const now = new Date()
      const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`
      const found = records.find((r) => {
        const d = new Date(r.timestamp)
        const local = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`
        return local === today
      })
      setTodayRecord(found ?? null)
    }).finally(() => setLoading(false))
  }, [userId])

  async function handleCheckin(lat: number, lng: number) {
    const record = await createCheckin({ lat, lng, type: checkinType })
    setTodayRecord(record)
    const statusMap: Record<string, string> = {
      ok: "打卡成功",
      location_fail: "打卡成功，但位置不在规定范围内",
      time_early: "打卡成功，早到",
      time_late: "打卡成功，迟到",
      time_fail: "打卡成功，迟到",
      face_fail: "打卡成功，但人脸验证未通过",
    }
    return {
      success: record.status === "ok",
      status: record.status,
      message: statusMap[record.status] ?? "打卡已记录",
    }
  }

  if (loading) {
    return <div className="flex justify-center py-20 text-muted-foreground"><Loader2 className="animate-spin" /></div>
  }

  // 构建打卡目标（如果用户配置了位置规则）
  const target = user?.require_location && user.location_lat && user.location_lng && user.location_radius
    ? { lat: user.location_lat, lng: user.location_lng, radius: user.location_radius }
    : null

  return (
    <div>
      <motion.div variants={fadeInUp} initial="hidden" animate="visible" className="mb-6">
        <h1 className="text-2xl font-bold">打卡</h1>
        <p className="text-muted-foreground text-sm mt-0.5">
          {user?.require_location
            ? "请在指定位置范围内完成打卡"
            : "获取定位后即可打卡"}
        </p>
      </motion.div>

      {/* 签到/签退 类型选择 */}
      <motion.div variants={fadeInUp} initial="hidden" animate="visible" className="mb-4">
        <div className="inline-flex rounded-xl bg-muted p-1">
          <button
            className={`px-5 py-2 rounded-lg text-sm font-medium transition-all ${
              checkinType === "sign_in"
                ? "bg-primary text-primary-foreground shadow-sm"
                : "text-muted-foreground hover:text-foreground"
            }`}
            onClick={() => setCheckinType("sign_in")}
          >
            签到
          </button>
          <button
            className={`px-5 py-2 rounded-lg text-sm font-medium transition-all ${
              checkinType === "sign_out"
                ? "bg-primary text-primary-foreground shadow-sm"
                : "text-muted-foreground hover:text-foreground"
            }`}
            onClick={() => setCheckinType("sign_out")}
          >
            签退
          </button>
        </div>
      </motion.div>

      <AMapCheckin
        target={target}
        requireLocation={user?.require_location}
        onCheckin={handleCheckin}
        alreadyCheckedIn={!!todayRecord}
      />
    </div>
  )
}
