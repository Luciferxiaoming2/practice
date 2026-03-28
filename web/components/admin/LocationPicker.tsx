"use client"
import { useEffect, useRef, useState, useCallback } from "react"
import { MapPin, Loader2, Search, X } from "lucide-react"

interface LocationPickerProps {
  lat: number | string
  lng: number | string
  radius: number | string
  onChange: (lat: number, lng: number) => void
}

interface SearchResult {
  name: string
  address: string
  lat: number
  lng: number
}

export default function LocationPicker({ lat, lng, radius, onChange }: LocationPickerProps) {
  const wrapperRef = useRef<HTMLDivElement>(null)
  const mapElRef = useRef<HTMLDivElement | null>(null)
  const mapInstance = useRef<any>(null)
  const markerRef = useRef<any>(null)
  const circleRef = useRef<any>(null)
  const amapRef = useRef<any>(null)
  const placeSearchRef = useRef<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")
  const [keyword, setKeyword] = useState("")
  const [results, setResults] = useState<SearchResult[]>([])
  const [searching, setSearching] = useState(false)
  const [showResults, setShowResults] = useState(false)
  const searchTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const numLat = typeof lat === "string" ? parseFloat(lat) : lat
  const numLng = typeof lng === "string" ? parseFloat(lng) : lng
  const numRadius = typeof radius === "string" ? parseFloat(radius) : radius

  // Initialize map — 命令式创建地图 div，脱离 React DOM 管理
  useEffect(() => {
    let destroyed = false
    if (!wrapperRef.current) return

    const mapEl = document.createElement("div")
    mapEl.style.width = "100%"
    mapEl.style.height = "100%"
    wrapperRef.current.appendChild(mapEl)
    mapElRef.current = mapEl

    async function init() {
      ;(window as any)._AMapSecurityConfig = {
        securityJsCode: process.env.NEXT_PUBLIC_AMAP_SECRET || "",
      }

      const AMapLoader = (await import("@amap/amap-jsapi-loader")).default

      const AMap = await AMapLoader.load({
        key: process.env.NEXT_PUBLIC_AMAP_KEY || "",
        version: "2.0",
        plugins: ["AMap.Geocoder", "AMap.PlaceSearch"],
      })

      if (destroyed) return
      amapRef.current = AMap

      const hasCoords = !isNaN(numLat) && !isNaN(numLng) && numLat !== 0 && numLng !== 0
      const center = hasCoords ? [numLng, numLat] : [116.397428, 39.90923]

      const map = new AMap.Map(mapEl, {
        zoom: 15,
        center,
        resizeEnable: true,
      })
      mapInstance.current = map

      placeSearchRef.current = new AMap.PlaceSearch({
        pageSize: 6,
        pageIndex: 1,
      })

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
      if (mapInstance.current) {
        mapInstance.current.destroy()
        mapInstance.current = null
      }
      mapEl.remove()
      mapElRef.current = null
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

  const doSearch = useCallback((kw: string) => {
    if (!kw.trim() || !placeSearchRef.current) {
      setResults([])
      setShowResults(false)
      return
    }
    setSearching(true)
    placeSearchRef.current.search(kw, (status: string, result: any) => {
      setSearching(false)
      if (status === "complete" && result.poiList?.pois?.length) {
        const items: SearchResult[] = result.poiList.pois.map((poi: any) => ({
          name: poi.name,
          address: poi.address || "",
          lat: poi.location.getLat(),
          lng: poi.location.getLng(),
        }))
        setResults(items)
        setShowResults(true)
      } else {
        setResults([])
        setShowResults(true)
      }
    })
  }, [])

  function handleSearchInput(value: string) {
    setKeyword(value)
    if (searchTimerRef.current) clearTimeout(searchTimerRef.current)
    if (!value.trim()) {
      setResults([])
      setShowResults(false)
      return
    }
    searchTimerRef.current = setTimeout(() => doSearch(value), 400)
  }

  function selectResult(item: SearchResult) {
    setKeyword(item.name)
    setShowResults(false)
    setResults([])
    const AMap = amapRef.current
    const map = mapInstance.current
    if (AMap && map) {
      placeMarker(AMap, map, item.lat, item.lng)
      map.setCenter([item.lng, item.lat])
      map.setZoom(16)
    }
    onChange(item.lat, item.lng)
  }

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
    <div className="space-y-2">
      {/* Search bar */}
      <div className="relative">
        <div className="relative">
          <Search size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="搜索地点..."
            value={keyword}
            onChange={(e) => handleSearchInput(e.target.value)}
            onFocus={() => results.length > 0 && setShowResults(true)}
            className="w-full pl-8 pr-8 py-1.5 text-sm border border-border rounded-lg bg-card focus:outline-none focus:ring-1 focus:ring-primary/30"
          />
          {keyword && (
            <button
              onClick={() => { setKeyword(""); setResults([]); setShowResults(false) }}
              className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
            >
              <X size={14} />
            </button>
          )}
          {searching && (
            <Loader2 size={14} className="absolute right-2.5 top-1/2 -translate-y-1/2 animate-spin text-muted-foreground" />
          )}
        </div>
        {/* Search results dropdown */}
        {showResults && (
          <div className="absolute z-30 w-full mt-1 bg-card border border-border rounded-lg shadow-lg max-h-[180px] overflow-y-auto">
            {results.length === 0 ? (
              <div className="px-3 py-2 text-xs text-muted-foreground">未找到相关地点</div>
            ) : (
              results.map((item, i) => (
                <button
                  key={i}
                  onClick={() => selectResult(item)}
                  className="w-full text-left px-3 py-2 hover:bg-muted/50 border-b border-border last:border-0 transition-colors"
                >
                  <div className="text-sm font-medium truncate">{item.name}</div>
                  {item.address && <div className="text-[11px] text-muted-foreground truncate">{item.address}</div>}
                </button>
              ))
            )}
          </div>
        )}
      </div>

      {/* Map */}
      <div className="relative w-full h-[200px] rounded-xl overflow-hidden border border-border">
        <div ref={wrapperRef} className="w-full h-full" />
        {loading && (
          <div className="absolute inset-0 flex items-center justify-center bg-muted/50 z-10">
            <Loader2 className="animate-spin text-muted-foreground" size={20} />
          </div>
        )}
        <div className="absolute bottom-2 left-2 bg-card/90 backdrop-blur-sm rounded-lg px-2 py-1 text-[10px] text-muted-foreground flex items-center gap-1 z-10">
          <MapPin size={10} />
          搜索或点击地图选点
        </div>
      </div>
    </div>
  )
}
