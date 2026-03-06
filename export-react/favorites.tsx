import { Icon } from "@iconify/react";

export function Favorites() {
  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground pb-24">
      <header className="pt-14 pb-4 px-6 flex flex-col items-start border-b border-border bg-white sticky top-0 z-10">
        <h1 className="text-2xl font-bold font-heading">Favorite Colors</h1>
        <p className="text-[14px] text-muted-foreground mt-1">
          Your curated collection of inspiration
        </p>
      </header>
      <div className="px-4 pt-6">
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
            placeholder="Search your favorites..."
          />
        </div>
        <div className="flex items-center justify-between mt-4 px-1">
          <span className="text-[13px] font-medium text-muted-foreground">8 Colors Saved</span>
          <div className="flex gap-2">
            <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-secondary text-[12px] font-semibold text-foreground">
              Brand
              <Icon icon="solar:alt-arrow-down-linear" className="size-3" />
            </button>
            <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-secondary text-[12px] font-semibold text-foreground">
              Latest
              <Icon icon="solar:sort-from-top-to-bottom-linear" className="size-3" />
            </button>
          </div>
        </div>
      </div>
      <div className="px-4 py-6 grid grid-cols-2 gap-4">
        <div className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-sm relative group active:scale-[0.98] transition-transform">
          <button className="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center text-red-500 z-10 shadow-sm border border-border/50">
            <Icon icon="solar:heart-bold" className="size-5" />
          </button>
          <div className="h-24 w-full bg-[#3F4B5A]" />
          <div className="p-3">
            <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
              Benjamin Moore
            </span>
            <h3 className="font-bold text-[15px] leading-tight text-foreground mt-0.5">
              Hale Navy
            </h3>
            <p className="text-[12px] font-medium text-muted-foreground">HC-154</p>
          </div>
        </div>
        <div className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-sm relative group active:scale-[0.98] transition-transform">
          <button className="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center text-red-500 z-10 shadow-sm border border-border/50">
            <Icon icon="solar:heart-bold" className="size-5" />
          </button>
          <div className="h-24 w-full bg-[#E8DCC4]" />
          <div className="p-3">
            <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
              Benjamin Moore
            </span>
            <h3 className="font-bold text-[15px] leading-tight text-foreground mt-0.5">
              Swiss Coffee
            </h3>
            <p className="text-[12px] font-medium text-muted-foreground">OC-45</p>
          </div>
        </div>
        <div className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-sm relative group active:scale-[0.98] transition-transform">
          <button className="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center text-red-500 z-10 shadow-sm border border-border/50">
            <Icon icon="solar:heart-bold" className="size-5" />
          </button>
          <div className="h-24 w-full bg-[#7B8B91]" />
          <div className="p-3">
            <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
              Sherwin-Williams
            </span>
            <h3 className="font-bold text-[15px] leading-tight text-foreground mt-0.5">Sea Salt</h3>
            <p className="text-[12px] font-medium text-muted-foreground">SW 6204</p>
          </div>
        </div>
        <div className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-sm relative group active:scale-[0.98] transition-transform">
          <button className="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center text-red-500 z-10 shadow-sm border border-border/50">
            <Icon icon="solar:heart-bold" className="size-5" />
          </button>
          <div className="h-24 w-full bg-[#4A5D4E]" />
          <div className="p-3">
            <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
              Benjamin Moore
            </span>
            <h3 className="font-bold text-[15px] leading-tight text-foreground mt-0.5">
              Backwoods
            </h3>
            <p className="text-[12px] font-medium text-muted-foreground">469</p>
          </div>
        </div>
        <div className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-sm relative group active:scale-[0.98] transition-transform">
          <button className="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center text-red-500 z-10 shadow-sm border border-border/50">
            <Icon icon="solar:heart-bold" className="size-5" />
          </button>
          <div className="h-24 w-full bg-[#F4F1EA]" />
          <div className="p-3">
            <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
              Benjamin Moore
            </span>
            <h3 className="font-bold text-[15px] leading-tight text-foreground mt-0.5">
              White Dove
            </h3>
            <p className="text-[12px] font-medium text-muted-foreground">OC-17</p>
          </div>
        </div>
        <div className="flex flex-col bg-card rounded-2xl border border-border overflow-hidden text-left shadow-sm relative group active:scale-[0.98] transition-transform">
          <button className="absolute top-2 right-2 w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center text-red-500 z-10 shadow-sm border border-border/50">
            <Icon icon="solar:heart-bold" className="size-5" />
          </button>
          <div className="h-24 w-full bg-[#7D7061]" />
          <div className="p-3">
            <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
              Sherwin-Williams
            </span>
            <h3 className="font-bold text-[15px] leading-tight text-foreground mt-0.5">
              Urbane Bronze
            </h3>
            <p className="text-[12px] font-medium text-muted-foreground">SW 7048</p>
          </div>
        </div>
      </div>
      <nav className="fixed bottom-0 w-full h-[84px] bg-white border-t border-border flex justify-around items-start pt-3 pb-6 z-30 px-2">
        <button className="flex flex-col items-center gap-1 text-muted-foreground w-16 hover:text-foreground transition-colors">
          <Icon icon="solar:magic-stick-3-linear" className="size-6" />
          <span className="text-[10px] font-medium">Visualize</span>
        </button>
        <button className="flex flex-col items-center gap-1 text-primary w-16">
          <Icon icon="solar:heart-bold" className="size-6" />
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
