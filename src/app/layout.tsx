import type { Metadata } from "next";
import { Open_Sans, Merriweather_Sans } from "next/font/google";
import { Toaster } from "@/components/ui/sonner";
import "./globals.css";

const openSans = Open_Sans({
  subsets: ["latin"],
  variable: "--font-body",
});

const merriweatherSans = Merriweather_Sans({
  subsets: ["latin"],
  variable: "--font-heading",
});

export const metadata: Metadata = {
  title: "Crain Painting Color Visualizer",
  description: "See your room in a new color before you paint. Upload a photo, pick a Benjamin Moore color, and visualize the transformation.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${openSans.variable} ${merriweatherSans.variable}`}>
      <body className="antialiased">
        {children}
        <Toaster />
      </body>
    </html>
  );
}
