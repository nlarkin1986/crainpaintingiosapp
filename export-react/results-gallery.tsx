import { Icon } from "@iconify/react";

export function ResultsGallery() {
  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground pb-24">
      <header className="pt-14 pb-4 px-4 flex items-center justify-between border-b border-border bg-white sticky top-0 z-20">
        <h1 className="font-heading font-bold text-xl px-2">Gallery</h1>
        <div className="flex gap-2">
          <button className="w-10 h-10 flex items-center justify-center rounded-full bg-muted/50 hover:bg-muted transition-colors">
            <Icon icon="solar:folder-add-linear" className="size-6 text-primary" />
          </button>
          <button className="w-10 h-10 flex items-center justify-center rounded-full bg-muted/50 hover:bg-muted transition-colors">
            <Icon icon="solar:magnifer-linear" className="size-6" />
          </button>
        </div>
      </header>
      <div className="flex flex-col gap-8 py-6">
        <section className="flex flex-col gap-4">
          <div className="px-6 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Icon icon="solar:sofa-bold-duotone" className="size-6 text-primary" />
              <h2 className="font-heading font-bold text-lg">Living Room</h2>
              <span className="text-xs font-medium bg-muted px-2 py-0.5 rounded-full text-muted-foreground ml-1">
                3
              </span>
            </div>
            <button className="text-sm font-semibold text-primary">View All</button>
          </div>
          <div className="flex overflow-x-auto gap-4 px-6 no-scrollbar pb-2">
            <div className="flex-shrink-0 w-[240px] flex flex-col gap-3 group active:scale-[0.98] transition-transform">
              <div className="relative aspect-[3/4] rounded-2xl overflow-hidden shadow-md border border-border">
                <img
                  src="https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/Igcq9YRllt9/components/gzXyUcmp7Ov.png"
                  className="w-full h-full object-cover"
                />
                <div className="absolute top-3 right-3 bg-black/40 backdrop-blur-md p-1.5 rounded-lg border border-white/20">
                  <Icon icon="solar:full-screen-linear" className="size-4 text-white" />
                </div>
              </div>
              <div className="bg-card rounded-xl p-3 border border-border shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-[#E8DCC4] border border-border shrink-0" />
                  <div className="overflow-hidden">
                    <p className="font-bold text-[13px] truncate">Swiss Coffee</p>
                    <p className="text-[11px] text-muted-foreground truncate">BM OC-45</p>
                  </div>
                </div>
              </div>
            </div>
            <div className="flex-shrink-0 w-[240px] flex flex-col gap-3 group active:scale-[0.98] transition-transform">
              <div className="relative aspect-[3/4] rounded-2xl overflow-hidden shadow-md border border-border">
                <img
                  src="https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/Igcq9YRllt9/components/g2BaAqdNyDc.png"
                  className="w-full h-full object-cover"
                />
                <div className="absolute top-3 right-3 bg-black/40 backdrop-blur-md p-1.5 rounded-lg border border-white/20">
                  <Icon icon="solar:full-screen-linear" className="size-4 text-white" />
                </div>
              </div>
              <div className="bg-card rounded-xl p-3 border border-border shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-[#9BA495] border border-border shrink-0" />
                  <div className="overflow-hidden">
                    <p className="font-bold text-[13px] truncate">Saybrook Sage</p>
                    <p className="text-[11px] text-muted-foreground truncate">BM HC-114</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
        <section className="flex flex-col gap-4">
          <div className="px-6 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Icon icon="solar:bed-bold-duotone" className="size-6 text-primary" />
              <h2 className="font-heading font-bold text-lg">Master Bedroom</h2>
              <span className="text-xs font-medium bg-muted px-2 py-0.5 rounded-full text-muted-foreground ml-1">
                2
              </span>
            </div>
            <button className="text-sm font-semibold text-primary">View All</button>
          </div>
          <div className="flex overflow-x-auto gap-4 px-6 no-scrollbar pb-2">
            <div className="flex-shrink-0 w-[240px] flex flex-col gap-3 group active:scale-[0.98] transition-transform">
              <div className="relative aspect-[3/4] rounded-2xl overflow-hidden shadow-md border border-border">
                <img
                  src="https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/Igcq9YRllt9/components/E6fZTnqyWHL.png"
                  className="w-full h-full object-cover"
                />
                <div className="absolute top-3 right-3 bg-black/40 backdrop-blur-md p-1.5 rounded-lg border border-white/20">
                  <Icon icon="solar:full-screen-linear" className="size-4 text-white" />
                </div>
              </div>
              <div className="bg-card rounded-xl p-3 border border-border shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-[#C57A5D] border border-border shrink-0" />
                  <div className="overflow-hidden">
                    <p className="font-bold text-[13px] truncate">Terra Cotta Tile</p>
                    <p className="text-[11px] text-muted-foreground truncate">BM 2090-30</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
        <section className="flex flex-col gap-4">
          <div className="px-6 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Icon
                icon="solar:chef-hat-minimalistic-bold-duotone"
                className="size-6 text-primary"
              />
              <h2 className="font-heading font-bold text-lg">Kitchen Renovation</h2>
              <span className="text-xs font-medium bg-muted px-2 py-0.5 rounded-full text-muted-foreground ml-1">
                4
              </span>
            </div>
            <button className="text-sm font-semibold text-primary">View All</button>
          </div>
          <div className="flex overflow-x-auto gap-4 px-6 no-scrollbar pb-2">
            <div className="flex-shrink-0 w-[240px] flex flex-col gap-3 group active:scale-[0.98] transition-transform">
              <div className="relative aspect-[3/4] rounded-2xl overflow-hidden shadow-md border border-border">
                <img
                  src="https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/Igcq9YRllt9/components/cWlLxYC6Vv8.png"
                  className="w-full h-full object-cover"
                />
                <div className="absolute top-3 right-3 bg-black/40 backdrop-blur-md p-1.5 rounded-lg border border-white/20">
                  <Icon icon="solar:full-screen-linear" className="size-4 text-white" />
                </div>
              </div>
              <div className="bg-card rounded-xl p-3 border border-border shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-[#2F4F4F] border border-border shrink-0" />
                  <div className="overflow-hidden">
                    <p className="font-bold text-[13px] truncate">Salamander</p>
                    <p className="text-[11px] text-muted-foreground truncate">BM 2123-10</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
      <nav className="fixed bottom-0 w-full h-[84px] bg-white border-t border-border flex justify-around items-start pt-3 pb-6 z-40 px-2">
        <button className="flex flex-col items-center gap-1 text-muted-foreground w-16">
          <Icon icon="solar:magic-stick-3-linear" className="size-6" />
          <span className="text-[10px] font-medium">Visualize</span>
        </button>
        <button className="flex flex-col items-center gap-1 text-muted-foreground w-16">
          <Icon icon="solar:heart-linear" className="size-6" />
          <span className="text-[10px] font-medium">Favorites</span>
        </button>
        <button className="flex flex-col items-center gap-1 text-primary w-16">
          <Icon icon="solar:gallery-bold" className="size-6" />
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
