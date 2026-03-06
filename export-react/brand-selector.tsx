import { Icon } from "@iconify/react";

export function BrandSelector() {
  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground pb-24">
      <header className="pt-14 pb-4 px-4 flex flex-col items-center border-b border-border bg-white sticky top-0 z-20">
        <div className="w-44 h-8 bg-muted rounded flex items-center justify-center font-heading font-bold tracking-tight text-primary text-xl">
          Aura Finishes
        </div>
        <p className="text-[14px] text-muted-foreground mt-2">Trusted quality since 1952</p>
      </header>
      <div className="px-6 py-8 flex flex-col gap-8">
        <div className="space-y-2">
          <h1 className="font-heading font-bold text-2xl">Select a Paint Brand</h1>
          <p className="text-muted-foreground">
            Choose your preferred manufacturer to browse their catalog.
          </p>
        </div>
        <div className="grid grid-cols-1 gap-4">
          <button className="group relative flex items-center gap-4 p-5 bg-card rounded-2xl border-2 border-primary bg-primary/5 shadow-sm transition-all active:scale-[0.98]">
            <div className="absolute top-4 right-4 w-6 h-6 rounded-full bg-primary flex items-center justify-center text-white shadow-sm">
              <Icon icon="solar:check-read-bold" className="size-4" />
            </div>
            <div className="w-14 h-14 rounded-xl bg-white border border-border flex items-center justify-center shadow-sm shrink-0">
              <span className="font-heading font-black text-red-600 text-lg leading-none text-center">
                BM
              </span>
            </div>
            <div className="flex flex-col text-left">
              <span className="font-bold text-lg">Benjamin Moore</span>
              <span className="text-sm text-muted-foreground">Premium quality since 1883</span>
            </div>
          </button>
          <button className="group flex items-center gap-4 p-5 bg-card rounded-2xl border border-border shadow-sm transition-all active:scale-[0.98] hover:border-primary/50">
            <div className="w-14 h-14 rounded-xl bg-white border border-border flex items-center justify-center shadow-sm shrink-0">
              <Icon icon="solar:globus-bold" className="size-8 text-blue-600" />
            </div>
            <div className="flex flex-col text-left">
              <span className="font-bold text-lg">Sherwin-Williams</span>
              <span className="text-sm text-muted-foreground">Cover the Earth since 1866</span>
            </div>
          </button>
          <button className="group flex items-center gap-4 p-5 bg-card rounded-2xl border border-border shadow-sm transition-all active:scale-[0.98] hover:border-primary/50">
            <div className="w-14 h-14 rounded-xl bg-white border border-border flex items-center justify-center shadow-sm shrink-0">
              <span className="font-heading font-black text-orange-600 text-lg">BEHR</span>
            </div>
            <div className="flex flex-col text-left">
              <span className="font-bold text-lg">Behr</span>
              <span className="text-sm text-muted-foreground">Quality you can trust</span>
            </div>
          </button>
          <button className="group flex items-center gap-4 p-5 bg-card rounded-2xl border border-dashed border-border shadow-sm transition-all active:scale-[0.98] hover:border-primary/50 mt-2">
            <div className="w-14 h-14 rounded-xl bg-muted flex items-center justify-center shrink-0">
              <Icon
                icon="solar:palette-round-bold"
                className="size-8 text-muted-foreground group-hover:text-primary transition-colors"
              />
            </div>
            <div className="flex flex-col text-left flex-1">
              <span className="font-bold text-lg">Other Brand</span>
              <span className="text-sm text-muted-foreground">Specify a custom manufacturer</span>
            </div>
            <Icon icon="solar:alt-arrow-right-linear" className="size-6 text-muted-foreground" />
          </button>
        </div>
      </div>
      <div className="fixed bottom-0 w-full p-6 bg-gradient-to-t from-background via-background/90 to-transparent">
        <button className="w-full h-14 rounded-2xl bg-gradient-to-r from-accent to-primary text-primary-foreground font-bold text-lg shadow-lg flex items-center justify-center gap-2 transition-transform active:scale-[0.98]">
          Continue
          <Icon icon="solar:arrow-right-bold" className="size-6" />
        </button>
      </div>
    </div>
  );
}
