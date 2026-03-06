import { Icon } from "@iconify/react";

export function ItemPicker() {
  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground pb-40">
      <header className="pt-14 pb-4 px-4 flex flex-col items-center border-b border-border bg-white sticky top-0 z-10">
        <div className="w-44 h-8 bg-muted rounded flex items-center justify-center font-heading font-bold tracking-tight text-primary text-xl">
          Aura Finishes
        </div>
        <p className="text-[14px] text-muted-foreground mt-2">
          Premium quality finishes since 1952
        </p>
      </header>
      <div className="px-6 py-6 bg-white">
        <div className="flex items-center justify-between relative">
          <div className="absolute left-[15%] right-[15%] top-1/2 -translate-y-1/2 h-[2px] bg-border z-0" />
          <div className="relative z-10 flex flex-col items-center gap-2">
            <div className="w-10 h-10 rounded-full border-2 border-primary bg-primary/10 flex items-center justify-center text-primary">
              <Icon icon="solar:palette-bold" className="size-5" />
            </div>
            <span className="text-[12px] font-semibold text-foreground">Color</span>
          </div>
          <div className="relative z-10 flex flex-col items-center gap-2">
            <div className="w-10 h-10 rounded-full bg-muted flex items-center justify-center text-muted-foreground">
              <Icon icon="solar:camera-bold" className="size-5" />
            </div>
            <span className="text-[12px] font-medium text-muted-foreground">Photo</span>
          </div>
          <div className="relative z-10 flex flex-col items-center gap-2">
            <div className="w-10 h-10 rounded-full bg-muted flex items-center justify-center text-muted-foreground">
              <Icon icon="solar:sofa-bold" className="size-5" />
            </div>
            <span className="text-[12px] font-medium text-muted-foreground">Surface</span>
          </div>
        </div>
      </div>
      <div className="px-4 mb-4">
        <div className="flex p-1 bg-muted rounded-xl">
          <button className="flex-1 py-2 text-[14px] font-semibold bg-white rounded-[10px] shadow-sm text-foreground transition-transform active:scale-[0.98]">
            Signature
          </button>
          <button className="flex-1 py-2 text-[14px] font-medium text-muted-foreground transition-transform active:scale-[0.98]">
            Heritage
          </button>
        </div>
      </div>
      <div className="px-4 flex gap-6 border-b border-border">
        <button className="py-3 text-[15px] font-semibold text-primary border-b-2 border-primary">
          Popular
        </button>
        <button className="py-3 text-[15px] font-medium text-muted-foreground">All Colors</button>
        <button className="py-3 text-[15px] font-medium text-primary flex items-center gap-1.5 bg-primary/5 px-3 -mb-[2px] rounded-t-lg">
          <Icon icon="solar:camera-bold" className="size-4" />
          Match
        </button>
      </div>
      <div className="px-4 pt-4">
        <div className="relative group">
          <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none">
            <Icon
              icon="solar:magnifer-linear"
              className="size-5 text-muted-foreground group-focus-within:text-primary transition-colors"
            />
          </div>
          <input
            type="text"
            className="w-full h-12 pl-12 pr-12 rounded-xl bg-input border border-transparent focus:border-primary/20 focus:bg-white focus:ring-4 focus:ring-primary/5 focus:outline-none transition-all text-[15px] font-medium placeholder:text-muted-foreground/60"
            placeholder="Search colors, names, or codes..."
          />
          <button className="absolute inset-y-0 right-4 flex items-center text-muted-foreground/40 hover:text-muted-foreground transition-colors">
            <Icon icon="solar:close-circle-bold" className="size-5" />
          </button>
        </div>
        <div className="flex items-center justify-between mt-4 px-1">
          <span className="text-[13px] font-medium text-muted-foreground">Showing 142 results</span>
          <button className="flex items-center gap-1.5 text-[13px] font-semibold text-primary">
            <Icon icon="solar:filter-linear" className="size-4" />
            Filter
          </button>
        </div>
      </div>
      <div className="px-4 py-6 grid grid-cols-2 gap-3">
        <button className="flex flex-col bg-card rounded-2xl border-2 border-primary overflow-hidden text-left relative shadow-[0_0_0_2px_theme(colors.primary)] transition-transform active:scale-[0.98]">
          <div className="absolute top-2 right-2 w-6 h-6 rounded-full bg-primary flex items-center justify-center text-white z-10 shadow-sm">
            <Icon icon="solar:check-read-linear" className="size-4" />
          </div>
          <div className="h-16 w-full bg-[#E8DCC4]" />
          <div className="p-3">
            <h3 className="font-bold text-[14px] leading-tight text-foreground">Swiss Coffee</h3>
            <p className="text-[12px] font-medium text-muted-foreground mt-1">OC-45</p>
          </div>
        </button>
        <button className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-[0_1px_3px_rgba(0,0,0,0.06)] transition-transform active:scale-[0.98]">
          <div className="h-16 w-full bg-[#3F4B5A]" />
          <div className="p-3">
            <h3 className="font-bold text-[14px] leading-tight text-foreground">Hale Navy</h3>
            <p className="text-[12px] font-medium text-muted-foreground mt-1">HC-154</p>
          </div>
        </button>
        <button className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-[0_1px_3px_rgba(0,0,0,0.06)] transition-transform active:scale-[0.98]">
          <div className="h-16 w-full bg-[#B2B5AC]" />
          <div className="p-3">
            <h3 className="font-bold text-[14px] leading-tight text-foreground">Edgecomb Gray</h3>
            <p className="text-[12px] font-medium text-muted-foreground mt-1">HC-173</p>
          </div>
        </button>
        <button className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-[0_1px_3px_rgba(0,0,0,0.06)] transition-transform active:scale-[0.98]">
          <div className="h-16 w-full bg-[#F4F1EA]" />
          <div className="p-3">
            <h3 className="font-bold text-[14px] leading-tight text-foreground">White Dove</h3>
            <p className="text-[12px] font-medium text-muted-foreground mt-1">OC-17</p>
          </div>
        </button>
        <button className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-[0_1px_3px_rgba(0,0,0,0.06)] transition-transform active:scale-[0.98]">
          <div className="h-16 w-full bg-[#4A5D4E]" />
          <div className="p-3">
            <h3 className="font-bold text-[14px] leading-tight text-foreground">Backwoods</h3>
            <p className="text-[12px] font-medium text-muted-foreground mt-1">469</p>
          </div>
        </button>
        <button className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-[0_1px_3px_rgba(0,0,0,0.06)] transition-transform active:scale-[0.98]">
          <div className="h-16 w-full bg-[#D4C4B7]" />
          <div className="p-3">
            <h3 className="font-bold text-[14px] leading-tight text-foreground">Pashmina</h3>
            <p className="text-[12px] font-medium text-muted-foreground mt-1">AF-100</p>
          </div>
        </button>
      </div>
      <div className="fixed bottom-[84px] left-0 right-0 bg-white/90 backdrop-blur-md border-t border-border p-4 shadow-[0_-4px_16px_rgba(0,0,0,0.08)] z-20 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-[#E8DCC4] border border-border shadow-sm" />
          <span className="text-[14px] font-semibold text-foreground">1 Selected</span>
        </div>
        <button className="h-12 px-6 rounded-xl bg-gradient-to-r from-accent to-primary text-primary-foreground font-semibold text-[16px] shadow-sm flex items-center gap-2 transition-transform active:scale-[0.98]">
          Next Step
          <Icon icon="solar:arrow-right-linear" className="size-5" />
        </button>
      </div>
      <nav className="fixed bottom-0 w-full h-[84px] bg-white border-t border-border flex justify-around items-start pt-3 pb-6 z-30 px-2">
        <button className="flex flex-col items-center gap-1 text-primary w-16">
          <Icon icon="solar:magic-stick-3-bold" className="size-6" />
          <span className="text-[10px] font-medium">Visualize</span>
        </button>
        <button className="flex flex-col items-center gap-1 text-muted-foreground w-16 hover:text-foreground transition-colors">
          <Icon icon="solar:heart-linear" className="size-6" />
          <span className="text-[10px] font-medium">Favorites</span>
        </button>
        <button className="flex flex-col items-center gap-1 text-muted-foreground w-16 hover:text-foreground transition-colors">
          <Icon icon="solar:gallery-linear" className="size-6" />
          <span className="text-[10px] font-medium">Gallery</span>
        </button>
        <button className="flex flex-col items-center gap-1 text-muted-foreground w-16 hover:text-foreground transition-colors">
          <Icon icon="solar:user-linear" className="size-6" />
          <span className="text-[10px] font-medium">Expert</span>
        </button>
      </nav>
    </div>
  );
}
