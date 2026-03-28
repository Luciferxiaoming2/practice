"use client"
import { useEffect, useRef, useState } from "react"
import { MapPin, Loader2 } from "lucide-react"

interface LocationPickerProps {
  lat: number | string
  lng: number | string
  radius: number | string
  onChange: (lat: number, lng: number) => void
}

export default function LocationPicker({ lat, lng, radius, onChange }: LocationPickerProps) {
  const mapRef = useRef<HTMLDivElement>(null)
  const mapInstance = useRef<any>(null)
  const markerRef = useRef<any>(null)
  const circleRef = useRef<any>(null)
  const amapRef = useRef<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")

  const numLat = typeof lat === "string" ? parseFloat(lat) : lat
  const numLng = typeof lng === "string" ? parseFloat(lng) : lng
  const numRadius = typeof radius === "string" ? parseFloat(radius) : radius

  // Initialize map
  useEffect(() => {
    let destroyed = false

    async function init() {
      ;(window as any)._AMapSecurityConfig = {
        securityJsCode: process.env.NEXT_PUBLIC_AMAP_SECRET || "",
      }

      const AMapLoader = (await import("@amap/amap-jsapi-loader")).default

      const AMap = await AMapLoader.load({
        key: process.env.NEXT_PUBLIC_AMAP_KEY || "",
        version: "2.0",
        plugins: ["AMap.Geocoder"],
      })

      if (destroyed || !mapRef.current) return
      amapRef.current = AMap

      const hasCoords = !isNaN(numLat) && !isNaN(numLng) && numLat !== 0 && numLng !== 0
      const center = hasCoords ? [numLng, numLat] : [116.397428, 39.90923]

      const map = new AMap.Map(mapRef.current, {
        zoom: 15,
        center,
        resizeEnable: true,
      })
      mapInstance.current = map

      if (hasCoords) {
        placeMarker(AMap, map, numLat, numLng)
      }

      map.on("click", (e: any) => {
        const clickLat = e.lnglat.getLat()
        const clickLng = e.lnglat.getLng()
        placeMarker(AMap, map, clickLat, clickLng)
        onChange(clickLat, clickLng)
      })

      setLoading(false)
    }

    init().catch(() => {
      if (!destroyed) {
        setError("地图加载失败，请检查网络")
        setLoading(false)
      }
    })

    return () => {
      destroyed = true
      mapInstance.current?.destroy()
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  // Update marker when lat/lng/radius change externally
  useEffect(() => {
    const AMap = amapRef.current
    const map = mapInstance.current
    if (!AMap || !map) return
    if (!isNaN(numLat) && !isNaN(numLng) && numLat !== 0 && numLng !== 0) {
      placeMarker(AMap, map, numLat, numLng)
      map.setCenter([numLng, numLat])
    }
  }, [numLat, numLng]) // eslint-disable-line react-hooks/exhaustive-deps

  // Update circle radius when radius changes
  useEffect(() => {
    if (circleRef.current && !isNaN(numRadius) && numRadius > 0) {
      circleRef.current.setRadius(numRadius)
    }
  }, [numRadius])

  function placeMarker(AMap: any, map: any, mLat: number, mLng: number) {
    // Remove old marker and circle
    if (markerRef.current) markerRef.current.setMap(null)
    if (circleRef.current) circleRef.current.setMap(null)

    const marker = new AMap.Marker({
      position: [mLng, mLat],
      map,
      draggable: true,
    })
    marker.on("dragend", (e: any) => {
      const pos = marker.getPosition()
      onChange(pos.getLat(), pos.getLng())
    })
    markerRef.current = marker

    const r = !isNaN(numRadius) && numRadius > 0 ? numRadius : 200
    const circle = new AMap.Circle({
      center: [mLng, mLat],
      radius: r,
      strokeColor: "#1677ff",
      strokeWeight: 2,
      strokeOpacity: 0.6,
      fillColor: "#1677ff",
      fillOpacity: 0.12,
      map,
    })
    circleRef.current = circle
  }

  if (error) {
    return (
      <div className="w-full h-[200px] rounded-xl border border-border flex items-center justify-center text-sm text-muted-foreground">
        {error}
      </div>
    )
  }

  return (
    <div className="relative w-full h-[200px] rounded-xl overflow-hidden border border-border">
      <div ref={mapRef} className="w-full h-full" />
      {loading && (
        <div className="absolute inset-0 flex items-center justify-center bg-muted/50 z-10">
          <Loader2 className="animate-spin text-muted-foreground" size={20} />
        </div>
      )}
      <div className="absolute bottom-2 left-2 bg-card/90 backdrop-blur-sm rounded-lg px-2 py-1 text-[10px] text-muted-foreground flex items-center gap-1 z-10">
        <MapPin size={10} />
        点击地图选点，拖拽标记调整
      </div>
    </div>
  )
}
