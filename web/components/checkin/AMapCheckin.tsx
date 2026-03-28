"use client"
import { useEffect, useRef, useState, useCallback } from "react"

// 安全密钥必须在 JSAPI 脚本加载前设置，放在模块顶层确保最早执行
if (typeof window !== "undefined") {
  ;(window as any)._AMapSecurityConfig = {
    securityJsCode: process.env.NEXT_PUBLIC_AMAP_SECRET || "",
  }
}

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { MapPin, Navigation, Loader2, CheckCircle, AlertTriangle, RefreshCw } from "lucide-react"
import { motion } from "framer-motion"
import { fadeInUp } from "@/lib/motion"

interface CheckinTarget {
  lat: number
  lng: number
  radius: number
}

interface CheckinResult {
  success: boolean
  status: string
  message: string
}

interface AMapCheckinProps {
  target?: CheckinTarget | null
  requireLocation?: boolean
  onCheckin: (lat: number, lng: number) => Promise<CheckinResult>
  alreadyCheckedIn?: boolean
}

export default function AMapCheckin({ target, requireLocation, onCheckin, alreadyCheckedIn }: AMapCheckinProps) {
  const mapRef = useRef<HTMLDivElement>(null)
  const mapInstance = useRef<any>(null)
  const amapRef = useRef<any>(null)       // 保存 AMap 构造函数
  const markerRef = useRef<any>(null)
  const destroyedRef = useRef(false)

  const [loading, setLoading] = useState(true)
  const [locating, setLocating] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [currentPos, setCurrentPos] = useState<{ lat: number; lng: number } | null>(null)
  const [distance, setDistance] = useState<number | null>(null)
  const [inRange, setInRange] = useState(false)
  const [result, setResult] = useState<CheckinResult | null>(null)
  const [error, setError] = useState("")

  const checkedIn = alreadyCheckedIn || !!result

  const calcDistance = useCallback((lat1: number, lng1: number, lat2: number, lng2: number) => {
    const R = 6371000
    const dLat = ((lat2 - lat1) * Math.PI) / 180
    const dLng = ((lng2 - lng1) * Math.PI) / 180
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  }, [])

  // 定位函数
  const locateUser = useCallback(() => {
    setLocating(true)
    setError("")

    if (!navigator.geolocation) {
      setError("浏览器不支持定位")
      setLocating(false)
      return
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        if (destroyedRef.current) return

        const lat = pos.coords.latitude
        const lng = pos.coords.longitude
        setCurrentPos({ lat, lng })

        const map = mapInstance.current
        const AMap = amapRef.current
        if (map && AMap) {
          if (markerRef.current) markerRef.current.setMap(null)

          const marker = new AMap.Marker({
            position: [lng, lat],
            map,
            label: {
              content: "<span style='font-size:12px;color:#52c41a;font-weight:600'>我的位置</span>",
              direction: "top",
            },
          })
          markerRef.current = marker
          map.setCenter([lng, lat])
          map.setZoom(16)
        }

        if (target && isFinite(target.lat) && isFinite(target.lng)) {
          const d = calcDistance(lat, lng, target.lat, target.lng)
          setDistance(Math.round(d))
          setInRange(d <= (target.radius || 200))
        } else {
          setInRange(true)
        }

        setLocating(false)
      },
      (err) => {
        if (destroyedRef.current) return
        switch (err.code) {
          case err.PERMISSION_DENIED:
            setError("定位权限被拒绝，请在浏览器设置中允许定位")
            break
          case err.POSITION_UNAVAILABLE:
            setError("无法获取位置信息")
            break
          case err.TIMEOUT:
            setError("定位超时，请重试")
            break
          default:
            setError("定位失败，请重试")
        }
        setLocating(false)
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
    )
  }, [target, calcDistance])

  // 初始化地图 — 与 LocationPicker 完全一致的加载方式
  useEffect(() => {
    destroyedRef.current = false
    const mapEl = mapRef.current
    if (!mapEl) return

    async function init() {
      // 如果 AMap 已经加载过，直接复用，避免 loader 重入问题
      let AMap = (window as any).AMap
      if (!AMap) {
        const AMapLoader = (await import("@amap/amap-jsapi-loader")).default
        AMap = await AMapLoader.load({
          key: process.env.NEXT_PUBLIC_AMAP_KEY || "",
          version: "2.0",
          plugins: ["AMap.Geolocation"],
        })
      }

      if (destroyedRef.current) return
      amapRef.current = AMap

      const hasValidTarget = target && isFinite(target.lat) && isFinite(target.lng)
      const center = hasValidTarget ? [target.lng, target.lat] : [116.397428, 39.90923]
      const map = new AMap.Map(mapEl, {
        zoom: 16,
        center,
        resizeEnable: true,
      })
      mapInstance.current = map

      if (hasValidTarget && target) {
        new AMap.Circle({
          center: [target.lng, target.lat],
          radius: target.radius || 200,
          strokeColor: "#1677ff",
          strokeWeight: 2,
          strokeOpacity: 0.6,
          fillColor: "#1677ff",
          fillOpacity: 0.12,
          map,
        })

        new AMap.Marker({
          position: [target.lng, target.lat],
          map,
          label: {
            content: "<span style='font-size:12px;color:#1677ff;font-weight:600'>打卡点</span>",
            direction: "top",
          },
        })
      }

      setLoading(false)
      locateUser()
    }

    init().catch(() => {
      if (!destroyedRef.current) {
        setError("地图加载失败，请检查网络或 API Key 配置")
        setLoading(false)
      }
    })

    return () => {
      destroyedRef.current = true
      if (mapInstance.current) {
        mapInstance.current.destroy()
        mapInstance.current = null
      }
      if (mapEl) {
        mapEl.innerHTML = ""
      }
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  async function handleCheckin() {
    if (!currentPos) {
      setError("请先完成定位")
      return
    }
    setSubmitting(true)
    setError("")
    try {
      const res = await onCheckin(currentPos.lat, currentPos.lng)
      setResult(res)
    } catch {
      setError("打卡失败，请重试")
    } finally {
      setSubmitting(false)
    }
  }

  function handleRelocate() {
    setResult(null)
    locateUser()
  }

  return (
    <div className="space-y-4">
      <motion.div variants={fadeInUp} initial="hidden" animate="visible">
        <Card className="overflow-hidden">
          <div className="w-full h-[350px] relative">
            <div ref={mapRef} className="absolute inset-0" />
            {loading && (
              <div className="absolute inset-0 flex items-center justify-center bg-muted/50 z-10">
                <Loader2 className="animate-spin text-muted-foreground" size={24} />
              </div>
            )}
          </div>
        </Card>
      </motion.div>

      <motion.div variants={fadeInUp} initial="hidden" animate="visible">
        <Card>
          <CardContent className="p-4 space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-sm">
                <Navigation size={14} className="text-primary" />
                <span className="text-muted-foreground">当前位置</span>
              </div>
              {currentPos ? (
                <span className="text-xs font-mono text-muted-foreground">
                  {currentPos.lat.toFixed(6)}, {currentPos.lng.toFixed(6)}
                </span>
              ) : (
                <span className="text-xs text-muted-foreground">
                  {locating ? "定位中..." : "未定位"}
                </span>
              )}
            </div>

            {target && requireLocation && (
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-sm">
                  <MapPin size={14} className="text-primary" />
                  <span className="text-muted-foreground">距打卡点</span>
                </div>
                {distance !== null ? (
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-mono">
                      {distance >= 1000 ? `${(distance / 1000).toFixed(1)} km` : `${distance} m`}
                    </span>
                    <Badge variant={inRange ? "success" : "warning"}>
                      {inRange ? "范围内" : "超出范围"}
                    </Badge>
                  </div>
                ) : (
                  <span className="text-xs text-muted-foreground">--</span>
                )}
              </div>
            )}

            {error && (
              <p className="text-destructive text-xs bg-destructive/10 rounded-lg px-3 py-2">{error}</p>
            )}

            {result && (
              <div className={`flex items-center gap-2 rounded-lg px-3 py-2 text-sm ${result.success ? "bg-green-50 text-green-700" : "bg-red-50 text-red-700"}`}>
                {result.success ? <CheckCircle size={16} /> : <AlertTriangle size={16} />}
                {result.message}
              </div>
            )}

            <div className="flex gap-2 pt-1">
              <Button
                variant="outline"
                className="flex-1"
                leftIcon={<RefreshCw size={14} />}
                onClick={handleRelocate}
                disabled={locating}
                isLoading={locating}
              >
                重新定位
              </Button>
              <Button
                className="flex-1"
                leftIcon={<MapPin size={14} />}
                onClick={handleCheckin}
                disabled={!currentPos || submitting || checkedIn}
                isLoading={submitting}
              >
                {checkedIn ? "今日已打卡" : "立即打卡"}
              </Button>
            </div>
          </CardContent>
        </Card>
      </motion.div>
    </div>
  )
}
