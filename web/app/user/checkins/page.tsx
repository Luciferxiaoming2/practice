"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Search, Loader2 } from "lucide-react"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { staggerContainer, staggerItem, fadeInUp } from "@/lib/motion"
import { getCheckins, type CheckIn } from "@/lib/api"
import { useAuth } from "@/lib/auth-context"

export default function UserCheckinsPage() {
  const { userId } = useAuth()
  const [records, setRecords] = useState<CheckIn[]>([])
  const [loading, setLoading] = useState(true)

  const [dateFrom, setDateFrom] = useState("")
  const [dateTo, setDateTo] = useState("")

  async function load() {
    if (!userId) return
    setLoading(true)
    try {
      const params: { user_id: number; date_from?: string; date_to?: string } = { user_id: userId }
      if (dateFrom) params.date_from = dateFrom
      if (dateTo) params.date_to = dateTo
      setRecords(await getCheckins(params))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [userId])

  function fmtTime(ts: string) {
    const d = new Date(ts)
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")} ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}:${String(d.getSeconds()).padStart(2, "0")}`
  }

  const statusMap: Record<string, { label: string; variant: "success" | "destructive" | "warning" }> = {
    ok: { label: "正常", variant: "success" },
    location_fail: { label: "位置异常", variant: "destructive" },
    time_fail: { label: "时间异常", variant: "warning" },
    face_fail: { label: "人脸异常", variant: "destructive" },
  }

  return (
    <div>
      <motion.div className="flex items-center justify-between mb-6" variants={fadeInUp} initial="hidden" animate="visible">
        <div>
          <h1 className="text-2xl font-bold">我的打卡</h1>
          <p className="text-muted-foreground text-sm mt-0.5">查看你的打卡历史记录</p>
        </div>
      </motion.div>

      <motion.div className="flex flex-wrap gap-3 mb-4" variants={fadeInUp} initial="hidden" animate="visible">
        <Input type="date" className="w-40" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
        <Input type="date" className="w-40" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
        <Button variant="outline" leftIcon={<Search size={14} />} onClick={load}>筛选</Button>
      </motion.div>

      {loading ? (
        <div className="flex justify-center py-20 text-muted-foreground">
          <Loader2 className="animate-spin" />
        </div>
      ) : (
        <motion.div variants={staggerContainer} initial="hidden" animate="visible">
          {records.length === 0 ? (
            <motion.div variants={staggerItem}>
              <Card className="flex flex-col items-center justify-center py-20 text-muted-foreground">
                <p className="text-sm">暂无打卡记录</p>
              </Card>
            </motion.div>
          ) : (
            <Card>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-muted-foreground text-xs">
                    <th className="px-5 py-3 text-left font-medium">打卡时间</th>
                    <th className="px-5 py-3 text-left font-medium">状态</th>
                    <th className="px-5 py-3 text-left font-medium">坐标</th>
                  </tr>
                </thead>
                <tbody>
                  {records.map((r) => {
                    const s = statusMap[r.status] ?? { label: r.status, variant: "outline" as const }
                    return (
                      <motion.tr key={r.id} variants={staggerItem} className="border-b border-border last:border-0 hover:bg-muted/40 transition-colors">
                        <td className="px-5 py-3 font-mono text-xs">{fmtTime(r.timestamp)}</td>
                        <td className="px-5 py-3">
                          <Badge variant={s.variant}>{s.label}</Badge>
                        </td>
                        <td className="px-5 py-3 text-xs text-muted-foreground">
                          {r.lat != null && r.lng != null
                            ? `${r.lat.toFixed(4)}, ${r.lng.toFixed(4)}`
                            : "—"}
                        </td>
                      </motion.tr>
                    )
                  })}
                </tbody>
              </table>
            </Card>
          )}
        </motion.div>
      )}
    </div>
  )
}
