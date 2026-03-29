"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Search, Loader2, Trash2, Download, X } from "lucide-react"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { staggerContainer, staggerItem, fadeInUp } from "@/lib/motion"
import { getCheckins, getUsers, deleteCheckin, batchDeleteCheckins, type CheckIn, type User } from "@/lib/api"

export default function CheckinsPage() {
  const [records, setRecords] = useState<CheckIn[]>([])
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)

  // filters
  const [selectedUser, setSelectedUser] = useState<number | "">("")
  const [dateFrom, setDateFrom] = useState("")
  const [dateTo, setDateTo] = useState("")

  // selection
  const [selected, setSelected] = useState<Set<number>>(new Set())

  // delete
  const [showDelete, setShowDelete] = useState<{ id: number; name: string } | null>(null)
  const [showBatchDelete, setShowBatchDelete] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [errMsg, setErrMsg] = useState("")

  async function load() {
    setLoading(true)
    setSelected(new Set())
    try {
      const params: Record<string, string | number> = {}
      if (selectedUser !== "") params.user_id = selectedUser
      if (dateFrom) params.date_from = dateFrom
      if (dateTo) params.date_to = dateTo
      const [r, u] = await Promise.all([getCheckins(params), getUsers()])
      setRecords(r)
      setUsers(u)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  function userName(uid: number) {
    return users.find((u) => u.id === uid)?.full_name ?? `#${uid}`
  }

  function fmtTime(ts: string) {
    const d = new Date(ts)
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}:${String(d.getSeconds()).padStart(2, "0")}`
  }

  const statusMap: Record<string, { label: string; variant: "success" | "destructive" | "warning" }> = {
    ok: { label: "正常", variant: "success" },
    location_fail: { label: "位置异常", variant: "destructive" },
    time_early: { label: "早到", variant: "warning" },
    time_late: { label: "迟到", variant: "warning" },
    time_fail: { label: "迟到", variant: "warning" },
    face_fail: { label: "人脸异常", variant: "destructive" },
  }

  function toggleSelect(id: number) {
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  function toggleSelectAll() {
    if (selected.size === records.length) {
      setSelected(new Set())
    } else {
      setSelected(new Set(records.map((r) => r.id)))
    }
  }

  async function handleBatchDelete() {
    setSubmitting(true)
    setErrMsg("")
    try {
      await batchDeleteCheckins([...selected])
      setSelected(new Set())
      setShowBatchDelete(false)
      load()
    } catch {
      setErrMsg("批量删除失败，请重试")
    } finally { setSubmitting(false) }
  }

  async function handleDelete() {
    if (!showDelete) return
    setSubmitting(true)
    setErrMsg("")
    try {
      await deleteCheckin(showDelete.id)
      setShowDelete(null)
      load()
    } catch {
      setErrMsg("删除失败，请重试")
    } finally { setSubmitting(false) }
  }

  function handleExport() {
    const header = "姓名,类型,打卡时间,状态,纬度,经度"
    const rows = records.map((r) => {
      const name = userName(r.user_id)
      const type = r.type === "sign_out" ? "签退" : "签到"
      const time = fmtTime(r.timestamp)
      const status = statusMap[r.status]?.label ?? r.status
      const lat = r.lat != null ? r.lat.toFixed(4) : ""
      const lng = r.lng != null ? r.lng.toFixed(4) : ""
      return `${name},${type},${time},${status},${lat},${lng}`
    })
    const csv = "\uFEFF" + [header, ...rows].join("\n")
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = `打卡记录_${new Date().toISOString().slice(0, 10)}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div>
      <motion.div className="flex items-center justify-between mb-6" variants={fadeInUp} initial="hidden" animate="visible">
        <div>
          <h1 className="text-2xl font-bold">打卡记录</h1>
          <p className="text-muted-foreground text-sm mt-0.5">查看所有用户的打卡历史</p>
        </div>
        <div className="flex gap-2">
          {selected.size > 0 && (
            <Button variant="destructive" leftIcon={<Trash2 size={14} />} onClick={() => setShowBatchDelete(true)}>
              删除选中 ({selected.size})
            </Button>
          )}
          <Button variant="outline" leftIcon={<Download size={14} />} onClick={handleExport} disabled={records.length === 0}>
            导出 CSV
          </Button>
        </div>
      </motion.div>

      {/* Filters */}
      <motion.div className="flex flex-wrap gap-3 mb-4" variants={fadeInUp} initial="hidden" animate="visible">
        <select
          className="h-10 rounded-xl border border-border bg-background px-3 text-sm outline-none focus:ring-2 focus:ring-ring"
          value={selectedUser}
          onChange={(e) => setSelectedUser(e.target.value === "" ? "" : Number(e.target.value))}
        >
          <option value="">全部用户</option>
          {users.map((u) => (
            <option key={u.id} value={u.id}>{u.full_name}</option>
          ))}
        </select>
        <div className="flex items-center gap-1.5">
          <span className="text-xs text-muted-foreground whitespace-nowrap">开始时间</span>
          <input
            type="date"
            className="h-10 rounded-xl border border-border bg-background px-3 text-sm outline-none focus:ring-2 focus:ring-ring w-44"
            value={dateFrom}
            onChange={(e) => setDateFrom(e.target.value)}
            lang="zh-CN"
          />
        </div>
        <div className="flex items-center gap-1.5">
          <span className="text-xs text-muted-foreground whitespace-nowrap">结束时间</span>
          <input
            type="date"
            className="h-10 rounded-xl border border-border bg-background px-3 text-sm outline-none focus:ring-2 focus:ring-ring w-44"
            value={dateTo}
            onChange={(e) => setDateTo(e.target.value)}
            lang="zh-CN"
          />
        </div>
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
                    <th className="px-3 py-3 w-10">
                      <input
                        type="checkbox"
                        checked={records.length > 0 && selected.size === records.length}
                        onChange={toggleSelectAll}
                        className="rounded border-border"
                      />
                    </th>
                    <th className="px-5 py-3 text-left font-medium">姓名</th>
                    <th className="px-5 py-3 text-left font-medium">类型</th>
                    <th className="px-5 py-3 text-left font-medium">打卡时间</th>
                    <th className="px-5 py-3 text-left font-medium">状态</th>
                    <th className="px-5 py-3 text-left font-medium">坐标</th>
                    <th className="px-5 py-3 text-left font-medium">操作</th>
                  </tr>
                </thead>
                <tbody>
                  {records.map((r) => {
                    const s = statusMap[r.status] ?? { label: r.status, variant: "outline" as const }
                    return (
                      <motion.tr key={r.id} variants={staggerItem} className={`border-b border-border last:border-0 hover:bg-muted/40 transition-colors ${selected.has(r.id) ? "bg-primary/5" : ""}`}>
                        <td className="px-3 py-3">
                          <input
                            type="checkbox"
                            checked={selected.has(r.id)}
                            onChange={() => toggleSelect(r.id)}
                            className="rounded border-border"
                          />
                        </td>
                        <td className="px-5 py-3">{userName(r.user_id)}</td>
                        <td className="px-5 py-3">
                          <Badge variant={r.type === "sign_out" ? "warning" : "success"}>
                            {r.type === "sign_out" ? "签退" : "签到"}
                          </Badge>
                        </td>
                        <td className="px-5 py-3 font-mono text-xs">{fmtTime(r.timestamp)}</td>
                        <td className="px-5 py-3">
                          <Badge variant={s.variant}>{s.label}</Badge>
                        </td>
                        <td className="px-5 py-3 text-xs text-muted-foreground">
                          {r.lat != null && r.lng != null
                            ? `${r.lat.toFixed(4)}, ${r.lng.toFixed(4)}`
                            : "—"}
                        </td>
                        <td className="px-5 py-3">
                          <Button size="sm" variant="outline" leftIcon={<Trash2 size={12} />}
                            onClick={() => setShowDelete({ id: r.id, name: userName(r.user_id) })}
                            className="text-destructive hover:text-destructive">
                            删除
                          </Button>
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

      {/* 删除确认弹窗 */}
      {showDelete && (
        <Modal title="确认删除" onClose={() => { setShowDelete(null); setErrMsg("") }}>
          <p className="text-sm text-muted-foreground mb-4">
            确定要删除 <span className="font-semibold text-foreground">{showDelete.name}</span> 的这条打卡记录吗？此操作不可撤销。
          </p>
          {errMsg && <p className="text-destructive text-xs mb-3">{errMsg}</p>}
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => { setShowDelete(null); setErrMsg("") }}>取消</Button>
            <Button variant="destructive" isLoading={submitting} onClick={handleDelete}>确认删除</Button>
          </div>
        </Modal>
      )}
      {/* 批量删除确认弹窗 */}
      {showBatchDelete && (
        <Modal title="批量删除" onClose={() => { setShowBatchDelete(false); setErrMsg("") }}>
          <p className="text-sm text-muted-foreground mb-4">
            确定要删除选中的 <span className="font-semibold text-foreground">{selected.size}</span> 条打卡记录吗？此操作不可撤销。
          </p>
          {errMsg && <p className="text-destructive text-xs mb-3">{errMsg}</p>}
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => { setShowBatchDelete(false); setErrMsg("") }}>取消</Button>
            <Button variant="destructive" isLoading={submitting} onClick={handleBatchDelete}>确认删除 ({selected.size})</Button>
          </div>
        </Modal>
      )}
    </div>
  )
}

/* ── 弹窗组件 ─────────────────────────────────────────── */
function Modal({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-[2px]" onClick={onClose}>
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 16 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 300, damping: 35 }}
        className="bg-card rounded-2xl shadow-xl w-full max-w-sm mx-4 max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
        style={{ boxShadow: "0 20px 60px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.6)" }}
      >
        <div className="flex items-center justify-between px-6 pt-5 pb-4 border-b border-border">
          <h2 className="text-base font-semibold">{title}</h2>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-muted/60 text-muted-foreground hover:text-foreground transition-colors">
            <X size={16} />
          </button>
        </div>
        <div className="px-6 py-5">
          {children}
        </div>
      </motion.div>
    </div>
  )
}
