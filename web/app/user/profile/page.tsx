"use client"
import { useEffect, useState } from "react"
import { motion } from "framer-motion"
import { Loader2, MapPin, Clock, ScanFace, Pencil, Check } from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { fadeInUp, staggerContainer, staggerItem } from "@/lib/motion"
import { getUser, updateUser, resetPassword, type User } from "@/lib/api"
import { useAuth } from "@/lib/auth-context"

export default function UserProfilePage() {
  const { userId } = useAuth()
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // 编辑姓名
  const [editingName, setEditingName] = useState(false)
  const [nameValue, setNameValue] = useState("")
  const [nameSaving, setNameSaving] = useState(false)
  const [nameSuccess, setNameSuccess] = useState("")

  // 修改密码
  const [showPwd, setShowPwd] = useState(false)
  const [newPwd, setNewPwd] = useState("")
  const [confirmPwd, setConfirmPwd] = useState("")
  const [pwdError, setPwdError] = useState("")
  const [pwdSuccess, setPwdSuccess] = useState("")
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    if (!userId) return
    getUser(userId)
      .then(setUser)
      .finally(() => setLoading(false))
  }, [userId])

  async function handleSaveName() {
    if (!nameValue.trim() || nameValue.trim() === user?.full_name) {
      setEditingName(false)
      return
    }
    setNameSaving(true)
    try {
      const updated = await updateUser(userId!, { full_name: nameValue.trim() })
      setUser(updated)
      setEditingName(false)
      setNameSuccess("姓名修改成功")
      setTimeout(() => setNameSuccess(""), 3000)
    } catch {
      // keep editing state on failure
    } finally {
      setNameSaving(false)
    }
  }

  async function handleChangePwd(e: React.FormEvent) {
    e.preventDefault()
    setPwdError("")
    setPwdSuccess("")

    if (newPwd.length < 8) { setPwdError("新密码至少 8 位"); return }
    if (!/[A-Za-z]/.test(newPwd)) { setPwdError("新密码需包含至少 1 个字母"); return }
    if (!/[0-9]/.test(newPwd)) { setPwdError("新密码需包含至少 1 个数字"); return }
    if (newPwd !== confirmPwd) { setPwdError("两次密码不一致"); return }

    setSubmitting(true)
    try {
      await resetPassword(userId!, newPwd)
      setNewPwd("")
      setConfirmPwd("")
      setShowPwd(false)
      setPwdSuccess("密码修改成功")
    } catch {
      setPwdError("修改失败，请重试")
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center py-20 text-muted-foreground">
        <Loader2 className="animate-spin" />
      </div>
    )
  }

  if (!user) return null

  return (
    <div>
      <motion.div variants={fadeInUp} initial="hidden" animate="visible" className="mb-6">
        <h1 className="text-2xl font-bold">个人信息</h1>
        <p className="text-muted-foreground text-sm mt-0.5">查看账户信息与打卡规则</p>
      </motion.div>

      <motion.div className="grid grid-cols-1 lg:grid-cols-2 gap-6" variants={staggerContainer} initial="hidden" animate="visible">
        {/* 基本信息 */}
        <motion.div variants={staggerItem}>
          <Card>
            <CardContent className="p-6 space-y-4">
              <h2 className="text-base font-semibold mb-4">基本信息</h2>
              <InfoRow label="账号" value={user.username} />
              <InfoRow label="姓名">
                {editingName ? (
                  <div className="flex items-center gap-2">
                    <Input
                      className="h-8 w-40 text-sm"
                      value={nameValue}
                      onChange={(e) => setNameValue(e.target.value)}
                      onKeyDown={(e) => e.key === "Enter" && handleSaveName()}
                      autoFocus
                    />
                    <Button variant="ghost" size="icon" className="h-8 w-8" onClick={handleSaveName} disabled={nameSaving}>
                      {nameSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
                    </Button>
                  </div>
                ) : (
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">{user.full_name}</span>
                    <button
                      className="text-muted-foreground hover:text-foreground transition-colors"
                      onClick={() => { setNameValue(user.full_name); setEditingName(true); setNameSuccess("") }}
                    >
                      <Pencil className="h-3.5 w-3.5" />
                    </button>
                  </div>
                )}
              </InfoRow>
              <InfoRow label="账户状态">
                <Badge variant={user.is_active ? "success" : "warning"}>
                  {user.is_active ? "已激活" : "待激活"}
                </Badge>
              </InfoRow>
              <InfoRow label="角色">
                <Badge variant={user.is_admin ? "default" : "outline"}>
                  {user.role?.name ?? (user.is_admin ? "管理员" : "普通用户")}
                </Badge>
              </InfoRow>
              <InfoRow label="人脸录入">
                <Badge variant={user.face_enrolled ? "success" : "outline"}>
                  {user.face_enrolled ? "已录入" : "未录入"}
                </Badge>
              </InfoRow>

              <div className="pt-2">
                {nameSuccess && <p className="text-green-600 text-xs mb-3">{nameSuccess}</p>}
                {pwdSuccess && <p className="text-green-600 text-xs mb-3">{pwdSuccess}</p>}
                {!showPwd ? (
                  <Button variant="outline" size="sm" onClick={() => { setShowPwd(true); setPwdError(""); setPwdSuccess("") }}>
                    修改密码
                  </Button>
                ) : (
                  <form className="space-y-3 border-t border-border pt-4" onSubmit={handleChangePwd}>
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium">新密码</label>
                      <Input type="password" placeholder="至少 8 位，含字母和数字" value={newPwd}
                        onChange={(e) => setNewPwd(e.target.value)} required />
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium">确认新密码</label>
                      <Input type="password" placeholder="再次输入新密码" value={confirmPwd}
                        onChange={(e) => setConfirmPwd(e.target.value)} required />
                    </div>
                    {pwdError && <p className="text-destructive text-xs">{pwdError}</p>}
                    <div className="flex gap-2">
                      <Button type="button" variant="outline" size="sm" onClick={() => setShowPwd(false)}>取消</Button>
                      <Button type="submit" size="sm" isLoading={submitting}>确认修改</Button>
                    </div>
                  </form>
                )}
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* 打卡规则 */}
        <motion.div variants={staggerItem}>
          <Card>
            <CardContent className="p-6 space-y-4">
              <h2 className="text-base font-semibold mb-4">打卡规则</h2>

              <div className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 bg-muted">
                  <MapPin size={16} className="text-muted-foreground" />
                </div>
                <div>
                  <p className="text-sm font-medium">地点打卡</p>
                  {user.require_location ? (
                    <p className="text-xs text-muted-foreground mt-0.5">
                      要求在指定位置 ({user.location_lat?.toFixed(4)}, {user.location_lng?.toFixed(4)}) 半径 {user.location_radius}米 内打卡
                    </p>
                  ) : (
                    <p className="text-xs text-muted-foreground mt-0.5">未启用</p>
                  )}
                </div>
                <Badge variant={user.require_location ? "success" : "outline"} className="ml-auto flex-shrink-0">
                  {user.require_location ? "已启用" : "未启用"}
                </Badge>
              </div>

              <div className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 bg-muted">
                  <Clock size={16} className="text-muted-foreground" />
                </div>
                <div>
                  <p className="text-sm font-medium">时间段打卡</p>
                  {user.require_time ? (
                    <p className="text-xs text-muted-foreground mt-0.5">
                      要求在 {user.checkin_time_start} ~ {user.checkin_time_end} 之间打卡
                    </p>
                  ) : (
                    <p className="text-xs text-muted-foreground mt-0.5">未启用</p>
                  )}
                </div>
                <Badge variant={user.require_time ? "success" : "outline"} className="ml-auto flex-shrink-0">
                  {user.require_time ? "已启用" : "未启用"}
                </Badge>
              </div>

              <div className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 bg-muted">
                  <ScanFace size={16} className="text-muted-foreground" />
                </div>
                <div>
                  <p className="text-sm font-medium">人脸识别</p>
                  <p className="text-xs text-muted-foreground mt-0.5">
                    {user.require_face ? "打卡时需要进行人脸验证" : "未启用"}
                  </p>
                </div>
                <Badge variant={user.require_face ? "success" : "outline"} className="ml-auto flex-shrink-0">
                  {user.require_face ? "已启用" : "未启用"}
                </Badge>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </motion.div>
    </div>
  )
}

function InfoRow({ label, value, children }: { label: string; value?: string; children?: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-sm text-muted-foreground">{label}</span>
      {children ?? <span className="text-sm font-medium">{value}</span>}
    </div>
  )
}
