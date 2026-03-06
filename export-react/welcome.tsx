import { Icon } from "@iconify/react";

export function Welcome() {
  return (
    <div className="relative flex flex-col min-h-screen bg-background text-foreground overflow-hidden">
      <div className="absolute inset-0 z-0">
        <img
          src="https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/Igcq9YRllt9/components/PEWcEOHyE7a.png"
          alt="Luxury living room hero"
          className="w-full h-full object-cover shadow-inner"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/40 to-transparent" />
        <div className="absolute inset-0 bg-black/10" />
      </div>
      <div className="relative z-10 flex flex-col flex-1 items-center px-6 pt-24 pb-12">
        <div className="flex flex-col items-center gap-3 animate-in fade-in slide-in-from-top-4 duration-700">
          <div className="px-6 py-2 bg-white/90 backdrop-blur-md rounded-2xl shadow-xl border border-white/20 flex items-center justify-center font-heading font-bold tracking-tight text-primary text-2xl">
            Aura Finishes
          </div>
          <p className="text-[14px] font-medium text-white drop-shadow-md">
            Trusted Craftsmanship Since 1952
          </p>
        </div>
        <div className="mt-auto w-full flex flex-col gap-8 items-center">
          <div className="text-center space-y-3 animate-in fade-in slide-in-from-bottom-4 duration-700 delay-200">
            <h1 className="font-heading font-bold text-3xl leading-tight text-foreground">
              Visualize your perfect space
            </h1>
            <p className="text-[16px] text-muted-foreground leading-relaxed px-4">
              Professional-grade AI visualization to help you choose the right finishes with
              confidence.
            </p>
          </div>
          <div className="w-full space-y-4 animate-in fade-in slide-in-from-bottom-8 duration-700 delay-500">
            <button className="w-full h-14 rounded-2xl bg-gradient-to-r from-accent to-primary text-primary-foreground font-bold text-[18px] shadow-lg shadow-primary/20 flex items-center justify-center gap-2 transition-transform active:scale-[0.98]">
              Get Started
              <Icon icon="solar:arrow-right-bold" className="size-6" />
            </button>
            <button className="w-full h-14 rounded-2xl bg-white border border-border text-foreground font-semibold text-[16px] shadow-sm flex items-center justify-center gap-2 transition-transform active:scale-[0.98]">
              Sign In
            </button>
          </div>
          <div className="flex items-center gap-2 text-[12px] text-muted-foreground mt-2">
            <Icon icon="solar:shield-check-bold" className="size-4 text-primary" />
            <span>Secure & Trusted Family Business</span>
          </div>
        </div>
      </div>
    </div>
  );
}
