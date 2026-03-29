"use client"
import { useEffect, useState, useCallback } from "react"
import { motion } from "framer-motion"
import Link from "next/link"
import {
  Users,
  CalendarCheck,
  CheckCircle2,
  RefreshCw,
  FileDown,
  Search,
  Bell,
} from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { staggerContainer, staggerItem } from "@/lib/motion"
import { getUsers, getCheckins, type User, type CheckIn } from "@/lib/api"
import { useAuth } from "@/lib/auth-context"
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from "recharts"

export default function DashboardPage() {
  const { isAdmin } = useAuth()
  const [users, setUsers] = useState<User[]>([])
  const [checkins, setCheckins] = useState<CheckIn[]>([])
  const [loading, setLoading] = useState(false)
  const [timeRange, setTimeRange] = useState<"24h" | "7d" | "30d">("24h")
  const [now, setNow] = useState<Date | null>(null)
  const [searchQuery, setSearchQuery] = useState("")
  const [searchFocused, setSearchFocused] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const [u, c] = await Promise.all([
        getUsers(),
        getCheckins({ date_from: new Date().toISOString().slice(0, 10), date_to: new Date().toISOString().slice(0, 10) }),
      ])
      setUsers(u)
      setCheckins(c)
    } catch {}
    setLoading(false)
  }, [])

  // 根据时间范围加载打卡数据
  const loadCheckinsByRange = useCallback(async (range: "24h" | "7d" | "30d") => {
    const now = new Date()
    let dateFrom = ""
    
    if (range === "24h") {
      dateFrom = now.toISOString().slice(0, 10)
    } else if (range === "7d") {
      const d = new Date(now)
      d.setDate(d.getDate() - 6)
      dateFrom = d.toISOString().slice(0, 10)
    } else {
      const d = new Date(now)
      d.setDate(d.getDate() - 29)
      dateFrom = d.toISOString().slice(0, 10)
    }
    
    try {
      const c = await getCheckins({ date_from: dateFrom, date_to: now.toISOString().slice(0, 10) })
      setCheckins(c)
    } catch {}
  }, [])

  useEffect(() => {
    load()
    setNow(new Date())
    const timer = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(timer)
  }, [load])

  // 当时间范围改变时重新加载数据
  useEffect(() => {
    loadCheckinsByRange(timeRange)
  }, [timeRange, loadCheckinsByRange])

  const total = users.length
  const totalCheckins = checkins.length
  const okCheckins = checkins.filter((c) => c.status === "ok").length
  const successRate = totalCheckins > 0 ? ((okCheckins / totalCheckins) * 100).toFixed(1) : "100.0"

  // Build chart data based on time range
  const chartData = (() => {
    if (timeRange === "24h") {
      // 按小时分组（8:00-20:00）
      return Array.from({ length: 13 }, (_, i) => {
        const hour = 8 + i
        const label = `${String(hour).padStart(2, "0")}:00`
        const count = checkins.filter((c) => {
          const h = new Date(c.timestamp).getHours()
          return h === hour
        }).length
        return { time: label, count }
      })
    } else if (timeRange === "7d") {
      // 按天分组（最近7天）
      return Array.from({ length: 7 }, (_, i) => {
        const d = new Date()
        d.setDate(d.getDate() - (6 - i))
        const dateStr = d.toISOString().slice(0, 10)
        const label = `${d.getMonth() + 1}/${d.getDate()}`
        const count = checkins.filter((c) => {
          return c.timestamp.slice(0, 10) === dateStr
        }).length
        return { time: label, count }
      })
    } else {
      // 按天分组（最近30天，每5天一个点）
      return Array.from({ length: 6 }, (_, i) => {
        const d = new Date()
        d.setDate(d.getDate() - (25 - i * 5))
        const dateStr = d.toISOString().slice(0, 10)
        const label = `${d.getMonth() + 1}/${d.getDate()}`
        const count = checkins.filter((c) => {
          return c.timestamp.slice(0, 10) === dateStr
        }).length
        return { time: label, count }
      })
    }
  })()

  // Recent checkins
  const userMap = new Map(users.map((u) => [u.id, u.full_name || u.username]))
  const recentCheckins = [...checkins]
    .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
    .slice(0, 6)

  const newUsersToday = users.filter((u) => {
    // Approximate: count inactive users as "new"
    return !u.is_active
  }).length

  const clockStr = now
    ? now.toLocaleTimeString("zh-CN", { hour: "2-digit", minute: "2-digit", second: "2-digit", hour12: false })
    : "--:--:--"

  // Global search
  const q = searchQuery.trim().toLowerCase()
  const matchedUsers = q
    ? users.filter((u) => u.full_name?.toLowerCase().includes(q) || u.username.toLowerCase().includes(q)).slice(0, 5)
    : []
  const matchedCheckins = q
    ? checkins.filter((c) => {
        const name = (c.user_name || userMap.get(c.user_id) || "").toLowerCase()
        return name.includes(q)
      }).slice(0, 5)
    : []
  const hasResults = matchedUsers.length > 0 || matchedCheckins.length > 0
  const showDropdown = searchFocused && q.length > 0

  return (
    <div>
      {/* Top bar */}
      <div className="flex items-center justify-between mb-8">
        <div className="relative flex-1 max-w-md">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground z-10" />
          <input
            type="text"
            placeholder="全局搜索记录..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onFocus={() => setSearchFocused(true)}
            onBlur={() => setTimeout(() => setSearchFocused(false), 200)}
            className="w-full pl-10 pr-4 py-2.5 text-sm border border-border rounded-xl bg-card focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
          {showDropdown && (
            <div className="absolute top-full left-0 right-0 mt-1 bg-card border border-border rounded-xl shadow-lg z-50 max-h-[360px] overflow-y-auto">
              {!hasResults && (
                <p className="px-4 py-3 text-sm text-muted-foreground">未找到匹配结果</p>
              )}
              {matchedUsers.length > 0 && (
                <>
                  <p className="px-4 pt-3 pb-1.5 text-xs font-semibold text-muted-foreground">用户</p>
                  {matchedUsers.map((u) => (
                    <Link
                      key={`u-${u.id}`}
                      href="/dashboard/accounts"
                      className="flex items-center gap-3 px-4 py-2.5 hover:bg-muted/50 transition-colors"
                    >
                      <div className="w-8 h-8 rounded-full bg-purple-50 flex items-center justify-center flex-shrink-0">
                        <Users size={14} className="text-primary" />
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-medium truncate">{u.full_name || u.username}</p>
                        <p className="text-xs text-muted-foreground">@{u.username} · {u.is_active ? "已激活" : "未激活"}</p>
                      </div>
                    </Link>
                  ))}
                </>
              )}
              {matchedCheckins.length > 0 && (
                <>
                  <p className="px-4 pt-3 pb-1.5 text-xs font-semibold text-muted-foreground border-t border-border">打卡记录</p>
                  {matchedCheckins.map((c) => {
                    const name = c.user_name || userMap.get(c.user_id) || `用户${c.user_id}`
                    const time = new Date(c.timestamp).toLocaleTimeString("zh-CN", { hour: "2-digit", minute: "2-digit" })
                    const isOk = c.status === "ok"
                    return (
                      <Link
                        key={`c-${c.id}`}
                        href="/dashboard/checkins"
                        className="flex items-center gap-3 px-4 py-2.5 hover:bg-muted/50 transition-colors"
                      >
                        <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${isOk ? "bg-green-50" : "bg-orange-50"}`}>
                          <CalendarCheck size={14} className={isOk ? "text-green-600" : "text-orange-600"} />
                        </div>
                        <div className="min-w-0">
                          <p className="text-sm font-medium truncate">{name} · {time}</p>
                          <p className={`text-xs ${isOk ? "text-green-600" : "text-orange-600"}`}>
                            {isOk ? "正常签到" : c.status === "location_fail" ? "位置异常" : c.status === "time_early" ? "早到" : c.status === "time_late" || c.status === "time_fail" ? "迟到" : "签到异常"}
                          </p>
                        </div>
                      </Link>
                    )
                  })}
                </>
              )}
            </div>
          )}
        </div>
        <div className="flex items-center gap-4 ml-6">
          <div className="text-right hidden sm:block">
            <p className="text-sm font-mono font-semibold">{clockStr}</p>
            <p className="text-xs text-muted-foreground flex items-center justify-end gap-1.5">
              超级管理员
              <span className="w-1.5 h-1.5 rounded-full bg-green-500 inline-block" />
            </p>
          </div>
          <div className="relative">
            <Bell size={20} className="text-muted-foreground" />
            <span className="absolute -top-1 -right-1 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-background" />
          </div>
          <div className="w-10 h-10 rounded-full bg-muted flex items-center justify-center text-sm font-bold">
            AD
          </div>
        </div>
      </div>

      {/* Title + Actions */}
      <motion.div
        className="flex flex-col sm:flex-row sm:items-center justify-between mb-6 gap-4"
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 30 }}
      >
        <div>
          <h1 className="text-2xl font-bold">工作控制台</h1>
          <p className="text-muted-foreground text-sm mt-0.5">系统运行状态概览</p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" leftIcon={<FileDown size={14} />}>
            导出全局报表
          </Button>
          <Button leftIcon={<RefreshCw size={14} />} onClick={load} isLoading={loading}>
            刷新
          </Button>
        </div>
      </motion.div>

      {/* Three Stat Cards */}
      <motion.div
        className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6"
        variants={staggerContainer}
        initial="hidden"
        animate="visible"
      >
        {/* 账户总数 */}
        <motion.div variants={staggerItem}>
          <Card className="hover:shadow-md transition-shadow">
            <CardContent className="p-6 flex items-center gap-4">
              <div className="w-14 h-14 rounded-2xl flex items-center justify-center flex-shrink-0 bg-purple-50">
                <Users size={24} className="text-primary" />
              </div>
              <div>
                <p className="text-muted-foreground text-xs font-medium">账户总数</p>
                <div className="flex items-baseline gap-2 mt-1">
                  <p className="text-3xl font-bold">{total}</p>
                  {newUsersToday > 0 && (
                    <span className="text-xs font-bold text-green-600">+{newUsersToday}</span>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* 今日打卡总数 */}
        <motion.div variants={staggerItem}>
          <Card className="hover:shadow-md transition-shadow">
            <CardContent className="p-6 flex items-center gap-4">
              <div className="w-14 h-14 rounded-2xl flex items-center justify-center flex-shrink-0 bg-blue-50">
                <CalendarCheck size={24} className="text-blue-600" />
              </div>
              <div>
                <p className="text-muted-foreground text-xs font-medium">今日打卡总数</p>
                <p className="text-3xl font-bold mt-1">{totalCheckins.toLocaleString()}</p>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* 按时打卡率 */}
        <motion.div variants={staggerItem}>
          <Card className="hover:shadow-md transition-shadow">
            <CardContent className="p-6 flex items-center gap-4">
              <div className="w-14 h-14 rounded-2xl flex items-center justify-center flex-shrink-0 bg-green-50">
                <CheckCircle2 size={24} className="text-green-600" />
              </div>
              <div>
                <p className="text-muted-foreground text-xs font-medium">按时打卡率</p>
                <p className="text-3xl font-bold mt-1">{successRate}%</p>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </motion.div>

      {/* Chart + Live Feed */}
      <motion.div
        className="grid grid-cols-1 lg:grid-cols-3 gap-4"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 30, delay: 0.3 }}
      >
        {/* 业务人流量全景 */}
        <Card className="lg:col-span-2">
          <CardContent className="p-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-6 gap-3">
              <div className="flex items-center gap-3">
                <h2 className="text-lg font-bold">业务人流量全景</h2>
                <span className="text-xs font-medium text-green-600 bg-green-50 border border-green-200 px-2 py-0.5 rounded-full">
                  实时更新
                </span>
              </div>
              <div className="flex items-center border border-border rounded-lg overflow-hidden">
                {(["24h", "7d", "30d"] as const).map((range) => (
                  <button
                    key={range}
                    onClick={() => setTimeRange(range)}
                    className={`px-4 py-1.5 text-xs font-medium transition-colors ${
                      timeRange === range
                        ? "bg-primary text-primary-foreground"
                        : "text-muted-foreground hover:text-foreground hover:bg-muted"
                    }`}
                  >
                    {range === "24h" ? "24小时" : range === "7d" ? "7天" : "30天"}
                  </button>
                ))}
              </div>
            </div>
            <div className="h-[280px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData} margin={{ top: 5, right: 10, left: -10, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorCount" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.15} />
                      <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" vertical={false} />
                  <XAxis
                    dataKey="time"
                    tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <YAxis
                    tick={{ fontSize: 11, fill: "hsl(var(--muted-foreground))" }}
                    axisLine={false}
                    tickLine={false}
                    allowDecimals={false}
                  />
                  <Tooltip
                    contentStyle={{
                      background: "hsl(var(--card))",
                      border: "1px solid hsl(var(--border))",
                      borderRadius: "8px",
                      fontSize: "12px",
                    }}
                    labelStyle={{ fontWeight: 600 }}
                  />
                  <Area
                    type="monotone"
                    dataKey="count"
                    stroke="hsl(var(--primary))"
                    strokeWidth={2.5}
                    fill="url(#colorCount)"
                    name="打卡人次"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        {/* 实时动态 */}
        <Card>
          <CardContent className="p-6 flex flex-col h-full">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-lg font-bold">实时动态</h2>
              <span className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                LIVE
              </span>
            </div>
            <div className="flex-1 space-y-4 overflow-y-auto">
              {recentCheckins.length === 0 ? (
                <p className="text-center text-muted-foreground text-sm py-8">今日暂无动态</p>
              ) : (
                recentCheckins.map((c) => {
                  const name = c.user_name || userMap.get(c.user_id) || `用户${c.user_id}`
                  const time = new Date(c.timestamp).toLocaleTimeString("zh-CN", { hour: "2-digit", minute: "2-digit" })
                  const isOk = c.status === "ok"
                  return (
                    <div key={c.id} className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-green-50 flex items-center justify-center flex-shrink-0">
                        <span className="text-sm font-bold text-green-700">
                          {name.charAt(0)}
                        </span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-semibold truncate">{name}</span>
                          <span className="text-xs text-muted-foreground flex-shrink-0">{time}</span>
                        </div>
                        <p className={`text-xs font-medium ${isOk ? "text-green-600" : "text-orange-600"}`}>
                          {isOk ? "成功签到" : c.status === "location_fail" ? "位置异常" : c.status === "time_early" ? "早到" : c.status === "time_late" || c.status === "time_fail" ? "迟到" : "签到异常"}
                        </p>
                      </div>
                    </div>
                  )
                })
              )}
            </div>
            <Link
              href="/dashboard/checkins"
              className="mt-4 block text-center text-sm font-medium text-primary border border-primary/30 rounded-xl py-2.5 hover:bg-primary/5 transition-colors"
            >
              进入详细日志面板
            </Link>
          </CardContent>
        </Card>
      </motion.div>
    </div>
  )
}
