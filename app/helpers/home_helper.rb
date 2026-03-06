module HomeHelper
  # Tailwind JIT는 동적 보간 클래스를 감지하지 못하므로
  # 색상별 완전한 클래스 문자열을 미리 정의해 룩업 방식으로 사용
  TOPIC_COLOR_CLASSES = {
    "indigo"  => {
      icon_lg:   "bg-indigo-100 text-indigo-600 group-hover:bg-indigo-600 group-hover:text-white",
      icon_sm:   "bg-indigo-50 text-indigo-600 group-hover:bg-indigo-600 group-hover:text-white",
      icon_base: "bg-indigo-50 text-indigo-600",
      title:     "group-hover:text-indigo-600",
      badge:     "text-indigo-600 bg-indigo-50 border-indigo-100",
      hero:      "text-indigo-400 group-hover:text-indigo-300",
    },
    "violet"  => {
      icon_lg:   "bg-violet-100 text-violet-600 group-hover:bg-violet-600 group-hover:text-white",
      icon_sm:   "bg-violet-50 text-violet-600 group-hover:bg-violet-600 group-hover:text-white",
      icon_base: "bg-violet-50 text-violet-600",
      title:     "group-hover:text-violet-600",
      badge:     "text-violet-600 bg-violet-50 border-violet-100",
      hero:      "text-violet-400 group-hover:text-violet-300",
    },
    "amber"   => {
      icon_lg:   "bg-amber-100 text-amber-600 group-hover:bg-amber-600 group-hover:text-white",
      icon_sm:   "bg-amber-50 text-amber-600 group-hover:bg-amber-600 group-hover:text-white",
      icon_base: "bg-amber-50 text-amber-600",
      title:     "group-hover:text-amber-600",
      badge:     "text-amber-600 bg-amber-50 border-amber-100",
      hero:      "text-amber-400 group-hover:text-amber-300",
    },
    "emerald" => {
      icon_lg:   "bg-emerald-100 text-emerald-600 group-hover:bg-emerald-600 group-hover:text-white",
      icon_sm:   "bg-emerald-50 text-emerald-600 group-hover:bg-emerald-600 group-hover:text-white",
      icon_base: "bg-emerald-50 text-emerald-600",
      title:     "group-hover:text-emerald-600",
      badge:     "text-emerald-600 bg-emerald-50 border-emerald-100",
      hero:      "text-emerald-400 group-hover:text-emerald-300",
    },
    "blue"    => {
      icon_lg:   "bg-blue-100 text-blue-600 group-hover:bg-blue-600 group-hover:text-white",
      icon_sm:   "bg-blue-50 text-blue-600 group-hover:bg-blue-600 group-hover:text-white",
      icon_base: "bg-blue-50 text-blue-600",
      title:     "group-hover:text-blue-600",
      badge:     "text-blue-600 bg-blue-50 border-blue-100",
      hero:      "text-blue-400 group-hover:text-blue-300",
    },
    "rose"    => {
      icon_lg:   "bg-rose-100 text-rose-600 group-hover:bg-rose-600 group-hover:text-white",
      icon_sm:   "bg-rose-50 text-rose-600 group-hover:bg-rose-600 group-hover:text-white",
      icon_base: "bg-rose-50 text-rose-600",
      title:     "group-hover:text-rose-600",
      badge:     "text-rose-600 bg-rose-50 border-rose-100",
      hero:      "text-rose-400 group-hover:text-rose-300",
    },
    "slate"   => {
      icon_lg:   "bg-slate-100 text-slate-600 group-hover:bg-slate-600 group-hover:text-white",
      icon_sm:   "bg-slate-50 text-slate-600 group-hover:bg-slate-600 group-hover:text-white",
      icon_base: "bg-slate-50 text-slate-600",
      title:     "group-hover:text-slate-600",
      badge:     "text-slate-600 bg-slate-50 border-slate-100",
      hero:      "text-slate-400 group-hover:text-slate-300",
    },
    "pink"    => {
      icon_lg:   "bg-pink-100 text-pink-600 group-hover:bg-pink-600 group-hover:text-white",
      icon_sm:   "bg-pink-50 text-pink-600 group-hover:bg-pink-600 group-hover:text-white",
      icon_base: "bg-pink-50 text-pink-600",
      title:     "group-hover:text-pink-600",
      badge:     "text-pink-600 bg-pink-50 border-pink-100",
      hero:      "text-pink-400 group-hover:text-pink-300",
    },
  }.freeze

  # 뷰에서 tc(color, :icon_sm) 형태로 호출
  def tc(color, key)
    (TOPIC_COLOR_CLASSES[color.to_s] || TOPIC_COLOR_CLASSES["indigo"])[key]
  end
end
