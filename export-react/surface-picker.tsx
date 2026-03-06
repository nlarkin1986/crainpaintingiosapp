import { Icon } from "@iconify/react";

export function SurfacePicker() {
  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground pb-40">
      <header className="pt-14 pb-4 px-4 flex flex-col items-center border-b border-border bg-white sticky top-0 z-10">
        <div className="w-44 h-8 bg-muted rounded flex items-center justify-center font-heading font-bold tracking-tight text-primary text-xl">
          Aura Finishes
        </div>
        <p className="text-[14px] text-muted-foreground mt-2">Step 3: Choose target surface</p>
      </header>
      <div className="px-6 py-6 bg-white">
        <div className="flex items-center justify-between relative">
          <div className="absolute left-[15%] right-[15%] top-1/2 -translate-y-1/2 h-[2px] bg-border z-0" />
          <div className="relative z-10 flex flex-col items-center gap-2">
            <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center text-white">
              <Icon icon="solar:check-read-bold" className="size-5" />
            </div>
            <span className="text-[12px] font-medium text-muted-foreground">Color</span>
          </div>
          <div className="relative z-10 flex flex-col items-center gap-2">
            <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center text-white">
              <Icon icon="solar:check-read-bold" className="size-5" />
            </div>
            <span className="text-[12px] font-medium text-muted-foreground">Photo</span>
          </div>
          <div className="relative z-10 flex flex-col items-center gap-2">
            <div className="w-10 h-10 rounded-full border-2 border-primary bg-primary/10 flex items-center justify-center text-primary">
              <Icon icon="solar:sofa-bold" className="size-5" />
            </div>
            <span className="text-[12px] font-semibold text-foreground">Surface</span>
          </div>
        </div>
      </div>
      <div className="px-4 pt-4 flex flex-col gap-6">
        <div className="px-2">
          <h2 className="font-heading font-bold text-lg">Where do you want to apply the color?</h2>
          <p className="text-sm text-muted-foreground">
            Select the area the AI should visualize first.
          </p>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <button className="flex flex-col items-center justify-center gap-3 p-5 bg-card rounded-2xl border-2 border-primary bg-primary/5 shadow-sm transition-transform active:scale-[0.98]">
            <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center text-primary">
              <Icon icon="solar:wall-bold" className="size-6" />
            </div>
            <span className="font-bold text-sm">Full Walls</span>
          </button>
          <button className="flex flex-col items-center justify-center gap-3 p-5 bg-card rounded-2xl border border-border shadow-sm transition-transform active:scale-[0.98]">
            <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center text-muted-foreground">
              <Icon icon="solar:ruler-bold" className="size-6" />
            </div>
            <span className="font-semibold text-sm">Trim & Base</span>
          </button>
          <button className="flex flex-col items-center justify-center gap-3 p-5 bg-card rounded-2xl border border-border shadow-sm transition-transform active:scale-[0.98]">
            <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center text-muted-foreground">
              <Icon icon="solar:mirror-bold" className="size-6" />
            </div>
            <span className="font-semibold text-sm">Accent Wall</span>
          </button>
          <button className="flex flex-col items-center justify-center gap-3 p-5 bg-card rounded-2xl border border-border shadow-sm transition-transform active:scale-[0.98]">
            <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center text-muted-foreground">
              <Icon icon="solar:door-bold" className="size-6" />
            </div>
            <span className="font-semibold text-sm">Doors</span>
          </button>
          <button className="flex flex-col items-center justify-center gap-3 p-5 bg-card rounded-2xl border border-border shadow-sm transition-transform active:scale-[0.98]">
            <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center text-muted-foreground">
              <Icon icon="solar:box-bold" className="size-6" />
            </div>
            <span className="font-semibold text-sm">Cabinets</span>
          </button>
          <button className="flex flex-col items-center justify-center gap-3 p-5 bg-card rounded-2xl border border-border shadow-sm transition-transform active:scale-[0.98]">
            <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center text-muted-foreground">
              <Icon icon="solar:floor-bold" className="size-6" />
            </div>
            <span className="font-semibold text-sm">Ceiling</span>
          </button>
          <button className="col-span-2 flex items-center gap-4 p-5 bg-card rounded-2xl border border-dashed border-border shadow-sm transition-transform active:scale-[0.98] mt-2 group hover:border-primary/50">
            <div className="w-12 h-12 rounded-full bg-muted group-hover:bg-primary/10 flex items-center justify-center text-muted-foreground group-hover:text-primary transition-colors">
              <Icon icon="solar:pen-new-square-bold" className="size-6" />
            </div>
            <div className="flex-1 text-left">
              <span className="font-semibold text-sm block">Custom / Other</span>
              <span className="text-[12px] text-muted-foreground">
                Specify a custom surface or area
              </span>
            </div>
            <Icon icon="solar:alt-arrow-right-linear" className="size-5 text-muted-foreground" />
          </button>
        </div>
        <div className="flex flex-col gap-2 mt-2 px-2">
          <label className="text-[13px] font-medium text-muted-foreground">
            Custom Surface Details
          </label>
          <div className="relative">
            <input
              type="text"
              className="w-full h-12 pl-4 pr-12 rounded-xl bg-input border border-border focus:ring-2 focus:ring-primary focus:outline-none transition-all text-sm"
              placeholder="e.g., Fireplace mantel, window frames..."
            />
            <div className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground">
              <Icon icon="solar:pen-2-linear" className="size-5" />
            </div>
          </div>
        </div>
      </div>
      <div className="fixed bottom-[84px] left-0 right-0 bg-white/90 backdrop-blur-md border-t border-border p-4 shadow-[0_-4px_16px_rgba(0,0,0,0.08)] z-20">
        <button className="w-full h-14 rounded-2xl bg-gradient-to-r from-accent to-primary text-primary-foreground font-bold text-[18px] shadow-lg flex items-center justify-center gap-3 transition-transform active:scale-[0.98]">
          <Icon icon="solar:magic-stick-3-bold" className="size-6" />
          Visualize Now
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
