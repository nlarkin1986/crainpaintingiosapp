import { Icon } from "@iconify/react";

export function VisualizationDetail() {
  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground pb-12">
      <header className="pt-14 pb-4 px-4 flex items-center justify-between bg-white sticky top-0 z-30">
        <button className="w-10 h-10 flex items-center justify-center rounded-full bg-muted/50 transition-transform active:scale-95">
          <Icon icon="solar:alt-arrow-left-linear" className="size-6" />
        </button>
        <div className="text-center">
          <h1 className="font-heading font-bold text-base leading-tight">Living Room</h1>
          <p className="text-[11px] text-muted-foreground">Generated Oct 24, 2024</p>
        </div>
        <button className="w-10 h-10 flex items-center justify-center rounded-full bg-muted/50 transition-transform active:scale-95">
          <Icon icon="solar:menu-dots-bold" className="size-6" />
        </button>
      </header>
      <main className="flex-1 px-4 pt-2 flex flex-col gap-6">
        <div className="p-1 bg-muted rounded-xl flex">
          <button className="flex-1 py-2 text-sm font-semibold text-muted-foreground rounded-lg transition-all">
            After Only
          </button>
          <button className="flex-1 py-2 text-sm font-bold text-foreground bg-white shadow-sm rounded-lg transition-all">
            Before & After
          </button>
        </div>
        <div className="relative w-full aspect-[3/4] rounded-3xl overflow-hidden shadow-2xl border border-border group">
          <img
            src="https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/Igcq9YRllt9/components/eKBW6jYkGbW.png"
            className="absolute inset-0 w-full h-full object-cover"
            alt="After"
          />
          <div
            className="absolute inset-0 w-full h-full overflow-hidden"
            style="clip-path: inset(0 40% 0 0);"
          >
            <img
              src="https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/Igcq9YRllt9/components/gzXyUcmp7Ov.png"
              className="absolute inset-0 w-full h-full object-cover"
              alt="Before"
            />
          </div>
          <div className="absolute inset-y-0 left-[60%] w-1 bg-white shadow-[0_0_10px_rgba(0,0,0,0.3)] z-10">
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-white shadow-xl flex items-center justify-center border-2 border-primary">
              <Icon icon="solar:alt-arrow-left-linear" className="size-4 text-primary" />
              <Icon icon="solar:alt-arrow-right-linear" className="size-4 text-primary" />
            </div>
          </div>
          <div className="absolute bottom-4 left-4 bg-black/40 backdrop-blur-md px-3 py-1 rounded-full text-[10px] font-bold text-white uppercase tracking-wider">
            Before
          </div>
          <div className="absolute bottom-4 right-4 bg-primary/80 backdrop-blur-md px-3 py-1 rounded-full text-[10px] font-bold text-white uppercase tracking-wider">
            After
          </div>
        </div>
        <div className="bg-card rounded-2xl p-5 border border-border shadow-sm flex flex-col gap-4">
          <div className="flex items-start justify-between">
            <div className="flex gap-4">
              <div className="w-14 h-14 rounded-xl bg-[#1D2B44] border border-border shadow-inner" />
              <div>
                <p className="text-xs text-muted-foreground font-medium uppercase tracking-tight">
                  Selected Color
                </p>
                <h2 className="font-heading font-bold text-lg">Hale Navy</h2>
                <p className="text-sm font-medium text-muted-foreground">Benjamin Moore · HC-154</p>
              </div>
            </div>
            <button className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary">
              <Icon icon="solar:heart-bold" className="size-6" />
            </button>
          </div>
          <div className="h-px bg-border w-full" />
          <div className="flex items-center justify-between text-[13px]">
            <div className="flex items-center gap-2 text-muted-foreground">
              <Icon icon="solar:wall-bold-duotone" className="size-4" />
              <span>Target: Accent Wall</span>
            </div>
            <div className="flex items-center gap-2 text-muted-foreground">
              <Icon icon="solar:sun-bold-duotone" className="size-4" />
              <span>Lighting: Afternoon Sun</span>
            </div>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-3 mb-6">
          <button className="flex flex-col items-center justify-center gap-2 py-4 bg-secondary rounded-2xl border border-border transition-transform active:scale-95">
            <Icon icon="solar:cart-large-4-bold-duotone" className="size-6 text-primary" />
            <span className="text-xs font-bold">Order Swatch</span>
          </button>
          <button className="flex flex-col items-center justify-center gap-2 py-4 bg-secondary rounded-2xl border border-border transition-transform active:scale-95">
            <Icon icon="solar:share-bold-duotone" className="size-6 text-primary" />
            <span className="text-xs font-bold">Share Result</span>
          </button>
        </div>
      </main>
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-white/90 backdrop-blur-lg border-t border-border z-40">
        <button className="w-full h-14 rounded-2xl bg-gradient-to-r from-accent to-primary text-primary-foreground font-bold text-base shadow-lg shadow-primary/20 flex items-center justify-center gap-3 transition-transform active:scale-[0.98]">
          Get Expert Consultation
          <Icon icon="solar:alt-arrow-right-bold" className="size-5" />
        </button>
      </div>
    </div>
  );
}
