import { Icon } from "@iconify/react";

export function PhotoUpload() {
  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground pb-40">
      <header className="pt-14 pb-4 px-4 flex flex-col items-center border-b border-border bg-white sticky top-0 z-10">
        <div className="w-44 h-8 bg-muted rounded flex items-center justify-center font-heading font-bold tracking-tight text-primary text-xl">
          Aura Finishes
        </div>
        <p className="text-[14px] text-muted-foreground mt-2">Step 2: Upload your space</p>
      </header>
      <div className="px-8 py-8 bg-white">
        <div className="flex items-center justify-between relative">
          <div className="absolute left-0 right-0 top-5 h-[2px] bg-muted z-0" />
          <div
            className="absolute left-0 top-5 h-[2px] bg-primary z-0 transition-all duration-500"
            style="width: 50%"
          />
          <div className="relative z-10 flex flex-col items-center gap-2.5">
            <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center text-white shadow-sm ring-4 ring-white">
              <Icon icon="hugeicons:tick-01" className="size-5" />
            </div>
            <span className="text-[11px] font-bold uppercase tracking-wider text-primary">
              Color
            </span>
          </div>
          <div className="relative z-10 flex flex-col items-center gap-2.5">
            <div className="w-10 h-10 rounded-full bg-white border-2 border-primary flex items-center justify-center text-primary shadow-md ring-4 ring-white ring-offset-0">
              <Icon icon="hugeicons:camera-01" className="size-5" />
            </div>
            <span className="text-[11px] font-bold uppercase tracking-wider text-foreground">
              Photo
            </span>
          </div>
          <div className="relative z-10 flex flex-col items-center gap-2.5">
            <div className="w-10 h-10 rounded-full bg-muted flex items-center justify-center text-muted-foreground ring-4 ring-white">
              <Icon icon="hugeicons:paint-brush-01" className="size-5" />
            </div>
            <span className="text-[11px] font-bold uppercase tracking-wider text-muted-foreground">
              Surface
            </span>
          </div>
        </div>
      </div>
      <div className="flex-1 px-4 flex flex-col gap-6 pt-4">
        <div className="relative group aspect-[3/4] rounded-3xl overflow-hidden border-2 border-dashed border-border bg-muted/30 flex flex-col items-center justify-center gap-4 transition-all hover:bg-muted/50 active:scale-[0.99]">
          <div className="absolute inset-0 opacity-10">
            <img
              src="https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/Igcq9YRllt9/components/BbnhoU8BVAi.png"
              className="w-full h-full object-cover"
            />
          </div>
          <div className="relative z-10 w-20 h-20 rounded-full bg-white shadow-xl flex items-center justify-center text-primary">
            <Icon icon="solar:upload-bold" className="size-10" />
          </div>
          <div className="relative z-10 text-center">
            <h2 className="font-heading font-bold text-xl">Take or Upload Photo</h2>
            <p className="text-muted-foreground mt-2 max-w-[240px] text-sm">
              Clear, well-lit photos work best for the AI visualizer.
            </p>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <button className="flex flex-col items-center justify-center gap-3 p-6 bg-card rounded-2xl border border-border shadow-sm active:scale-95 transition-transform">
            <div className="w-12 h-12 rounded-full bg-secondary flex items-center justify-center text-foreground">
              <Icon icon="solar:camera-linear" className="size-6" />
            </div>
            <span className="font-semibold text-sm">Camera</span>
          </button>
          <button className="flex flex-col items-center justify-center gap-3 p-6 bg-card rounded-2xl border border-border shadow-sm active:scale-95 transition-transform">
            <div className="w-12 h-12 rounded-full bg-secondary flex items-center justify-center text-foreground">
              <Icon icon="solar:gallery-linear" className="size-6" />
            </div>
            <span className="font-semibold text-sm">Library</span>
          </button>
        </div>
        <div className="bg-primary/5 rounded-2xl p-4 flex gap-4 items-start border border-primary/10">
          <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary shrink-0">
            <Icon icon="solar:lightbulb-bold" className="size-5" />
          </div>
          <div>
            <h4 className="font-bold text-sm text-primary">Pro Tip</h4>
            <p className="text-[13px] text-muted-foreground mt-1">
              Remove clutter and ensure natural daylight for the most realistic color simulation.
            </p>
          </div>
        </div>
      </div>
      <div className="fixed bottom-[84px] left-0 right-0 bg-white/90 backdrop-blur-md border-t border-border p-4 shadow-[0_-4px_16px_rgba(0,0,0,0.08)] z-20 flex items-center justify-between">
        <div className="flex items-center gap-3 text-muted-foreground">
          <Icon icon="solar:info-circle-linear" className="size-5" />
          <span className="text-[14px] font-medium">Upload a photo to proceed</span>
        </div>
        <button
          disabled
          className="h-12 px-6 rounded-xl bg-muted text-muted-foreground font-semibold text-[16px] shadow-sm flex items-center gap-2 opacity-50 cursor-not-allowed"
        >
          Next Step
          <Icon icon="solar:arrow-right-linear" className="size-5" />
        </button>
      </div>
      <nav className="fixed bottom-0 w-full h-[84px] bg-white border-t border-border flex justify-around items-start pt-3 pb-6 z-30 px-2">
        <button className="flex flex-col items-center gap-1 text-primary w-16">
          <Icon icon="solar:magic-stick-3-bold" className="size-6" />
          <span className="text-[10px] font-medium">Visualize</span>
        </button>
        <button className="flex flex-col items-center gap-1 text-muted-foreground w-16">
          <Icon icon="solar:gallery-linear" className="size-6" />
          <span className="text-[10px] font-medium">Gallery</span>
        </button>
        <button className="flex flex-col items-center gap-1 text-muted-foreground w-16">
          <Icon icon="solar:user-linear" className="size-6" />
          <span className="text-[10px] font-medium">Expert</span>
        </button>
      </nav>
    </div>
  );
}
