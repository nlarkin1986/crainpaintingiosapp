import { Icon } from "@iconify/react";

export function ColorMatcher() {
  return (
    <div className="flex flex-col min-h-screen bg-black text-white pb-12">
      <div className="relative flex-1 bg-neutral-900 overflow-hidden flex items-center justify-center">
        <img
          src="https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/generation-assets/placeholder/portrait.png"
          className="absolute inset-0 w-full h-full object-cover opacity-60"
        />
        <div className="relative z-10 w-64 h-64 border-2 border-white/40 rounded-3xl flex items-center justify-center">
          <div className="absolute inset-0 border-2 border-primary rounded-3xl animate-pulse" />
          <div className="w-12 h-12 rounded-full border-4 border-white flex items-center justify-center">
            <div className="w-2 h-2 bg-primary rounded-full" />
          </div>
          <div className="absolute -top-1 -left-1 w-6 h-6 border-t-4 border-l-4 border-primary rounded-tl-lg" />
          <div className="absolute -top-1 -right-1 w-6 h-6 border-t-4 border-r-4 border-primary rounded-tr-lg" />
          <div className="absolute -bottom-1 -left-1 w-6 h-6 border-b-4 border-l-4 border-primary rounded-bl-lg" />
          <div className="absolute -bottom-1 -right-1 w-6 h-6 border-b-4 border-r-4 border-primary rounded-br-lg" />
        </div>
        <div className="absolute top-14 left-0 right-0 px-6 flex items-center justify-between z-20">
          <button className="w-10 h-10 rounded-full bg-black/40 backdrop-blur-md flex items-center justify-center border border-white/10">
            <Icon icon="solar:close-circle-linear" className="size-6" />
          </button>
          <div className="px-4 py-1.5 rounded-full bg-black/40 backdrop-blur-md border border-white/10 text-[13px] font-medium tracking-wide">
            Align object in frame
          </div>
          <button className="w-10 h-10 rounded-full bg-black/40 backdrop-blur-md flex items-center justify-center border border-white/10">
            <Icon icon="solar:flashlight-linear" className="size-5" />
          </button>
        </div>
        <div className="absolute bottom-40 left-0 right-0 flex flex-col items-center gap-2 z-20">
          <div className="flex items-center gap-2 px-4 py-2 bg-primary/20 backdrop-blur-xl border border-primary/30 rounded-2xl">
            <div className="w-2 h-2 bg-primary rounded-full animate-ping" />
            <span className="text-sm font-semibold text-primary">Analyzing Color...</span>
          </div>
        </div>
      </div>
      <div className="bg-card text-foreground rounded-t-[32px] p-6 -mt-10 relative z-30 shadow-[0_-10px_40px_rgba(0,0,0,0.3)]">
        <div className="w-12 h-1.5 bg-muted rounded-full mx-auto mb-6" />
        <div className="flex flex-col gap-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="font-heading font-bold text-xl">Matches Found</h2>
              <p className="text-sm text-muted-foreground mt-0.5">3 closest cross-brand matches</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-[#9BA495] border-2 border-white shadow-md" />
          </div>
          <div className="space-y-3">
            <div className="flex items-center gap-4 p-4 rounded-2xl bg-muted/30 border border-border group active:bg-muted/50 transition-colors">
              <div className="w-14 h-14 rounded-xl bg-[#9BA495] shadow-inner shrink-0" />
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <span className="text-[10px] font-bold uppercase tracking-widest text-primary bg-primary/10 px-1.5 py-0.5 rounded">
                    98% Match
                  </span>
                </div>
                <h3 className="font-bold text-[15px] mt-1">Saybrook Sage</h3>
                <p className="text-[12px] text-muted-foreground">Benjamin Moore • HC-114</p>
              </div>
              <Icon icon="solar:add-circle-linear" className="size-6 text-primary" />
            </div>
            <div className="flex items-center gap-4 p-4 rounded-2xl bg-white border border-border group active:bg-muted/30 transition-colors">
              <div className="w-14 h-14 rounded-xl bg-[#8D9B89] shadow-inner shrink-0" />
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <span className="text-[10px] font-bold uppercase tracking-widest text-muted-foreground bg-muted px-1.5 py-0.5 rounded">
                    94% Match
                  </span>
                </div>
                <h3 className="font-bold text-[15px] mt-1">Evergreen Fog</h3>
                <p className="text-[12px] text-muted-foreground">Sherwin-Williams • SW 9130</p>
              </div>
              <Icon icon="solar:add-circle-linear" className="size-6 text-muted-foreground" />
            </div>
            <div className="flex items-center gap-4 p-4 rounded-2xl bg-white border border-border group active:bg-muted/30 transition-colors">
              <div className="w-14 h-14 rounded-xl bg-[#9EA798] shadow-inner shrink-0" />
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <span className="text-[10px] font-bold uppercase tracking-widest text-muted-foreground bg-muted px-1.5 py-0.5 rounded">
                    91% Match
                  </span>
                </div>
                <h3 className="font-bold text-[15px] mt-1">Sage Brush</h3>
                <p className="text-[12px] text-muted-foreground">Behr • PPU10-11</p>
              </div>
              <Icon icon="solar:add-circle-linear" className="size-6 text-muted-foreground" />
            </div>
          </div>
          <button className="w-full h-14 rounded-2xl bg-primary text-primary-foreground font-bold shadow-lg shadow-primary/20 flex items-center justify-center gap-2 mt-2">
            <Icon icon="solar:camera-rotate-linear" className="size-5" />
            Retake Photo
          </button>
        </div>
      </div>
    </div>
  );
}
